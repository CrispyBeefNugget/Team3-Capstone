import base64
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives import serialization
import random
import time

from tlsServer import makeError, cleanAuthData
import dmaftServerDB

#This needs to be renamed in the future.
#The CONNECT keyword is reserved for clients wanting to start a conversation with each other.
def handleConnectRequest(clientRequest: dict):
    #Make sure we got a valid request
    keys = set(clientRequest.keys())
    expectedKeys = {'Command','UserPublicKeyMod','UserPublicKeyExp','ClientTimestamp','UserId','Register'}
    if keys != expectedKeys:
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='One or more required JSON keys are missing from the request.')

    if clientRequest['UserId'] in ['',None] and clientRequest['Register'] not in ['True','true', True]:
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='Received challenge request with Register set to False and no UserId specified. Set Register to True to request a new account, or specify an existing UserId to log in to.')


    #If the client specified an account, make sure that user first exists
    if clientRequest['UserId'] not in ['',None]:
        dbConn = dmaftServerDB.startDB()
        try:
            if not dmaftServerDB.doesUserExist(connection=dbConn, userID=clientRequest['UserId']):
                dmaftServerDB.closeDB(dbConn)
                return makeError(clientRequest=clientRequest, errorCode='InvalidUserId', reason='The specified UserId does not exist. Please specify a different user or send a registration request.')
        except:
            dmaftServerDB.closeDB(dbConn)
            return makeError(clientRequest=clientRequest, errorCode='ServerInternalError', retry=True, reason='Failed to query the database to check if the specified user is registered.')

        dmaftServerDB.closeDB(dbConn)

    #Parse the key components into a valid RSA key
    try:
        userPubKeyExp = int(clientRequest['UserPublicKeyExp'])
        userPubKeyMod = int(clientRequest['UserPublicKeyMod'])
    except:
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='The user public key exponent and modulus must be valid integers.')
    
    try:
        numSet = rsa.RSAPublicNumbers(userPubKeyExp, userPubKeyMod)
        pubKey = numSet.public_key()
    except Exception as e:
        print("Exception when trying to construct key:\n", e)
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='Failed to construct the RSA public key from the given parameters.')

    #Create the challenge and send it to the client
    if clientRequest['UserId'] == '':
        clientRequest['UserId'] == None #Sanitize blank ID before sending to query

    pubKeyBytes = pubKey.public_bytes(encoding=serialization.Encoding.DER, format=serialization.PublicFormat.SubjectPublicKeyInfo)
    challengeBytes = random.randbytes(32)
    dbConn = dmaftServerDB.startDB()
    dmaftServerDB.pruneChallenges(connection=dbConn) #Prevent attackers from brute-forcing old challenges later on
    result = dmaftServerDB.addChallenges(connection=dbConn, challenges=[challengeBytes], publicKeys=[pubKeyBytes], userIDs=[clientRequest['UserId']])
    dbConn.close()

    if type(result) is not list:
        return makeError(clientRequest=clientRequest, errorCode='ServerInternalError', reason='Failed to produce an authentication challenge.')
    
    elif len(result) != 1:
        return makeError(clientRequest=clientRequest, errorCode='ServerInternalError', reason='Failed to receive created challenge from server database.')

    try:
        challenge = result[0]
        clientRequest['ChallengeId'] = str(challenge[0])
        clientRequest['ChallengeData'] = base64.b64encode(challenge[1]).decode()
        clientRequest['Successful'] = True
        clientRequest['ServerTimestamp'] = time.time()
        return clientRequest
    except:
        return makeError(clientRequest=clientRequest, errorCode='ServerInternalError', reason='Failed to parse challenge from server database response.')


