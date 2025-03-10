import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';



//Note: Database files for Android apps are stored in the "/data/data/{package}/databases" folder in device storage. Access this in Android Studio 
//by opening the emulated device in device explorer and navigating to "/data/data/{package name}/databases/ChatLog_DB.db". This folder is 
//accessible only by someone with root access and the app that made the database.



//------------------------------------------------------------------------------------------------------------------------------------------------------------
// Database exception classes
//------------------------------------------------------------------------------------------------------------------------------------------------------------



//My be thrown for some database queries if no results are found.
class NoRowsException implements Exception{
  final String cause;
  NoRowsException(this.cause);
}



//May be thrown if a conversation table specified does not exist in the database.
class NoTableException implements Exception{
  final String cause;
  NoTableException(this.cause);
}



//------------------------------------------------------------------------------------------------------------------------------------------------------------
// Database entry classes
//------------------------------------------------------------------------------------------------------------------------------------------------------------



//Class to store contacts retrieved from and sent to the database.
class Contact {
  final String id; //The unique userID of the user.
  String name; //The non-unique username of the user.
  String status; //The user's status, a short message indicating a current mood or other tidbit.
  String bio; //The user's biography as set in their profile. 
  Uint8List pic; //A list of 8-bit unsigned integers containing a representation of the user's profile picture.

  Contact({
    required this.id,
    required this.name,
    required this.status,
    required this.bio,
    required this.pic,
  });
}



//Class to store conversations retrieved from and sent to the database.
class Conversation {
  final String convoID; //The unique convoID of the conversation.
  Uint8List convoMembers; //A list of userIDs for users participating in the conversation.

  Conversation({
    required this.convoID,
    required this.convoMembers,
  });
}



//Class to store message logs retrieved from and sent to the database.
class MsgLog {
  final String convoID; //The ID for the chat conversation in which the message was sent.
  final String msgID; //The unique ID for the message.
  final String msgType; //A string keyword indicating the format of the given file or message.
  final String senderID; //UserID for the message's sender.
  final String rcvTime; //Time the server received the message. May not align with the time the recipient's client gets the message if they were offline.
  Uint8List message; //Message, file, etc. sent to the recipient.

  MsgLog({
    required this.convoID,
    required this.msgID,
    required this.msgType,
    required this.senderID,
    required this.rcvTime,
    required this.message,
  });
}



//------------------------------------------------------------------------------------------------------------------------------------------------------------
// Database helper class
//------------------------------------------------------------------------------------------------------------------------------------------------------------



//Class for ChatLog Database operations.
class ClientDB{
  //Singleton pattern to ensure only one instance of ClientDB may exist at once.
  static final ClientDB instance = ClientDB._constructor();
  ClientDB._constructor();

