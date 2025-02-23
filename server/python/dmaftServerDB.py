import bcrypt
import sqlite3
import uuid
import time

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
        destroyTable = "DROP TABLE " + tableName
        try:
            executeQuery(connection=connection, query=destroyTable)
        except:
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
initRegisteredUsersTbl = "CREATE TABLE tblRegisteredUsers (UserPublicKeySHA2_512 BLOB(64) NOT NULL PRIMARY KEY, ConversationIDs BLOB);"
initConversationTbl = "CREATE TABLE tblConversations (ConversationID TINYTEXT NOT NULL PRIMARY KEY,Participants BLOB NOT NULL);"
initMailboxTbl = "CREATE TABLE tblMailbox (ConversationID TINYTEXT NOT NULL, ArriveTimestamp INT, ExpireTimestamp INT NOT NULL, Recipient BLOB(64) NOT NULL, Message LONGBLOB(60000000) NOT NULL, FOREIGN KEY(Recipient) REFERENCES tblRegisteredUsers(UserPublicKeySHA2_512));"
initChallengeTbl = "CREATE TABLE tblChallenges (ChallengeID TINYTEXT NOT NULL PRIMARY KEY, Challenge BLOB NOT NULL, UserPublicKey BLOB NOT NULL, ExpireTimestamp INT NOT NULL);"
initTokenTbl = "CREATE TABLE tblTokens (TokenID BLOB NOT NULL PRIMARY KEY, TokenSecret BLOB NOT NULL, UserPublicKeyHash BLOB NOT NULL, ExpireTimestamp INT NOT NULL, FOREIGN KEY(UserPublicKeyHash) REFERENCES tblRegisteredUsers(UserPublicKeySHA2_512));"

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
        [('CREATE TABLE tblRegisteredUsers (UserPublicKeySHA2_512 BLOB(64) NOT NULL PRIMARY KEY, ConversationIDs BLOB)',)],
        [('CREATE TABLE tblConversations (ConversationID TINYTEXT NOT NULL PRIMARY KEY,Participants BLOB NOT NULL)',)],
        [('CREATE TABLE tblMailbox (ConversationID TINYTEXT NOT NULL, ArriveTimestamp INT, ExpireTimestamp INT NOT NULL, Recipient BLOB(64) NOT NULL, Message LONGBLOB(60000000) NOT NULL, FOREIGN KEY(Recipient) REFERENCES tblRegisteredUsers(UserPublicKeySHA2_512))',)],
        [('CREATE TABLE tblChallenges (ChallengeID TINYTEXT NOT NULL PRIMARY KEY, Challenge BLOB NOT NULL, UserPublicKey BLOB NOT NULL, ExpireTimestamp INT NOT NULL)',)],
        [('CREATE TABLE tblTokens (TokenID BLOB NOT NULL PRIMARY KEY, TokenSecret BLOB NOT NULL, UserPublicKeyHash BLOB NOT NULL, ExpireTimestamp INT NOT NULL, FOREIGN KEY(UserPublicKeyHash) REFERENCES tblRegisteredUsers(UserPublicKeySHA2_512))',)],
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
            raise RuntimeError("Expected table schema is missing from database: " + properSchema)
    
    return conn

#DATABASE OPERATION METHODS
#IMPORTANT: All methods below assume that a valid server is running with the schema described above.

#Generates and adds authentication challenges to the challenge table.
#Returns the list of generated challenge rows if successful, or None if failed.
def addChallenges(*, connection: sqlite3.Connection, challenges: list[bytes], publicKeys: list[bytes]):
    if len(challenges) != len(publicKeys):
        raise ValueError("Challenge list must have the same number of items as the public key list!")
    
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
        newRecords.append((newUUIDs[i], challenges[i], publicKeys[i], expireTime))
    
    try:
        with connection:
            stmt = 'INSERT INTO tblChallenges (ChallengeID, Challenge, UserPublicKey, ExpireTimestamp) VALUES (?,?,?,?);'
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
def getChallenge(*, connection: sqlite3.Connection, challengeId: str):
    #For security reasons, prune the challenge table BEFORE querying it.
    if not pruneChallenges(connection=connection):
        raise RuntimeError("Unable to remove expired challenges from the database!")
    
    try:
        with connection:
            stmt = 'SELECT * FROM tblChallenges WHERE ChallengeID = ?;'
            cursor = connection.execute(stmt, [challengeId])
            results = cursor.fetchall()
            return results
    except Exception as e:
        print("Unable to query the challenge table: ", e)
        return None


#Deletes all challenges with the given UUID.
#Returns True if successful and False if not.
#IMPORTANT: SQLite3 still returns True if a valid deletion command targets zero records.
#Therefore, if this command returns False, you should assume that one or more target records still remain.
def deleteChallengesWithUUID(*, connection: sqlite3.Connection, challengeId: str):
    #Pruning shouldn't be necessary as we're not retrieving any data, just deleting
    try:
        with connection:
            pruneStmt = "DELETE FROM tblChallenges WHERE ChallengeID = ?;"
            connection.execute(pruneStmt, [challengeId]) #This command expects a sequence/list for the substitution variable. currentTime must be wrapped in a list or else it uses individual str characters.
            connection.commit()
        return True
    except Exception as e:
        print("Unable to delete target records: ", e)
        return False

#Adds a new user to the system if they don't already exist.
#If their public key hash already exists, this operation does nothing and returns True.
#If it doesn't exist, this operation adds them to the database with no conversations and returns True.
#If this function returns False, assume an error has occurred.
def registerPublicKeyHash(*, connection: sqlite3.Connection, publicKeyHashStr: str):
    #Check if this user already exists.
    if len(publicKeyHashStr) > 128:
        raise ValueError("The provided hash is too long and is invalid.")
    
    try:
        searchStmt = "SELECT FROM tblRegisteredUsers WHERE UserPublicKeySHA2_512 = ?;"
        cursor = connection.execute(searchStmt, [publicKeyHashStr])
        results = cursor.fetchall()
    except Exception as e:
        print("Unable to search the registeredUsers table: ", e)
        return False
    
    if len(results) == 1:
        #User is already registered. Stop with success.
        return True
    
    elif len(results) > 1:
        #This should be impossible. Either the database is corrupt or there's a runtime error happening.
        #In either case, stop.
        raise RuntimeError("Multiple records were returned when searching the registeredUsers table by a public key hash.")
    
    #The provided public key hash isn't registered yet.
    #Register it.
    try:
        with connection:
            registerStmt = 'INSERT INTO tblRegisteredUsers (UserPublicKeySHA2_512) VALUES (?);'
            connection.execute(registerStmt, publicKeyHashStr)
            connection.commit()
    except Exception as e:
        print("Failed to register the specified public key hash: ", e)
        return False