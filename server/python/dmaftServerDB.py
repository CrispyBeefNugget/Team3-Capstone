from cryptography.hazmat.primitives.asymmetric import rsa
import json
import sqlite3
import random
import time
import uuid

import crypto

#INITIALIZATION FUNCTIONS
#Safe by default, but can erase data if you tell them to!!


def executeQuery(*, connection: sqlite3.Connection, query: str):
    if not sqlite3.complete_statement(query):
        raise ValueError("dmaftServerDB.executeQuery(): Invalid SQL query string!")

    try:
        cursor = connection.cursor()
        cursor.execute(query)
    except Exception as e:
        raise e
    
    results = cursor.fetchall()
    return results


def initTable(
        *, 
        connection: sqlite3.Connection, 
        destroyExistingTable: bool = False, 
        tableName: str,
        createStmt: str
        ):
    
    if destroyExistingTable:
        #DESTROY THE PREVIOUS TABLE FIRST.
        #If this errors out; no worries - it could just mean that the table already doesn't exist.
        destroyTable = "DROP TABLE " + tableName + ";"
        try:
            executeQuery(connection=connection, query=destroyTable)
        except Exception as e:
            print("Error occurred when trying to drop table:", e)
            pass

    #Try to create the new table.
    try:
        getAllTables = "SELECT name FROM sqlite_master WHERE type='table';"
        tables = executeQuery(connection=connection, query=getAllTables)
        for table in tables:
            if str(table[0]).lower() == tableName.lower():
                #There's a conflicting table. Stop.
                return False
        
        #The table doesn't exist. We can safely create it.
        executeQuery(connection=connection, query=createStmt)
        return True
    except:
        #Failed to safely create the table. Abort.
        return False


#These all work as expected.
#Just need to validate that data can be stored in these as expected.
initRegisteredUsersTbl = "CREATE TABLE tblRegisteredUsers (UserID TINYTEXT NOT NULL PRIMARY KEY, UserPublicKeySHA2_512 BLOB(64) NOT NULL, ConversationIDs BLOB);"
initConversationTbl = "CREATE TABLE tblConversations (ConversationID TINYTEXT NOT NULL PRIMARY KEY, Participants BLOB NOT NULL);"
initMailboxTbl = "CREATE TABLE tblMailbox (ConversationID TINYTEXT NOT NULL, ArriveTimestamp INT, ExpireTimestamp INT NOT NULL, Recipient TINYTEXT NOT NULL, Message LONGBLOB(60000000) NOT NULL, FOREIGN KEY(Recipient) REFERENCES tblRegisteredUsers(UserID));"
initChallengeTbl = "CREATE TABLE tblChallenges (ChallengeID TINYTEXT NOT NULL PRIMARY KEY, Challenge BLOB NOT NULL, UserPublicKey BLOB NOT NULL, User TINYTEXT, ExpireTimestamp INT NOT NULL, FOREIGN KEY(User) REFERENCES tblRegisteredUsers(UserID));"
initTokenTbl = "CREATE TABLE tblTokens (TokenID TINYTEXT NOT NULL PRIMARY KEY, TokenHash BLOB NOT NULL, User NOT NULL, ExpireTimestamp INT NOT NULL, FOREIGN KEY(User) REFERENCES tblRegisteredUsers(UserID));"

def getAllTableSchemas(*, connection: sqlite3.Connection):
    try:
        schemas = []
        tables = []
        allTablesResult = executeQuery(connection=connection, query="SELECT name FROM sqlite_master WHERE type='table';") #FIX THIS TO USE SQL STATEMENT COMPLETION; BETTER SECURITY
        for item in allTablesResult:
            tables.append(item[0])
        for table in tables:
            schema = executeQuery(connection=connection, query="select sql from sqlite_master where type = 'table' and name = '" + table + "';") #FIX THIS TO USE SQL STATEMENT COMPLETION; BETTER SECURITY
            schemas.append(schema)
        return schemas
    except:
        return None

def getAllTables(*, connection: sqlite3.Connection):
    try:
        tables = []
        allTablesResult = executeQuery(connection=connection, query="SELECT name FROM sqlite_master WHERE type='table';")
        for item in allTablesResult:
            tables.append(item[0])
        return tables
    except:
        return None
    
def connectSandbox():
    print("WARNING: This is a dev function that will be removed in production!")
    print("It only exists to make testing easier.")
    return sqlite3.connect('sandbox.db')

def connectDB():
    return sqlite3.connect('master.db')

