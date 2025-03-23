import asyncio
import base64
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives import serialization
import hashlib
import json
import time
import random
import socket
import ssl
import traceback
import websockets
import websockets.asyncio
import websockets.asyncio.server

import clients
import dmaftServerDB
import handleAuth

ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)

# Nigel's path
# ssl_cert = '/Users/Shared/Keys/DMAFT/dmaft-tls_cert.pem'
# ssl_key = '/Users/Shared/Keys/DMAFT/dmaft-tls_key.pem'

# Jeremey's path
ssl_cert = 'C:/Users/jclar/OneDrive/Documents/CS4996/ssl/dmaft-tls_cert.pem'
ssl_key = 'C:/Users/jclar/OneDrive/Documents/CS4996/ssl/dmaft-tls_key.pem'

# Ben's path
# ssl_cert = 'INSERT_PATH_HERE/dmaft-tls_cert.pem'
# ssl_key = 'INSERT_PATH_HERE/dmaft-tls_key.pem'

ssl_context.load_cert_chain(ssl_cert, keyfile=ssl_key)

connectedClients = clients.ConnectionList()


def getRSAPublicKeySHA512(pubkey: rsa.RSAPublicKey):
    pubBytes = pubkey.public_bytes(encoding=serialization.Encoding.DER, format=serialization.PublicFormat.SubjectPublicKeyInfo)
    sha512Thumbprint = hashlib.sha512(pubBytes).hexdigest()
    return sha512Thumbprint

#Message handlers
def handlePingMsg(clientRequest: dict):
    clientRequest['Successful'] = True
    clientRequest['ServerTimestamp'] = time.time()
    return clientRequest


#IMPORTANT: These methods assume the client is already authenticated!
#Handle a request to search the list of users.
#To preserve user privacy, only UserIDs and UserNames are returned by the database.
def handleSearchUsersMsg(clientRequest: dict):
    #Make sure we have a valid request
    keys = set(clientRequest.keys())
    expectedKeys = {'Command','SearchBy','SearchTerm'}
    if not expectedKeys.issubset(keys):
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='One or more required JSON keys are missing from the request.')

    sanityChecks = [
        type(clientRequest['Command']) == str,
        type(clientRequest['SearchBy']) == str,
        type(clientRequest['SearchTerm']) == str,
    ]

    if False in sanityChecks:
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='One of the JSON keys is malformed or missing a required value.')

    if not clientRequest['SearchBy'].upper() in ['USERID', 'USERNAME']:
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='Invalid SearchBy key; must specify UserId or UserName.')

    #Search the list of users and return the results.
    dbConn = dmaftServerDB.startDB()
    try:
        if clientRequest['SearchBy'].upper() == 'USERNAME':
            results = dmaftServerDB.getUsersByName(connection=dbConn, userName=clientRequest['SearchTerm'])
        else:
            results = dmaftServerDB.getUserByID(connection=dbConn, userID=clientRequest['SearchTerm'])
    except:
        return makeError(clientRequest=clientRequest, retry=True, errorCode='ServerInternalError', reason='Failed to execute the requested search. Please try again.')
    finally:
        dbConn.close()

    userlist = []
    try:
        for record in results:
            userlist.append({'UserId':record[0], 'UserName':record[1]})
    except:
        pass

    clientRequest['Successful'] = True
    clientRequest['ServerTimestamp'] = int(time.time())
    clientRequest['Results'] = userlist
    return clientRequest


