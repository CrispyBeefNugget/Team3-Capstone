import bcrypt
import sqlite3



#INITIALIZATION FUNCTIONS
#Safe by default, but can erase data if you tell them to!!


def executeQuery(*, cursor: sqlite3.Cursor, query: str):
    if not sqlite3.complete_statement(query):
        raise ValueError("dmaftServerDB.executeQuery(): Invalid SQL query string!")

    try:
        cursor.execute(query)
    except:
        raise RuntimeError("dmaftServerDB.executeQuery(): Provided query failed to execute.")
    
    results = cursor.fetchall()
    return results


def initTable(
        *, 
        cursor: sqlite3.Cursor, 
        destroyExistingTable: bool = False, 
        tableName: str,
        createStmt: str
        ):
    
    if destroyExistingTable:
        #DESTROY THE PREVIOUS TABLE FIRST.
        #If this errors out; no worries - it could just mean that the table already doesn't exist.
        destroyTable = "DROP TABLE " + tableName
        try:
            executeQuery(cursor=cursor, query=destroyTable)
        except:
            pass

    #Try to create the new table.
    try:
        getAllTables = "SELECT name FROM sqlite_master WHERE type='table';"
        tables = executeQuery(cursor=cursor, query=getAllTables)
        for table in tables:
            if str(table[0]).lower() == tableName.lower():
                #There's a conflicting table. Stop.
                return False
        
        #The table doesn't exist. We can safely create it.
        executeQuery(cursor=cursor, query=createStmt)
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

def getAllTableSchemas(*, cursor: sqlite3.Cursor):
    try:
        schemas = []
        tables = []
        allTablesResult = executeQuery(cursor=cursor, query="SELECT name FROM sqlite_master WHERE type='table';")
        for item in allTablesResult:
            tables.append(item[0])
        for table in tables:
            schema = executeQuery(cursor=cursor, query="select sql from sqlite_master where type = 'table' and name = '" + table + "';")
            schemas.append(schema)
        return schemas
    except:
        return None

def getAllTables(*, cursor: sqlite3.Cursor):
    try:
        schemas = []
        tables = []
        allTablesResult = executeQuery(cursor=cursor, query="SELECT name FROM sqlite_master WHERE type='table';")
        for item in allTablesResult:
            tables.append(item[0])
        return tables
    except:
        return None
    
def connectSandbox():
    print("WARNING: This is a dev function that will be removed in production!")
    print("It only exists to make testing easier.")
    connection = sqlite3.connect('sandbox.db')
    return connection.cursor()