import asyncio
import bcrypt #Token secret hash conversion
import base64
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
import hashlib
import json
import time
import random
import ssl
import websockets
import websockets.asyncio
import websockets.asyncio.server

import dmaftServerDB

ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)

ssl_cert = '/Users/Shared/Keys/DMAFT/dmaft-tls_cert.pem'
ssl_key = '/Users/Shared/Keys/DMAFT/dmaft-tls_key.pem'

ssl_context.load_cert_chain(ssl_cert, keyfile=ssl_key)


def getRSAPublicKeySHA512(pubkey: rsa.RSAPublicKey):
    pubBytes = pubkey.public_bytes(encoding=serialization.Encoding.DER, format=serialization.PublicFormat.SubjectPublicKeyInfo)
    sha512Thumbprint = hashlib.sha512(pubBytes).hexdigest()
    return sha512Thumbprint

#Message handlers
def handlePingMsg(clientRequest: dict):
    clientRequest['Successful'] = True
    clientRequest['ServerTimestamp'] = time.time()
    return clientRequest

#This needs to be renamed in the future.
#The CONNECT keyword is reserved for clients wanting to start a conversation with each other.
def handleConnectRequest(clientRequest: dict):
    #Make sure we got a valid request
    keys = set(clientRequest.keys())
    expectedKeys = {'Command','UserPublicKeyMod','UserPublicKeyExp','ClientTimestamp'}
    if keys != expectedKeys:
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='One or more required JSON keys are missing from the request.')

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
    pubKeyBytes = pubKey.public_bytes(encoding=serialization.Encoding.DER, format=serialization.PublicFormat.SubjectPublicKeyInfo)
    challengeBytes = random.randbytes(32)
    dbConn = dmaftServerDB.startDB()
    result = dmaftServerDB.addChallenges(connection=dbConn, challenges=[challengeBytes], publicKeys=[pubKeyBytes])

    if type(result) is not list:
        return makeError(clientRequest=clientRequest, errorCode='ServerInternalError', reason='Failed to produce an authentication challenge.')
    
    elif len(result) != 1:
        return makeError(clientRequest=clientRequest, errorCode='ServerInternalError', reason='Failed to receive created challenge from server database.')

    try:
        challenge = result[0]
        clientRequest['ChallengeId'] = str(challenge[0])
        clientRequest['ChallengeData'] = base64.b64encode(challenge[1]).decode()
        clientRequest['Sucessful'] = True
        clientRequest['ServerTimestamp'] = time.time()
        return clientRequest
    except:
        return makeError(clientRequest=clientRequest, errorCode='ServerInternalError', reason='Failed to parse challenge from server database response.')


def handleChallengeResponse(clientRequest: dict):
    raise NotImplementedError


#Main dispatch function for all received requests
def handleRequest(clientRequest):
    command = str(clientRequest['Command']).upper()

    if command == 'PING':
        return handlePingMsg(clientRequest)
        
    #This needs to be renamed to a different command.
    #"CONNECT" is reserved for one client wanting to connect to another client.
    elif command == 'CONNECT':
        print("Detected CONNECT request.")
        return handleConnectRequest(clientRequest)
    
    elif command == 'AUTHENTICATE':
        print("Detected AUTHENTICATE request.")
        return handleChallengeResponse(clientRequest)

    else:
        return makeError(clientRequest=clientRequest, errorCode='BadRequest', reason='Invalid command received from client.')


async def listen(websocket):
    async for message in websocket:
        print("Received message!")
        try:
            clientRequest = json.loads(message)
        except:
            serverReply = makeError(clientRequest={}, errorCode='NonJSONRequest', reason='This server only accepts JSON requests.')
            await websocket.send(json.dumps(serverReply))
            continue
        
        try:
            serverReply = handleRequest(clientRequest)
            await websocket.send(json.dumps(serverReply))
            print("Successfully processed request.\n")
        except Exception as e:
            print("ERROR: handleRequest threw an exception.")
            print("Exception Info:")
            print(e, '\n')
            serverReply = makeError(clientRequest=clientRequest, errorCode='ServerInternalError', reason='Server failed to process the request.')
            await websocket.send(json.dumps(serverReply))


async def main():
    async with websockets.asyncio.server.serve(listen, "localhost", 8765, ssl=ssl_context) as server:
        print(type(server))
        print("Started server websocket, listening...")
        await server.serve_forever()

def makeError(*, clientRequest: dict, errorCode, reason: str):
    jsonMsg = {
        'Successful': False,
        'ErrorType':errorCode,
        'UserErrorMessage':reason,
        'ServerTimestamp':time.time(),
    }
    try:
        jsonMsg['ClientTimestamp'] = clientRequest['Timestamp']
        jsonMsg['Command'] = clientRequest['Command']
    except:
        pass
    return json.dumps(jsonMsg)

if __name__ == "__main__":
    asyncio.run(main())