def startDB():
    correctSchemas = [
        [('CREATE TABLE "tblRegisteredUsers" (\n\t"UserID"\tTINYTEXT NOT NULL,\n\t"UserPublicKeySHA2_512"\tBLOB(64) NOT NULL,\n\t"ConversationIDs"\tBLOB,\n\t"UserName"\tTEXT,\n\t"Status"\tTEXT,\n\t"Bio"\tTEXT,\n\t"ProfilePic"\tBLOB,\n\tPRIMARY KEY("UserID")\n)',)],
        [('CREATE TABLE tblConversations (ConversationID TINYTEXT NOT NULL PRIMARY KEY, Participants BLOB NOT NULL)',)],
        [('CREATE TABLE tblMailbox (ConversationID TINYTEXT NOT NULL, ArriveTimestamp INT, ExpireTimestamp INT NOT NULL, Recipient TINYTEXT NOT NULL, Message LONGBLOB(60000000) NOT NULL, FOREIGN KEY(Recipient) REFERENCES tblRegisteredUsers(UserID))',)],
        [('CREATE TABLE tblChallenges (ChallengeID TINYTEXT NOT NULL PRIMARY KEY, Challenge BLOB NOT NULL, UserPublicKey BLOB NOT NULL, User TINYTEXT, ExpireTimestamp INT NOT NULL, FOREIGN KEY(User) REFERENCES tblRegisteredUsers(UserID))',)],
        [('CREATE TABLE tblTokens (TokenID TINYTEXT NOT NULL PRIMARY KEY, TokenHash BLOB NOT NULL, User NOT NULL, ExpireTimestamp INT NOT NULL, FOREIGN KEY(User) REFERENCES tblRegisteredUsers(UserID))',)],
    ]

    try:
        conn = connectDB()
    except Exception as e:
        print("Failed to load database file!")
        raise e
    
    schemas = getAllTableSchemas(connection=conn)
    if schemas is None:
        conn.close()
        raise RuntimeError("Failed to list schemas from tables in production database!")
    
    for properSchema in correctSchemas:
        if properSchema not in schemas:
            conn.close()
            print("Schema mismatch!")
            print("Expected schema:", properSchema[0][0])
            print("Actual schemas:")
            for schema in schemas:
                print(schema)
            raise RuntimeError("Expected table schema is missing from database: " + properSchema[0][0])
    
    return conn


def closeDB(connection: sqlite3.Connection):
    try:
        connection.close()
        return True
    except:
        return False

#DATABASE OPERATION METHODS
#IMPORTANT: All methods below assume that a valid server is running with the schema described above.

#Generates and adds authentication challenges to the challenge table.
#Returns the list of generated challenge rows if successful, or None if failed.
def addChallenges(*, connection: sqlite3.Connection, challenges: list[bytes], publicKeys: list[bytes], userIDs: list):
    if len(challenges) != len(publicKeys) or len(challenges) != len(userIDs):
        raise ValueError("Challenge list, User ID list and public key list must all have the same number of items! NONE items are acceptable in the User ID list.")
    
    #No point in running if there's nothing to add or process.
    if len(challenges) == 0:
        return []

    result = executeQuery(connection = connection, query = 'SELECT ChallengeID from tblChallenges;')
    if result is None:
        #Unable to list the current UUIDs
        return None
    
    #Make sure that the new challenge IDs we generate don't conflict with any existing ones
    currentUUIDs = []
    for row in result:
        currentUUIDs.append(str(row[0]).upper())

    newUUIDs = []
    while len(newUUIDs) < len(challenges):
        newUUID = str(uuid.uuid4()).upper()
        if newUUID not in currentUUIDs:
            newUUIDs.append(newUUID)

    expireTime = int(time.time()) + 300 #Allow 5 minutes for the challenge to be satisfied. Expire it afterwards.

    newRecords = []
    for i in range(len(challenges)):
        newRecords.append((newUUIDs[i], challenges[i], publicKeys[i], userIDs[i], expireTime))
    
    try:
        with connection:
            stmt = 'INSERT INTO tblChallenges (ChallengeID, Challenge, UserPublicKey, User, ExpireTimestamp) VALUES (?,?,?,?,?);'
            connection.executemany(stmt, newRecords)
            connection.commit()
        return newRecords
    
    except Exception as e:
        print("Unable to complete operation: ", e)
        return None
    