def handleChallengeResponse(clientRequest: dict):
    keys = set(clientRequest.keys())
    expectedKeys = {'Command','ChallengeId','Signature','HashAlgorithm','ClientTimestamp'}
    if keys != expectedKeys:
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='One or more required JSON keys are missing from the request.')

    if str(clientRequest['HashAlgorithm']).upper() != 'SHA256':
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='Only SHA256 signatures are currently supported.')

    if clientRequest['ChallengeId'] == '' or clientRequest['Signature'] == '':
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='Both the ChallengeId and Signature must be non-empty.')

    print("Received authentication request!")
    print(clientRequest)

    #Find the challenge and retrieve the stored public key.
    #Remember, the public key was serialized as DER and the format was SubjectPublicKeyInfo.
    dbConn = dmaftServerDB.startDB()
    try:
        challenges = dmaftServerDB.getChallenge(connection=dbConn, challengeID=clientRequest['ChallengeId'])
    except Exception as e:
        print("dmaftserverDB.getChallenges() failed.")
        dbConn.close()
        return makeError(clientRequest=clientRequest, retry=True, errorCode='ServerInternalError', reason='dmaftServerDB.getChallenge() failed.')
    
    if type(challenges) is not list:
        dbConn.close()
        return makeError(clientRequest=clientRequest, retry=True, errorCode='ServerInternalError', reason='Failed to query the server challenge database. Please try again.')

    elif len(challenges) != 1:
        dbConn.close()
        return makeError(clientRequest=clientRequest, errorCode='InvalidChallengeId', reason='The specified challenge does not exist. Please request a new challenge.')

    #We got exactly one match.
    #Delete the challenge from the DB so it can't be used in a replay attack.
    #Then, import the public key from the result in 'record' and verify the provided signature.
    if not dmaftServerDB.deleteChallengesWithUUID(connection=dbConn, challengeID=clientRequest['ChallengeId']):
        dbConn.close()
        return makeError(clientRequest=clientRequest, retry=True, errorCode='ServerInternalError', reason='')

    record = challenges[0]
    challengeId, challenge, publicKeyBytes, userId, expireTimestamp = record
    userPublicKey = serialization.load_der_public_key(publicKeyBytes)
    sigBytes = base64.b64decode(clientRequest['Signature'])
    try:
        #If this succeeds without an exception, the signature is valid.
        userPublicKey.verify(
            signature=sigBytes,
            data=challenge,
            padding=padding.PKCS1v15(),
            algorithm=hashes.SHA256()
            )
    except:
        #The challenge signature is invalid. Treat as if a wrong password was entered; deny access.
        return makeError(clientRequest=clientRequest, errorCode='InvalidResponse', reason='The challenge signature could not be verified. Please request a new challenge.')

    #The client is now authenticated!
    dbConn = dmaftServerDB.startDB()
    if userId in [None,'']:
        #The user doesn't exist yet. Register them.
        newUserId = dmaftServerDB.registerUser(connection=dbConn, publicKey=userPublicKey)
        if newUserId is None:
            dmaftServerDB.closeDB(dbConn)
            return makeError(clientRequest=clientRequest, errorCode='ServerInternalError', reason='Failed to register the new user record after successful authentication. Please request a new challenge.')

        userId = newUserId
        print("Successfully created a new userId!")

    #Issue the user a token and construct a response
    token = dmaftServerDB.createToken(connection=dbConn, userID=userId)
    print("Created the token!")
    if token is None:
        #Token creation failed. Provide a fake token with the real user ID to the client. They can get a new token on their own using that info.
        dmaftServerDB.closeDB(dbConn)
        clientRequest['Successful'] = True
        clientRequest['UserId'] = userId
        clientRequest['TokenId'] = ''
        clientRequest['TokenSecret'] = ''
        return clientRequest
    
    #Token creation succeeded. Send it back for the client to use.
    clientRequest['Successful'] = True
    clientRequest['UserId'] = token['UserId']
    clientRequest['TokenId'] = token['TokenId']
    clientRequest['TokenSecret'] = base64.b64encode(token['TokenSecret']).decode()
    return clientRequest


def validateClientToken(clientRequest: dict):
    #First make sure we have a valid request.
    keys = set(clientRequest.keys())
    requiredKeys = {'UserId','TokenId','TokenSecret'}
    if not requiredKeys.issubset(keys):
        print("handleAuth.validateClientToken(): Received client request with missing keys! Sending BadRequest to client...")
        clientRequest = cleanAuthData(clientRequest)
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='handleAuth.validateClientToken(): A required JSON key (UserId, TokenId, TokenSecret) is missing from the request.')
    
    sanityChecks = [
        type(clientRequest['UserId']) == str,
        type(clientRequest['TokenId']) == str,
        type(clientRequest['TokenSecret'] == str)
        ]
    
    if False in sanityChecks:
        clientRequest = cleanAuthData(clientRequest)
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='handleAuth.validateClientToken(): A required JSON key (UserId, TokenId, TokenSecret) has the wrong kind of data.')

    #Decode the Base64-encoded token secret.
    trueTokenSecret = base64.b64decode(clientRequest['TokenSecret'])

    dbConn = dmaftServerDB.startDB()
    try:
        if not dmaftServerDB.doesUserExist(connection=dbConn, userID=clientRequest['UserId']):
            clientRequest = cleanAuthData(clientRequest)
            return makeError(clientRequest=clientRequest, errorCode='InvalidUserId', reason="The specified User ID doesn't exist. Please try a different ID or register an account.")
        
        authorizedUser = dmaftServerDB.validateToken(connection=dbConn, tokenID=clientRequest['TokenId'], tokenSecret=trueTokenSecret)
        if authorizedUser is None:
           clientRequest = cleanAuthData(clientRequest)
           return makeError(clientRequest=clientRequest, errorCode='InvalidToken', reason='The provided token is invalid. Please authenticate.')
    
        if str(authorizedUser).upper != str(clientRequest['UserId']).upper():
            clientRequest = cleanAuthData(clientRequest)
            return makeError(clientRequest=clientRequest, errorCode='InvalidToken', reason='The provided token is invalid. Please authenticate.')
    
        return cleanAuthData(clientRequest)
    
    except:
        print("handleAuth.validateClientToken(): Unable to complete the token validation request. Sending ServerInternalError to client...")
        clientRequest = cleanAuthData(clientRequest)
        return makeError(clientRequest=clientRequest, errorCode='ServerInternalError', retry=True, reason='handleAuth.validateClientToken(): Server failed to prune the tokens table. Please try again.')