  //If a db is already open, return it. Otherwise, open the db.
  static Database? _db; //Database object
  Future<Database> get database async{
    if(_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }

  //Store database column names for easier adjustment later.
  final String _contactsTableName = "contactTable";
  final String _contactsIDName = "userID";
  final String _contactsNameName = "userName";
  final String _contactsStatusName = "userStatus";
  final String _contactsBioName = "userBio";
  final String _contactsPictureName = "userProfilePic";
  
  final String _conversationTableName = "conversationTable";
  final String _convoIDName = "convoID";
  final String _convoMembersName = "convoMembers";

  final String _msglogsMessageIDName = "msgID";
  final String _msglogsMessageTypeName = "msgType";
  final String _msglogsSenderIDName = "senderID";
  final String _msglogsReceivedTimeName = "receivedTime";
  final String _msglogsMessageName = "message";



  //Universal methods-------------------------------------------------------------------------------------------------------------------------------------------



  //Method: getDatabase.
  //Parameters: None.
  //Returns: A future Sqflite Database object.
  //Example Usage: Called automatically during ClientDB instance construction so just use "final ClienttDB <name> = ClientDB.instance;".
  //Description: Opens the local client database and returns a future database object.
  Future<Database> getDatabase() async{
    //Get database path. Uses default system path for database storage.
    final dbDirPath = await getDatabasesPath();
    final dbPath = join(dbDirPath, 'client_db');
    //Open database. Creates one if it doesn't exist.
    final database = await openDatabase(
      dbPath,
      version: 1,
      //When a new database is created, create tables for contacts and conversations.
      onCreate: (db, version) { 
        //Create a table for contact storage.
        db.rawQuery("""
          CREATE TABLE "$_contactsTableName" (
            $_contactsIDName TEXT PRIMARY KEY, 
            $_contactsNameName TEXT NOT NULL, 
            $_contactsStatusName TEXT NOT NULL,
            $_contactsBioName TEXT NOT NULL,
            $_contactsPictureName BLOB NOT NULL
          )
        """);
        
        //Create a table for conversation storage.
        db.rawQuery("""
          CREATE TABLE "$_conversationTableName" (
            $_convoIDName TEXT PRIMARY KEY, 
            $_convoMembersName BLOB NOT NULL
        )
        """);
      }
    );
    return database;
  }



  //Contact methods---------------------------------------------------------------------------------------------------------------------------------------------



  //Method: addContact.
  //Parameters: Contact object to be added.
  //Returns: Nothing.
  //Example Usage: "clientdb1.addContact(<a_Contact_object>);".
  //Description: Creates a database entry using properties of a Contact object. Will throw an exception if the primary key value (userID) already exists in the 
  //  database.
  void addContact(Contact contact) async{
    final db = await database;
    //Insert data.
    await db.insert(
      _contactsTableName, 
      {
        _contactsIDName: contact.id,
        _contactsNameName: contact.name,
        _contactsStatusName: contact.status,
        _contactsBioName: contact.bio,
        _contactsPictureName: contact.pic,
      }
    );
  }



  //Method: getContacts.
  //Parameters: Optional string that will be searched for in the id, name, status, and bio columns.
  //Returns: A future list of Contact objects.
  //Example usage: "List<Contact> contactlist = await clientdb1.getContacts();".
  //Description: Fetches some or all data from the contacts database and returns them as a future list of Contact objects. Can be given a string search 
  //  phrase which will be applied to the id, name, status, and bio fields of each contact. Contacts containing the search string in any of these fields will
  //  be returned. Example: A search string of "45" would select a contact with an id of "123456" and a contact with a bio containing "I am 45 years old."
  Future<List<Contact>> getContacts([String searchPattern = ""]) async{
    final db = await database;
    final dynamic data;
    //No search pattern given, so fetch the entire table of contacts.
    if(searchPattern.isEmpty){
      data = await db.query(_contactsTableName);
    }
    //Use the search pattern to fetch only rows with some matching value(s).
    else{
      data = await db.rawQuery("""
      SELECT 
      * 
      FROM $_contactsTableName 
      WHERE
      $_contactsIDName LIKE ? OR
      $_contactsNameName LIKE ? OR
      $_contactsStatusName LIKE ? OR
      $_contactsBioName LIKE ?
      ORDER BY
      $_contactsNameName
      """,
      ["%$searchPattern%", "%$searchPattern%", "%$searchPattern%", "%$searchPattern%"]
      );
    }
    //Transform database data into a list of Contact objects
    List<Contact> contacts = data
      .map(
        (e) => Contact( //Map database data into Contact class fields.
          id: e[_contactsIDName] as String, 
          name: e[_contactsNameName] as String,
          status: e[_contactsStatusName] as String,
          bio: e[_contactsBioName] as String,  
          pic: e[_contactsPictureName] as Uint8List,
        )
      ).toList().cast<Contact>(); //Cast dynamic type data to Contact type.
    return contacts;
  }



  //Method: modifyContact.
  //Parameters: Updated contact object.
  //Returns: Nothing.
  //Example Usage: "clientdb1.modifyContact(<a_Contact_object>);".
  //Description: Modify a contact entry in the database using the userID. Changes all fields except userID to match the Contact object's properties. Does 
  //  nothing if no entry exists with the given userID.
  void modifyContact(Contact contact) async{
    final db = await database;
    await db.rawQuery("""
      UPDATE 
      $_contactsTableName 
      SET 
      $_contactsNameName = ?,
      $_contactsStatusName = ?, 
      $_contactsBioName = ?
      
      WHERE 
      $_contactsIDName = ?
      """,
      [contact.name, contact.status, contact.bio, contact.id]
    );
  }



  //Method: delContact.
  //Parameters: Contact object corresponding to the database entry to be deleted.
  //Returns: Nothing.
  //Example Usage: "clientdb1.delContact(<a_Contact_object>);".
  //Description: Remove a contact entry from the database using the given Contact object's userID. Will do nothing if the given contact isn't in the database.
  void delContact(Contact contact) async{
    final db = await database;
    await db.rawQuery("""
    DELETE FROM 
    $_contactsTableName 
    WHERE $_contactsIDName = ?
    """,
    [contact.id]
    );
  }



  //Conversation methods----------------------------------------------------------------------------------------------------------------------------------------



  //Method: addConvo.
  //Parameters: Conversation object to be used to make a database entry.
  //Returns: Nothing.
  //Example Usage: "clientdb1.addConvo(<a_conversation_object>);".
  //Description: Note that this does NOT create a message log conversation table! This creates an entry in the conversations table used to track which users are
  //  in each conversation.
  void addConvo(Conversation convo) async{
    final db = await database;
    //Insert data.
    await db.insert(
      _conversationTableName, 
      {
        _convoIDName: convo.convoID,
        _convoMembersName: convo.convoMembers,
      }
    );
  }



  //Method: getConvo.
  //Parameters: Conversation ID of the conversation entry.
  //Returns: A conversation object.
  //Example Usage: "clientdb1.getConvo(<a_conversation_id>);".
  //Description: Fetches a conversation object from the database conversations table using the conversation ID. Throws an exception if no conversation with that
  //  id exists.
  Future<Conversation> getConvo(String targetConvoID) async{
    final db = await database;
    final dynamic data;
    //Fetch a row with the given convoID.
    data = await db.rawQuery("""
    SELECT *
    FROM $_conversationTableName
    WHERE $_convoIDName = ?
    """, [targetConvoID]);
  
    //If there are no rows for the conversation, throw an exception
    if(data == null){
      throw NoRowsException("There are no entries in the table for conversation $targetConvoID");
    }
    //Transform database data into a list of Conversation objects
    Conversation convos = data
      .map(
        (e) => Conversation( //Map database data into Conversation class fields.
          convoID: targetConvoID,
          convoMembers: e[_convoMembersName] as Uint8List, 
        )
      ).toList().cast<Conversation>(); //Cast dynamic type data to Conversation type.
    return convos;
  }



  //Method: updateConvo.
  //Parameters: Updated Conversation object.
  //Returns: Nothing.
  //Example Usage: "clientdb1.modifyConvo(<a_Conversation_object>);".
  //Description: Updates an existing conversation database entry with the properties of the given Conversation object. Does nothing if there is no database 
  //  entry with the same convoID.
  void modifyConvo(Conversation convo) async{
    final db = await database;
    await db.rawQuery("""
      UPDATE 
      $_conversationTableName 
      SET 
      $_convoMembersName = ?, 
      WHERE 
      $_convoIDName = ?
      """,
      [convo.convoMembers, convo.convoID]
    );
  }



  //Method: delConvo.
  //Parameters: Conversation object corresponding to the database entry to be deleted.
  //Returns: Nothing.
  //Example Usage: "clientdb1.delConvo(<a_Conversation_object>);".
  //Description: Remove a message log entry from the database using the convoID. Will do nothing if the given conversation isn't in the database.
  void delConvo(Conversation convo) async{
    final db = await database;
    await db.rawQuery("""
    DELETE FROM 
    $_conversationTableName 
    WHERE $_convoIDName = ?
    """,
    [convo.convoID]
    );
  }



  //Message log methods-----------------------------------------------------------------------------------------------------------------------------------------



  //Method: addMsgLog.
  //Parameters: MsgLog object to be added. Note that no fields can be null.
  //Returns: Nothing.
  //Example Usage: "clientdb1.addMsgLog(<a_message_log_object>);".
  //Description: Adds a new message log to the database. Creates a table for the conversation if there isn't already one.
  void addChatLog(MsgLog msglog) async{
    final db = await database;
    //Check if a table already exists for the conversation ID.
    dynamic tables = await db.rawQuery("""
      SELECT COUNT(*) 
      FROM sqlite_master 
      WHERE type = 'table' 
      AND name = ?
    """, [msglog.convoID]);
    //No table exists for this conversation, so create one.
    if(tables[0]["COUNT(*)"] == 0){
      await db.rawQuery("""
      CREATE TABLE "${msglog.convoID}" (
          $_msglogsMessageIDName TEXT PRIMARY KEY,
          $_msglogsMessageTypeName TEXT NOT NULL,
          $_msglogsSenderIDName TEXT NOT NULL, 
          $_msglogsReceivedTimeName TEXT NOT NULL,
          $_msglogsMessageName BLOB NOT NULL
      )"""
      );
    }
    //A table exists for the conversation, so just insert the message log.
    await db.rawQuery("""
      INSERT INTO "${msglog.convoID}"
      VALUES(
        ?, 
        ?, 
        ?, 
        ?,
        ?
      )
      """, [msglog.msgID, msglog.msgType, msglog.senderID, msglog.rcvTime, msglog.message]
    );
  }



  //Method: getMsgLogs.
  //Parameters: Conversation ID for the message logs.
  //Returns: A future list of MsgLog objects.
  //Example Usage: "List<MsgLog> mymsglogs1 = await clientdb1.getMsgLogs(<a_conversation_id>)".
  //Description: Returns a list of message log objects corresponding to the provided conversation ID.
  Future<List<MsgLog>> getMsgLogs(String targetConvoID) async{
    final db = await database;
    final dynamic data;
    //Check if there's a table for the specified conversation.
    dynamic tables = await db.rawQuery("""
      SELECT COUNT(*) 
      FROM sqlite_master 
      WHERE type = 'table' 
      AND name = ?
    """, [targetConvoID]);
    //If there isn't a table with that ID, throw an exception
    if(tables[0]["COUNT(*)"] == 0){
      throw NoTableException("There is no table for conversation $targetConvoID");
    }
    //Fetch the msgLogs with the given convoID.
    else{
      data = await db.rawQuery("""
      SELECT *
      FROM $targetConvoID
      """);
    }
    //If there are no rows for the conversation, throw an exception
    if(data == null){
      throw NoRowsException("There are no entries in the table for conversation $targetConvoID");
    }
    //Transform database data into a list of MsgLog objects
    List<MsgLog> msglogs = data
      .map(
        (e) => MsgLog( //Map database data into Contact class fields.
          convoID: targetConvoID,
          msgID: e[_msglogsMessageIDName] as String, 
          msgType: e[_msglogsMessageTypeName] as String,
          senderID: e[_msglogsSenderIDName] as String,  
          rcvTime: e[_msglogsReceivedTimeName] as String,
          message: e[_msglogsMessageName] as Uint8List,
        )
      ).toList().cast<MsgLog>(); //Cast dynamic type data to Contact type.
    return msglogs;
  }



  //Method: modifyMsgLog.
  //Parameters: Updated MsgLog object.
  //Returns: Nothing.
  //Example Usage: 
  //Description: Updates an existing message log database entry with the properties of the given MsgLog object. Does nothing if there is no database entry 
  //  with the same msgID.
  void modifyMsgLog(MsgLog msglog) async{
    final db = await database;
    await db.rawQuery("""
      UPDATE 
      ${msglog.convoID} 
      SET 
      $_msglogsMessageTypeName = ?, 
      $_msglogsSenderIDName = ?,
      $_msglogsReceivedTimeName = ?,
      $_msglogsMessageName = ?
      WHERE 
      $_msglogsMessageIDName = ?
      """,
      [msglog.msgType, msglog.senderID, msglog.rcvTime, msglog.message]
    );
  }



  //Method: delMsgLog.
  //Parameters: MsgLog object corresponding to the database entry to be deleted.
  //Returns: None.
  //Example Usage: "clientdb1.delMsgLog(<a_message_log_object>);".
  //Description: Remove a message log entry from the database using the convoID and msgID. Will do nothing if the given message isn't in the database.
  void delChatLog(MsgLog msglog) async{
    final db = await database;
    await db.rawQuery("""
    DELETE FROM 
    ${msglog.convoID} 
    WHERE $_msglogsMessageIDName = ?
    """,
    [msglog.msgID]
    );
  }

}