#Delete any expired challenges.
#Should run this method BEFORE verifying a completed challenge.
#Returns a bool describing its success.
def pruneChallenges(*, connection: sqlite3.Connection):
    try:
        with connection:
            pruneStmt = "DELETE FROM tblChallenges WHERE ExpireTimestamp < ?;"
            currentTime = str(int(time.time()))
            connection.execute(pruneStmt, [currentTime]) #This command expects a sequence/list for the substitution variable. currentTime must be wrapped in a list or else it uses individual str characters.
            connection.commit()
        return True
    except Exception as e:
        print("Unable to complete challenge prune operation: ", e)
        return False


#Returns a list if successful, and None if failed.
#Throws an exception if it cannot prune the challenge database first.
def getChallenge(*, connection: sqlite3.Connection, challengeID: str):
    #For security reasons, prune the challenge table BEFORE querying it.
    if not pruneChallenges(connection=connection):
        raise RuntimeError("Unable to remove expired challenges from the database!")
    
    try:
        with connection:
            stmt = 'SELECT * FROM tblChallenges WHERE ChallengeID = ?;'
            cursor = connection.execute(stmt, [challengeID])
            results = cursor.fetchall()
            return results
    except Exception as e:
        print("Unable to query the challenge table: ", e)
        return None


#Deletes all challenges with the given UUID.
#Returns True if successful and False if not.
#IMPORTANT: SQLite3 still returns True if a valid deletion command targets zero records.
#Therefore, if this command returns False, you should assume that one or more target records still remain.
def deleteChallengesWithUUID(*, connection: sqlite3.Connection, challengeID: str):
    #Pruning shouldn't be necessary as we're not retrieving any data, just deleting
    try:
        with connection:
            pruneStmt = "DELETE FROM tblChallenges WHERE ChallengeID = ?;"
            connection.execute(pruneStmt, [challengeID]) #This command expects a sequence/list for the substitution variable. currentTime must be wrapped in a list or else it uses individual str characters.
            connection.commit()
        return True
    except Exception as e:
        print("Unable to delete target records: ", e)
        return False


#Returns true if the given UserID is already registered, and False if not.
#Raises an error if the database fails to list all registered users.
def doesUserExist(*, connection: sqlite3.Connection, userID: str):
    result = executeQuery(connection = connection, query = 'SELECT UserID from tblRegisteredUsers;')
    if result is None:
        #Unable to list the current UUIDs
        raise RuntimeError("dmaftServerDB.doesUserExist(): Failed to list all registered users!")
    
    currentUserIDs = []
    for row in result:
        currentUserIDs.append(str(row[0]).upper())

    return (userID.upper() in currentUserIDs)


#Adds a new user to the system with no conversations.
#Returns True if successful and False if not.
def registerUser(*, connection: sqlite3.Connection, publicKey: rsa.RSAPublicKey):
    pubKeySHA512 = crypto.getSHA512(crypto.getPubKeyBytes(publicKey))

    result = executeQuery(connection = connection, query = 'SELECT UserID from tblRegisteredUsers;')
    if result is None:
        #Unable to list the current UUIDs
        return None
    
    #Make sure that the new User IDs we generate don't conflict with any existing ones
    currentUUIDs = []
    for row in result:
        currentUUIDs.append(str(row[0]).upper())

    while True:
        newUserUUID = str(uuid.uuid4()).upper()
        if newUserUUID not in currentUUIDs:
            break
    
    try:
        with connection:
            registerStmt = 'INSERT INTO tblRegisteredUsers (UserID, UserPublicKeySHA2_512, ConversationIDs) VALUES (?,?,?);'
            connection.execute(registerStmt, (newUserUUID, pubKeySHA512, None,))
            connection.commit()
        return newUserUUID
    except Exception as e:
        print("Unable to register new user: ", e)
        return None

#Searches the database by UserID.
#Returns a list of results if successful and None if failed.
def searchUserByID(*, connection: sqlite3.Connection, userID: str):
    try:
        with connection:
            stmt = 'SELECT UserID, UserName FROM tblRegisteredUsers WHERE UserID = ?;'
            cursor = connection.execute(stmt, [userID])
            results = cursor.fetchall()
            return results
    except Exception as e:
        print("Unable to query the registered users table: ", e)
        return None
    
#Searches the database by UserName.
#Returns a list of results if successful and None if failed.
def searchUsersByName(*, connection: sqlite3.Connection, userName: str):
    try:
        with connection:
            stmt = 'SELECT UserID, UserName FROM tblRegisteredUsers WHERE UserName LIKE ?;'
            cursor = connection.execute(stmt, [userName])
            results = cursor.fetchall()
            return results
    except Exception as e:
        print("Unable to query the registered users table: ", e)
        return None
    