def handleNewConvoRequest(clientRequest: dict):
    keys = set(clientRequest.keys())
    expectedKeys = {'Command','UserId','RecipientIds'}
    if not expectedKeys.issubset(keys):
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='One or more required JSON keys are missing from the request.')

    sanityChecks = [
        type(clientRequest['Command']) == str,
        type(clientRequest['UserId']) == str,
        type(clientRequest['RecipientIds']) == str,
    ]

    if False in sanityChecks:
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='One of the JSON keys is malformed or missing a required value.')

    #Parse the recipient list and ensure that each recipient is a valid UserID.
    #Remove all duplicates too.
    recipients = json.loads(clientRequest['Recipients'])
    if type(recipients) != list:
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='The Recipient key must specify a list of UserID strings to add to the conversation.')

    recipients = list(dict.fromkeys(recipients))
    for i in len(recipients):
        recipients[i] = str(recipients[i]).upper()
    
    sender = clientRequest['UserId'].upper()
    if sender in recipients:
        recipients.remove(sender)

    #Check if we actually have any recipients.
    #If not, stop.
    if len(recipients) == 0:
        return makeError(clientRequest=clientRequest, errorCode='NoRecipientsSpecified', reason='At least one User ID must be specified in the recipient list other than yours!')

    #We have at least one recipient.
    #Validate them all before continuing.
    dbConn = dmaftServerDB.startDB()
    try:
        for recipient in recipients:
            if not dmaftServerDB.doesUserExist(connection=dbConn, userID=recipient):
                dmaftServerDB.closeDB(dbConn)
                return makeError(clientRequest=clientRequest, errorCode='InvalidRecipientId', reason='Recipient ID ' + recipient + ' is not a registered user.')
    except:
        dmaftServerDB.closeDB(dbConn)
        return makeError(clientRequest=clientRequest, errorCode='ServerInternalError', retry=True, reason='Failed to validate the provided list of recipient IDs. Please try again.')

    #The provided recipients are valid.
    #Add the sender to the member list and create the conversation.
    recipients.append(sender)
    try:
        conversationID = dmaftServerDB.createNewConversation(connection=dbConn, userIDs=recipients)
        if conversationID is None:
            dmaftServerDB.closeDB(dbConn)
            return makeError(clientRequest=clientRequest, errorCode='ServerInternalError', retry=True, reason='Failed to create the requested conversation. Please try again.')
    except:
        #The only error that this method will throw is a ValueError, and only if one of the recipients doesn't exist.
        return makeError(clientRequest=clientRequest, errorCode='InvalidRecipientId', reason='The database detected that one of the provided User IDs is invalid.')

    #The conversation was successfully created.
    #Notify everyone.
    newConversationData = {
        'Command':'NEWCONVERSATIONCREATED',
        'ServerTimestamp': time.time(),
        'CreatorId':sender,
        'Members':recipients,
        'ConversationId':conversationID
    }
    newConversationMsg = json.dumps(newConversationData)
    remainingUsers = connectedClients.broadcastToUsers(recipients, newConversationMsg)

    #If any recipients missed the notification, store it in the mailbox to send to them later.
    #Mark the conversation as SYSTEM so that we know it isn't a user-sent message.
    if len(remainingUsers) > 0:
        dbConn = dmaftServerDB.startDB()
        for user in remainingUsers:
            dmaftServerDB.addToMailbox(connection=dbConn, conversationID='SYSTEM', recipientID=user, msgDict=newConversationMsg, expireTime=(int(time.time()) + 1209600)) #Give it two weeks to send out

    clientRequest['Successful'] = True
    clientRequest['ServerTimestamp'] = int(time.time())
    clientRequest['NewConversationId'] = conversationID
    return clientRequest


