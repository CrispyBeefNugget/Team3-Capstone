import asyncio
import bcrypt #Token secret hash conversion
import json
import time
import websockets
import websockets.asyncio
import websockets.asyncio.server

import dmaftServerDB

#Message handlers
def handlePingMsg(clientRequest: dict):
    clientRequest['Successful'] = True
    clientRequest['ServerTimestamp'] = time.time()
    return clientRequest

def handleConnectRequest(clientRequest):
    raise NotImplementedError

def handleChallengeResponse(clientRequest):
    raise NotImplementedError


#Main dispatch function for all received requests
def handleRequest(clientRequest):
    command = str(clientRequest['Command']).upper()

    if command == 'PING':
        return handlePingMsg(clientRequest)
        
    elif command == 'CONNECT':
        return handleConnectRequest(clientRequest)
    
    elif command == 'AUTHENTICATE':
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
    async with websockets.asyncio.server.serve(listen, "localhost", 8765) as server:
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