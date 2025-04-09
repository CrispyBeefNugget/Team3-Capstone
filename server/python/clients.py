import websockets
import websockets.asyncio
import websockets.asyncio.server
import asyncio
import copy

class ConnectionList:
    def __init__(self):
        self.clients = []

    def getClientFromSocket(self, socket: websockets.asyncio.server.ServerConnection):
        return list(filter(lambda client: client['Socket'] == socket, self.clients))
        #Credit to here for this method: https://stackoverflow.com/a/25373204
    
    def getClientsFromUser(self, userID: str):
        return list(filter(lambda client: str(client['UserId']).upper() == userID.upper(), self.clients))

    def deleteSocket(self, socket: websockets.asyncio.server.ServerConnection):
        for client in self.clients:
            if client['Socket'] == socket:
                self.clients.remove(client)

    def addSocket(self, socket: websockets.asyncio.server.ServerConnection):
        self.clients.append({'UserId':None,'Socket':socket})
    
    def setUserOnSocket(self, socket: websockets.asyncio.server.ServerConnection, userID: str):
        for client in self.clients:
            if client['Socket'] == socket:
                client['UserId'] = userID
            
    def isUserConnected(self, userID: str):
        return len(self.getClientsFromUser(userID)) > 0


    #Returns True if successful and False if failed.
    #If the connection was closed earlier, it will be removed from the ConnectionList.
    #If the connection wasn't previously present, it will be added.
    async def sendMsgToSocket(self, socket: websockets.asyncio.server.ServerConnection, msgData: bytes):
        print("Executing sendMsgToSocket on socket ID", socket.id)
        if len(self.getClientFromSocket(socket)) == 0:
            print("The provided websocket is missing! Adding it...")
            self.addSocket(socket)
        try:
            await socket.send(msgData)
            print("Successfully sent the message!")
            return True
        except websockets.exceptions.ConnectionClosed as closed:
            print("The socket is closed, removing...")
            self.deleteSocket(socket)
            return False
        except Exception as e:
            print("Exception raised:",e)
            return False
    
    def sendMsgToUser(self, userID: str, msgData: bytes):
        successStatus = False
        clients = self.getClientsFromUser(userID)
        if len(clients) == 0:
            print("clients.sendMsgToUser(): Found no websocket connections for user", userID)
            return False
    
        for client in clients:
            try:
                print("Creating task to send message to user ", userID, "on socket ID", str(client['Socket'].id))
                task = asyncio.create_task(self.sendMsgToSocket(client['Socket'], msgData))
                successStatus = True
            except:
                print("Client found with missing socket! Removing...")
                self.clients.remove(client)

        return successStatus

    def broadcastToUsers(self, userList: list[str], msgData: bytes):
        usersRemaining = copy.deepcopy(userList)
        successStatus = False
        print("ConnectionList.broadcastToUsers(): Received user list", userList)
        for user in userList:
            print("ConnectionList.broadcastToUsers(): Contents of userList is", userList)
            print("ConnectionList.broadcastToUsers(): Attempting to send message to user", user)
            if self.sendMsgToUser(user, msgData):
                usersRemaining.remove(user)
                print("Successfully delivered message to user " + user)
        
        return usersRemaining