#Updates a user's profile data.
#Returns True if successful and False if not.
#It is expected that the server will only call this method on behalf
#of authenticated users, to update their OWN profiles.
def updateUserProfileData(
        *, 
        connection: sqlite3.Connection, 
        userID: str, 
        userName: str, 
        userBio: str, 
        userStatus: str, 
        userPic: bytes
        ):
    
    #Verify that the userID is legitimate.
    try:
        if not doesUserExist(connection=connection, userID=userID):
            print("dmaftServerDB.updateUserProfileData(): User", userID, "is not registered! Aborting.")
            return False
    except:
        return False
    
    #Update the requested data.
    try:
        with connection:
            updateProfileStmt = 'UPDATE tblRegisteredUsers SET UserName = ?, Status = ?, Bio = ?, ProfilePic = ? WHERE UserID = ?;'
            connection.execute(updateProfileStmt, (userName, userStatus, userBio, userPic, userID))
            connection.commit()
            return True
    except:
        print("dmaftServerDB.updateUserProfileData(): Failed to update the profile info for user", userID)
        return False

#Deletes any expired tokens.
#Should run this method BEFORE verifying a token.
#Returns True if successful and False if not.
def pruneTokens(*, connection: sqlite3.Connection):
    try:
        with connection:
            pruneStmt = "DELETE FROM tblTokens WHERE ExpireTimestamp < ?;"
            currentTime = str(int(time.time()))
            connection.execute(pruneStmt, [currentTime]) #This command expects a sequence/list for the substitution variable. currentTime must be wrapped in a list or else it uses individual str characters.
            connection.commit()
        return True
    except Exception as e:
        print("Unable to complete token prune operation: ", e)
        return False

#Creates a token for an existing, already-registered user.
#Returns the TokenID and TokenSecret if successful.
#Returns None if failed.
#Raises an error if the system failed to prune old tokens (RuntimeError) or if the specified user doesn't exist (ValueError).
def createToken(*, connection: sqlite3.Connection, userID: str):
    if not pruneTokens(connection=connection):
        raise RuntimeError("Failed to prune the Token database of old tokens!")
    
    if not doesUserExist(connection=connection, userID=userID):
        raise ValueError("The specified user ID doesn't exist!")
    
    result = executeQuery(connection = connection, query = 'SELECT TokenID from tblTokens;')
    if result is None:
        #Unable to list the current UUIDs
        return None
    
    #Make sure that the new User IDs we generate don't conflict with any existing ones
    currentUUIDs = []
    for row in result:
        currentUUIDs.append(str(row[0]).upper())
    
    while True:
        tokenID = str(uuid.uuid4()).upper()
        if tokenID not in currentUUIDs:
            break

    tokenSecret = random.randbytes(32)
    tokenHash = crypto.getSHA256(tokenSecret)
    expireTime = int(time.time()) + 86400 #The token is valid for 24 hours

    try:
        with connection:
            newTokenStmt = 'INSERT INTO tblTokens (TokenID, TokenHash, User, ExpireTimestamp) VALUES (?,?,?,?)'
            connection.execute(newTokenStmt, (tokenID, tokenHash, userID, expireTime))
            connection.commit()
        return {
            'UserId':userID,
            'TokenId':tokenID,
            'TokenSecret':tokenSecret
        }
    except Exception as e:
        print("Failed to create the requested token:", e)
        return None
    

#Returns any tokens found given the unique TokenID.
#Returns a list of tokens if successful, and None if not.
#Raises a RuntimeError if the token database cannot first be pruned of old tokens.
def getToken(*, connection: sqlite3.Connection, tokenID: str):
    #For security reasons, prune the challenge table BEFORE querying it.
    if not pruneTokens(connection=connection):
        raise RuntimeError("Unable to remove expired tokens from the database!")
    
    try:
        with connection:
            stmt = 'SELECT * FROM tblTokens WHERE TokenID = ?;'
            cursor = connection.execute(stmt, [tokenID])
            results = cursor.fetchall()
            return results
    except Exception as e:
        print("Unable to query the tokens table: ", e)
        return None
    