def handleSendMessageRequest(clientRequest: dict):
    #Make sure we have a valid request
    keys = set(clientRequest.keys())
    expectedKeys = {'Command','ConversationId','MessageType','MessageData'}
    if not expectedKeys.issubset(keys):
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='One or more required JSON keys are missing from the request.')

    sanityChecks = [
        type(clientRequest['Command']) == str,
        type(clientRequest['ConversationId']) == str,
        type(clientRequest['MessageType']) == str,
    ]

    if False in sanityChecks:
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='One of the JSON keys is malformed or missing a required value.')

    if clientRequest['MessageType'] not in ['Text', 'Image', 'Video', 'File']:
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='Invalid value given for MsgType. Must be one of: Text, Image, Video, File.')

    #Validate the Conversation ID and get the list of recipients
    dbConn = dmaftServerDB.startDB()
    sqlResult = dmaftServerDB.getConversationByID(clientRequest['ConversationId'])
    dmaftServerDB.closeDB(dbConn)

    if sqlResult is None:
        return makeError(clientRequest=clientRequest, errorCode='InvalidConversationId', reason='Invalid conversation ID provided in send message request.')

    if len(sqlResult) > 1:
        return makeError(clientRequest=clientRequest, errorCode='ServerInternalError', reason='Failed to validate the conversation ID.')

    conversationID, participantJSON = sqlResult[0]
    participants = json.loads(participantJSON)
    if clientRequest['UserId'].upper() in participants:
        participants.remove(clientRequest['UserId'])

    #Construct and send the message notification
    userMsgData = {
        'Command':'INCOMINGMESSAGE',
        'OriginalReceiptTimestamp':int(time.time()),
        'SenderId':clientRequest['UserId'],
        'ConversationId':clientRequest['ConversationId'],
        'MessageType':clientRequest['MessageType'],
        'MessageData':clientRequest['MessageData']
    }

    userMsgJSON = json.dumps(userMsgData)
    remainingUsers = connectedClients.broadcastToUsers(participants, userMsgJSON)

    #If any recipients missed the notification, store it in the mailbox to send to them later.
    #Mark the conversation as SYSTEM so that we know it isn't a user-sent message.
    if len(remainingUsers) > 0:
        dbConn = dmaftServerDB.startDB()
        for user in remainingUsers:
            dmaftServerDB.addToMailbox(connection=dbConn, conversationID='SYSTEM', recipientID=user, msgDict=userMsgJSON, expireTime=(int(time.time()) + 604800)) #Give it one week to send out

    clientRequest['Successful'] = True
    clientRequest['ServerTimestamp'] = int(time.time())
    return clientRequest


#Update the requesting user's profile info at their request.
#By design, users cannot update profile info for other users.
def handleUpdateProfileRequest(clientRequest: dict):
    #Validate the top-layer JSON.
    keys = set(clientRequest.keys())
    expectedKeys = {'Command','UserId','NewProfile'}
    if not expectedKeys.issubset(keys):
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='One or more required JSON keys are missing from the request.')

    sanityChecks = [
        type(clientRequest['Command']) == str,
        type(clientRequest['UserId']) == str,
        type(clientRequest['NewProfile']) == dict,
    ]

    if False in sanityChecks:
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='One of the JSON keys is malformed or missing a required value.')

    #Now validate the NewProfile dictionary.
    pkeys = set(clientRequest['NewProfile'].keys())
    expectedPKeys = {'UserName','UserProfilePic','UserStatus','UserBio'}
    if not expectedPKeys.issubset(pkeys):
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='The NewProfile key data is missing a required inner key.')

    pSanityChecks = [
        type(clientRequest['NewProfile']['UserName']) == str,
        type(clientRequest['NewProfile']['UserProfilePic']) == str, #haven't decoded it from Base64 yet
        type(clientRequest['NewProfile']['UserStatus']) == str,
        type(clientRequest['NewProfile']['UserBio']) == str,
    ]

    if False in pSanityChecks:
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='One or more inner keys inside the NewProfile key are malformed or missing a value')

    #Technically, we could decode the user's profile photo and then upload it to the DB.
    #However, since we don't NEED to see the raw value server-side, might as well store it in B64 to make it easier for delivery.

    dbConn = dmaftServerDB.startDB()
    result = dmaftServerDB.updateUserProfileData(
        connection=dbConn,
        userID=clientRequest['UserId'],
        userName=clientRequest['NewProfile']['UserName'],
        userBio=clientRequest['NewProfile']['UserBio'],
        userStatus=clientRequest['NewProfile']['UserStatus'],
        userPic=clientRequest['NewProfile']['UserProfilePic'],
        )
    dmaftServerDB.closeDB(dbConn)

    if not result:
        return makeError(clientRequest=clientRequest, retry=True, errorCode='ServerInternalError', reason="Failed to update user profile data for user " + clientRequest['UserId'] + ". Please try again.")

    del clientRequest['NewProfile']
    clientRequest['Successful'] = True
    clientRequest['ServerTimestamp'] = int(time.time())

    return clientRequest


