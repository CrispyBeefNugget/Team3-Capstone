import asyncio
from websockets.asyncio.client import connect

import json
import time


async def hello():
    async with connect("ws://localhost:8765") as websocket:
        await websocket.send(constructPing('Hello there!'))
        message = await websocket.recv()
        try:
            serverReply = json.loads(message)
            print(serverReply)
        except:
            print(message)

def constructPing(msg: str):
    jsonMsg = {
        'Command':'PING',
        'Message':msg,
        'ClientTimestamp':time.gmtime(),
    }
    result = json.dumps(jsonMsg)
    return result

if __name__ == "__main__":
    asyncio.run(hello())