def validateToken(*, connection: sqlite3.Connection, tokenID: str, tokenSecret: bytes):
    if not pruneTokens(connection=connection):
        raise RuntimeError("Unable to remove expired tokens from the database!")
    
    try:
        with connection:
            stmt = 'SELECT * FROM tblTokens WHERE TokenID = ?;'
            cursor = connection.execute(stmt, [tokenID])
            results = cursor.fetchall()
    except Exception as e:
        print("Unable to query the tokens table: ", e)
        return None
    
    if len(results) > 1:
        print("More than one token found for this query. Assuming the TokenID is incorrect.")
        return None
    
    if len(results) == 0:
        return None
    
    record = results[0]
    realTokenID, correctHash, userID, expireTimestamp = record
    if tokenID.upper() != str(realTokenID).upper():
        return None
    
    givenHash = crypto.getSHA256(tokenSecret)
    if givenHash == correctHash:
        return userID
    else:
        return None

    

#Deletes all tokens with the given TokenID.
#Returns True if successful and False if not.
#IMPORTANT: SQLite3 still returns True if a valid deletion command targets zero records.
#Therefore, if this command returns False, you should assume that one or more target records still remain.
def deleteTokensWithID(*, connection: sqlite3.Connection, tokenID: str):
    #Pruning shouldn't be necessary as we're not retrieving any data, just deleting
    try:
        with connection:
            pruneStmt = "DELETE FROM tblTokens WHERE TokenID = ?;"
            connection.execute(pruneStmt, [tokenID]) #This command expects a sequence/list for the substitution variable. currentTime must be wrapped in a list or else it uses individual str characters.
            connection.commit()
        return True
    except Exception as e:
        print("Unable to delete target records: ", e)
        return False


#Deletes all challenges with the given UserID.
#Returns True if successful and False if not.
#This effectively signs the associated user out of the app on all devices!!
#IMPORTANT: SQLite3 still returns True if a valid deletion command targets zero records.
#Therefore, if this command returns False, you should assume that one or more target records still remain.
def deleteTokensWithUserID(*, connection: sqlite3.Connection, userID: str):
    #Pruning shouldn't be necessary as we're not retrieving any data, just deleting
    try:
        with connection:
            pruneStmt = "DELETE FROM tblTokens WHERE User = ?;"
            connection.execute(pruneStmt, [userID]) #This command expects a sequence/list for the substitution variable. currentTime must be wrapped in a list or else it uses individual str characters.
            connection.commit()
        return True
    except Exception as e:
        print("Unable to delete target records: ", e)
        return False
    

#Creates a new conversation for the given participants.
#Returns the new conversation UUID if successful, and None if failed.
#Raises a ValueError if any provided UserIDs don't exist in the database system.
def createNewConversation(*, connection: sqlite3.Connection, userIDs: list[str]):
    #Make sure the provided users all exist
    for userID in userIDs:
        if not doesUserExist(connection=connection, userID=userID):
            raise ValueError("User ID", userID, "is not registered in the database!")
    
    #Serialize the userlist into JSON so we can store it
    jsonUserIDs = json.dumps(userIDs)

    result = executeQuery(connection = connection, query = 'SELECT ConversationID from tblConversations;')
    if result is None:
        #Unable to list the current UUIDs
        return None
    
    #Make sure that the new conversation ID we generate doesn't conflict with any existing ones
    currentUUIDs = []
    for row in result:
        currentUUIDs.append(str(row[0]).upper())

    while True:
        convoUUID = str(uuid.uuid4()).upper()
        if convoUUID not in currentUUIDs:
            break
    
    try:
        with connection:
            newConvoStmt = 'INSERT INTO tblConversations (ConversationID, Participants) VALUES (?,?);'
            connection.execute(newConvoStmt, (convoUUID, jsonUserIDs))
            connection.commit()
        return convoUUID
    except Exception as e:
        print("Unable to create conversation:", e)
        return None
    

#Searches the database by ConversationID.
#Returns a list of results if successful and None if failed.
def getConversationByID(*, connection: sqlite3.Connection, conversationID: str):
    try:
        with connection:
            stmt = 'SELECT * FROM tblConversations WHERE ConversationID = ?;'
            cursor = connection.execute(stmt, [conversationID])
            results = cursor.fetchall()
            return results
    except Exception as e:
        print("Unable to query the conversation table: ", e)
        return None
    

def doesConversationExist(*, connection: sqlite3.Connection, conversationID: str):
    result = executeQuery(connection = connection, query = 'SELECT ConversationID from tblConversations;')
    if result is None:
        #Unable to list the current UUIDs
        raise RuntimeError("dmaftServerDB.doesConversationExist(): Failed to list all registered conversations!")
    
    currentConvoIDs = []
    for row in result:
        currentConvoIDs.append(str(row[0]).upper())

    return (conversationID.upper() in currentConvoIDs)
    