#Main dispatch function for all received requests.
#These first few do NOT require valid tokens.
def handleRequest(clientRequest):
    command = str(clientRequest['Command']).upper()
    if command == 'PING':
        return handlePingMsg(clientRequest)
        
    #This needs to be renamed to a different command.
    #"CONNECT" is reserved for one client wanting to connect to another client.
    elif command == 'CONNECT':
        print("Detected CONNECT request.")
        return handleAuth.handleConnectRequest(clientRequest)
    
    elif command == 'AUTHENTICATE':
        print("Detected AUTHENTICATE request.")
        return handleAuth.handleChallengeResponse(clientRequest)

    else:
        #Validate the client's token.
        clientRequest = handleAuth.validateClientToken(clientRequest)
        if clientRequest.get('Successful', 'HelloThere') == False:
            return clientRequest    #Audit this line later on. validateClientToken is supposed to return an error dictionary if it fails, that we can just directly send. However, an attacker could just purposely set Successful == False in their clientRequest.
        
        #Client's token is validated. Allow remaining access.
        if command == 'SEARCHUSERS':
            print("Detected SEARCHUSERS request.")
            

        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='Invalid command received from client.')


async def listen(websocket: websockets.asyncio.server.ServerConnection):
    global connectedClients
    try:
        print(type(websocket))
        i = 0
        print("Running the listen function now!")
        async for message in websocket:
            if (connectedClients.getClientFromSocket(websocket) == []):
                connectedClients.addSocket(websocket)

            i += 1
            print('Count:', i)
            print("Received message!")
            try:
                clientRequest = json.loads(message)
            except:
                serverReply = makeError(clientRequest={}, errorCode='NonJSONRequest', reason='This server only accepts JSON requests.')
                await websocket.send(json.dumps(serverReply))
                continue
            
            try:
                serverReply = handleRequest(clientRequest)
                print("Sending to client:", serverReply)
                await websocket.send(json.dumps(serverReply))
                print("Successfully processed request.\n")

            except Exception as e:
                print("ERROR: handleRequest threw an exception.")
                print("Exception Info:")
                print(e, '\n')
                print(traceback.format_exc())
                serverReply = makeError(clientRequest=clientRequest, errorCode='ServerInternalError', reason='Server failed to process the request.')
                await websocket.send(json.dumps(serverReply))

    except websockets.exceptions.ConnectionClosed as closed:
        print("Client disconnected:", closed)
        connectedClients.deleteSocket(websocket)
        print("Removed this websocket from the list of active clients.")

    except Exception as e:
        print('Exception raised when trying to send message:', websocket, e)
        connectedClients.deleteSocket(websocket)
        print("Removed this websocket from the list of active clients.")


async def main():
    ip = getIPAddress()
    async with websockets.asyncio.server.serve(listen, ip, 8765, ssl=ssl_context) as server:
        print(type(server))
        print("Started server websocket, listening...")
        await server.serve_forever()

def makeError(*, clientRequest: dict, retry: bool = False, errorCode, reason: str):
    jsonMsg = {
        'Successful': False,
        'ErrorType':errorCode,
        'RetryOperation':retry, #Usually false, should only be true when the server experienced a transient error.
        'UserErrorMessage':reason,
        'ServerTimestamp':time.time(),
    }
    try:
        jsonMsg['OperationId'] = clientRequest.get('OperationId')
        jsonMsg['ClientTimestamp'] = clientRequest['Timestamp']
        jsonMsg['Command'] = clientRequest['Command']
    except:
        pass
    return json.dumps(jsonMsg)

#Strips out the UserId and token info from a given clientRequest.
def cleanAuthData(clientRequest: dict):
    for item in ['TokenId', 'TokenSecret']:
        try:
            del clientRequest[item]
        except:
            pass
        return clientRequest
    
def getIPAddress():
    tempSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    tempSocket.settimeout(0)
    try:
        tempSocket.connect(('8.8.8.8', 1))
        ip = tempSocket.getsockname()[0]
    except:
        ip = '127.0.0.1'
    finally:
        tempSocket.close()
    return ip

def makeBadAuthError(*, clientRequest: dict):
    return makeError(clientRequest=clientRequest, errorCode='InvalidToken', reason='The required token for this operation is missing or invalid. Please request a new challenge.')

if __name__ == "__main__":
    asyncio.run(main())