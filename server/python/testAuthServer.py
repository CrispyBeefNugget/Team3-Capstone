import asyncio
import bcrypt #Token secret hash conversion
import json
import time
import websockets
import websockets.asyncio
import websockets.asyncio.server

async def echo(websocket):
    async for message in websocket:
        try:
            clientRequest = json.loads(message)
            if clientRequest['Command'].upper() != "PING":
                await websocket.send(sendError('Unrecognized command!'))
                continue

            clientRequest['Successful'] = True
            clientRequest['ServerTimestamp'] = time.gmtime()
            await websocket.send(json.dumps(clientRequest))
            
        except:
            print("Received non-JSON message!")
            print("Message: ", message)
            await websocket.send(message)


async def main():
    async with websockets.asyncio.server.serve(echo, "localhost", 8765) as server:
        await server.serve_forever()

def sendError(reason: str):
    jsonMsg = {
        'Successful': False,
        'ErrorMessage':reason,
        'ServerTimestamp':time.gmtime(),
    }
    return json.dumps(jsonMsg)

if __name__ == "__main__":
    asyncio.run(main())