#MAILBOX DATA

#Adds a message to the mailbox for the recipient, to be delivered later.
#Returns True if successful and False if not.
#Raises a ValueError if the specified ExpireTime exists in the past,
#or if the specified recipient isn't a registered user.
#NOTE: For system messages (new conversation created, etc.) specify a conversationID of SYSTEM.
def addToMailbox(*, connection: sqlite3.Connection, conversationID: str, expireTime: int, recipientID: str, msgDict: dict):
    #Make sure the expire time is valid.
    currentTime = int(time.time())
    if currentTime > expireTime:
        raise ValueError("The expire time must be later than the current time!")
    
    #Make sure that we have a valid conversation.
    #Individual SYSTEM messages are excluded from this check.
    if conversationID.upper() != 'SYSTEM':
        if not doesConversationExist(connection=connection, conversationID=conversationID):
            raise ValueError("The provided conversation ID doesn't exist!")
    
        #Make sure the specified recipient is a member of this conversation
        conversations = getConversationByID(connection=connection, conversationID=conversationID)
        if len(conversations) != 1:
            raise RuntimeError("dmaftServerDB.addToMailbox(): " + str(len(conversations)) + " were found for conversation ID " + conversationID + "! Database corruption has likely occurred.")

        convoRecord = conversations[0]
        userlist = json.loads(convoRecord[1])
        for user in userlist:
            user = user.upper()
        if recipientID.upper() not in userlist:
            raise ValueError("dmaftServerDB.addToMailbox(): The specified recipient user ID", recipientID, "is not a member of conversation", conversationID,"!")

    msgData = json.dumps(msgDict)

    try:
        with connection:
            insertMailboxStmt = 'INSERT INTO tblMailbox (ConversationID, ArriveTimestamp, ExpireTimestamp, Recipient, Message) VALUES (?,?,?,?,?);'
            connection.execute(insertMailboxStmt, (conversationID, currentTime, expireTime, recipientID, msgData))
            connection.commit()
        return True
    except Exception as e:
        print("Unable to save message to mailbox:", e)
        return False
    

#WARNING: RUNNING THIS MIGHT RESULT IN DISCREPANCIES BETWEEN SENDER AND RECEIVER CLIENTS.
#THERE IS CURRENTLY NO WAY TO NOTIFY THE SENDER THAT THE RECIPIENT NEVER GOT THEIR MESSAGE.
#Returns True if successful and False if not.
def purgeOldMailboxItems(connection: sqlite3.Connection):
    try:
        with connection:
            msgPruneStmt = "DELETE FROM tblMailbox WHERE ExpireTimestamp < ?;"
            currentTime = str(int(time.time()))
            connection.execute(msgPruneStmt)
            connection.commit()
        return True
    except Exception as e:
        print("Failed to remove old messages from the mailbox:", e)
        return False
    
#Returns a list if successful and None if failed.
def getMsgsForUser(*, connection: sqlite3.Connection, userID: str):
    try:
        with connection:
            stmt = 'SELECT ROWID, * FROM tblMailbox WHERE Recipient = ?;' #The RowID is an automatic primary key for each table and enables targeted deletion. It must be explicitly requested.
            cursor = connection.execute(stmt, [userID])
            return cursor.fetchall()
    except Exception as e:
        print("Unable to query the mailbox:", e)
        return None
    
#Returns True if successful and False if not.
#Valid deletion commands targeting zero rows will still return True.
#Treat False as if an error occurred.
def deleteMsgFromMailbox(*, connection: sqlite3.Connection, rowID: int):
    try:
        with connection:
            msgDeleteStmt = 'DELETE FROM tblMailbox WHERE ROWID = ?;'
            connection.execute(msgDeleteStmt, [rowID])
            connection.commit()
        return True
    except Exception as e:
        print("Failed to delete the specified message:", e)
        return False

#Returns True if successful and False if not.
#Valid deletion commands targeting zero rows will still return True.
#Treat False as if an error occurred.
def deleteAllMsgsForUser(*, connection: sqlite3.Connection, userID: int):
    try:
        with connection:
            msgDeleteStmt = 'DELETE FROM tblMailbox WHERE Recipient = ?;'
            connection.execute(msgDeleteStmt, [userID])
            connection.commit()
        return True
    except Exception as e:
        print("Failed to delete messages for user", userID, ":", e)
        return False
