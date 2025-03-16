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



//May be thrown for some database queries if no results are found.
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



//Class to store contacts or personal user data retrieved from and sent to the database.
class Contact {
  final String id; //The unique userID of the user.
  String name; //The non-unique username of the user.
  String pronouns; //The user's preferred pronouns.
  String bio; //The user's biography as set in their profile. 
  Uint8List pic; //A list of 8-bit unsigned integers containing a representation of the user's profile picture.
  String lastModified; //A string in DateTime format indicating when the contact when last updated.

  Contact({
    required this.id,
    required this.name,
    required this.pronouns,
    required this.bio,
    required this.pic,
    required this.lastModified,
  });
}



//Class to store conversations retrieved from and sent to the database.
class Conversation {
  final String convoID; //The unique convoID of the conversation.
  List<String> convoMembers; //A list of userIDs for users participating in the conversation.
  String lastModified;

  Conversation({
    required this.convoID,
    required this.convoMembers,
    required this.lastModified,
  });
}



//Class to store message logs retrieved from and sent to the database.
class MsgLog {
  final String convoID; //The ID for the chat conversation in which the message was sent.
  final String msgID; //The unique ID for the message.
  String msgType; //A string keyword indicating the format of the given file or message.
  String senderID; //UserID for the message's sender.
  String rcvTime; //Time the server received the message. May not align with the time the recipient's client gets the message if they were offline.
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
    _db = await _getDatabase();
    return _db!;
  }

  //Store database column names for easier adjustment later.
  final String _userTableName = "userTable";
  
  final String _contactsTableName = "contactTable";
  final String _contactsIDName = "userID";
  final String _contactsNameName = "userName";
  final String _contactsPronounsName = "userPronouns";
  final String _contactsBioName = "userBio";
  final String _contactsPictureName = "userProfilePic";
  final String _contactsLastModifiedName = "lastModified";
  
  final String _conversationTableName = "conversationTable";
  final String _convoIDName = "convoID";
  final String _convoMembersName = "convoMembers";
  final String _convoLastModifiedName = "lastModified";

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
  Future<Database> _getDatabase() async{
    //Get database path. Uses default system path for database storage.
    final dbDirPath = await getDatabasesPath();
    final dbPath = join(dbDirPath, 'client_db');
    //Open database. Creates one if it doesn't exist.
    final database = await openDatabase(
      dbPath,
      version: 1,
      //When a new database is created, create tables for contacts and conversations.
      onCreate: (db, version) { 
        //Create a table for user data storage.
        db.rawQuery("""
          CREATE TABLE "$_userTableName" (
            $_contactsIDName TEXT PRIMARY KEY, 
            $_contactsNameName TEXT NOT NULL, 
            $_contactsPronounsName TEXT NOT NULL,
            $_contactsBioName TEXT NOT NULL,
            $_contactsPictureName BLOB NOT NULL,
            $_contactsLastModifiedName TEXT NOT NULL
          )
        """);

        //Loads a single blank user into the User table.
        db.insert(
          _userTableName, 
          {
            _contactsIDName: "",
            _contactsNameName: "",
            _contactsPronounsName: "",
            _contactsBioName: "",
            _contactsPictureName: Uint8List(8),
            _contactsLastModifiedName: "",
          }
        );
        
        //Create a table for contact storage.
        db.rawQuery("""
          CREATE TABLE "$_contactsTableName" (
            $_contactsIDName TEXT PRIMARY KEY, 
            $_contactsNameName TEXT NOT NULL, 
            $_contactsPronounsName TEXT NOT NULL,
            $_contactsBioName TEXT NOT NULL,
            $_contactsPictureName BLOB NOT NULL,
            $_contactsLastModifiedName TEXT NOT NULL
          )
        """);
        
        //Create a table for conversation storage.
        db.rawQuery("""
          CREATE TABLE "$_conversationTableName" (
            $_convoIDName TEXT PRIMARY KEY, 
            $_convoMembersName TEXT NOT NULL,
            $_convoLastModifiedName TEXT NOT NULL
        )
        """);
      }
    );
    return database;
  }



  //User methods---------------------------------------------------------------------------------------------------------------------------------------------



  //Method: getUser.
  //Parameters: None.
  //Returns: A future Contact object.
  //Example usage: "Contact user1 = await clientdb1.getUser();".
  //Description: Fetches the Contact object for the user's own information. Stores the same types of data as other Contact objects.
  Future<Contact> getUser() async{
    final db = await database;
    final dynamic data;
    //Fetch user table row.
    data = await db.query(_userTableName);
    //Transform database data into a Contact object
    Contact user = data
      .map(
        (e) => Contact( //Map database data into Contact class fields.
          id: e[_contactsIDName] as String, 
          name: e[_contactsNameName] as String,
          pronouns: e[_contactsPronounsName] as String,
          bio: e[_contactsBioName] as String,  
          pic: e[_contactsPictureName] as Uint8List,
          lastModified: e[_contactsLastModifiedName] as String,
        )
      ).toList().cast<Contact>(); //Cast dynamic type data to Contact type.
    return user;
  }



  //Method: modifyUser.
  //Parameters: Updated contact object.
  //Returns: Nothing.
  //Example Usage: "clientdb1.modifyUser(<a_Contact_object>);".
  //Description: Modify the user's Contact entry in the database. Changes all fields including userID to match the Contact object's properties.
  Future<void> modifyUser(Contact user) async{
    final db = await database;
    await db.rawQuery("""
      UPDATE 
      $_userTableName
      SET 
      $_contactsIDName = ?,
      $_contactsNameName = ?,
      $_contactsPronounsName = ?, 
      $_contactsBioName = ?,
      $_contactsLastModifiedName = ?
      """,
      [user.id, user.name, user.pronouns, user.bio, user.lastModified]
    );
  }



  //Contact methods---------------------------------------------------------------------------------------------------------------------------------------------



  //Method: addContact.
  //Parameters: Contact object to be added.
  //Returns: Nothing.
  //Example Usage: "clientdb1.addContact(<a_Contact_object>);".
  //Description: Creates a database entry using properties of a Contact object. Will throw an exception if the primary key value (userID) already exists in the 
  //  database.
  Future<void> addContact(Contact contact) async{
    final db = await database;
    //Insert data.
    await db.insert(
      _contactsTableName, 
      {
        _contactsIDName: contact.id,
        _contactsNameName: contact.name,
        _contactsPronounsName: contact.pronouns,
        _contactsBioName: contact.bio,
        _contactsPictureName: contact.pic,
        _contactsLastModifiedName: contact.lastModified,
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
      $_contactsPronounsName LIKE ? OR
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
          pronouns: e[_contactsPronounsName] as String,
          bio: e[_contactsBioName] as String,  
          pic: e[_contactsPictureName] as Uint8List,
          lastModified: e[_contactsLastModifiedName] as String,
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
  Future<void> modifyContact(Contact contact) async{
    final db = await database;
    await db.rawQuery("""
      UPDATE 
      $_contactsTableName 
      SET 
      $_contactsNameName = ?,
      $_contactsPronounsName = ?, 
      $_contactsBioName = ?,
      $_contactsLastModifiedName = ?
      
      WHERE 
      $_contactsIDName = ?
      """,
      [contact.name, contact.pronouns, contact.bio, contact.lastModified, contact.id]
    );
  }



  //Method: delContact.
  //Parameters: Contact object corresponding to the database entry to be deleted.
  //Returns: Nothing.
  //Example Usage: "clientdb1.delContact(<a_Contact_object>);".
  //Description: Remove a contact entry from the database using the given Contact object's userID. Will do nothing if the given contact isn't in the database.
  Future<void> delContact(Contact contact) async{
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
  //Description: Creates an entry in the conversations table used to track which users are in each conversation. Also creates a MsgLog table for the 
  //  conversation.
  Future<void> addConvo(Conversation convo) async{
    final db = await database;
    //Insert data.
    await db.insert(
      _conversationTableName, 
      {
        _convoIDName: convo.convoID,
        _convoMembersName: convo.convoMembers.join(","),
        _convoLastModifiedName: convo.lastModified,
      }
    );
    //Create a MsgLog table for the conversation.
    db.rawQuery("""
      CREATE TABLE "${convo.convoID}" (
        $_msglogsMessageIDName TEXT PRIMARY KEY,
        $_msglogsMessageTypeName TEXT NOT NULL,
        $_msglogsSenderIDName TEXT NOT NULL, 
        $_msglogsReceivedTimeName TEXT NOT NULL,
        $_msglogsMessageName BLOB NOT NULL
      )
    """);
  }



  //Method: getConvo.
  //Parameters: Conversation ID of the conversation entry.
  //Returns: A conversation object.
  //Example Usage: "Conversation myconv = clientdb1.getConvo(<a_conversation_id>);".
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
    Conversation convo = data
      .map(
        (e) => Conversation( //Map database data into Conversation class fields. Splits convo members around commas to reform a list.
          convoID: targetConvoID,
          convoMembers: e[_convoMembersName].split(",") as List<String>, 
          lastModified: e[_convoLastModifiedName],
        )
      ).toList().cast<Conversation>(); //Cast dynamic type data to Conversation type.
    return convo;
  }



  //Method: getAllConvos.
  //Parameters: Nothing.
  //Returns: A list of conversation objects.
  //Example Usage: "List<Conversation> myconvlist = clientdb1.getAllConvos();".
  //Description: Fetches all conversation objects from the database conversations table. Throws an exception if the table is empty.
  Future<List<Conversation>> getAllConvos() async{
    final db = await database;
    final dynamic data;
    //Fetch all rows from conversation table.
    data = await db.rawQuery("""
    SELECT *
    FROM $_conversationTableName
    """);
  
    //If there are no rows for the conversation, throw an exception
    if(data == null){
      throw NoRowsException("There are conversations in the table.");
    }
    //Transform database data into a list of Conversation objects
    List<Conversation> convos = data
      .map(
        (e) => Conversation( //Map database data into Conversation class fields. Splits convo members around commas to reform a list.
          convoID: e[_convoIDName] as String,
          convoMembers: e[_convoMembersName].split(",") as List<String>, 
          lastModified: e[_convoLastModifiedName],
        )
      ).toList().cast<Conversation>(); //Cast dynamic type data to Conversation type.
    return convos;
  }



  //Method: modifyConvo.
  //Parameters: Updated Conversation object.
  //Returns: Nothing.
  //Example Usage: "clientdb1.modifyConvo(<a_Conversation_object>);".
  //Description: Updates an existing conversation database entry with the properties of the given Conversation object. Does nothing if there is no database 
  //  entry with the same convoID.
  Future<void> modifyConvo(Conversation convo) async{
    final db = await database;
    await db.rawQuery("""
      UPDATE $_conversationTableName 
      SET 
      $_convoMembersName = ?,
      $_convoLastModifiedName = ?
      WHERE $_convoIDName = ?
      """,
      [convo.convoMembers.join(","), convo.lastModified, convo.convoID] //Convomembers list elements are joined into a string and separated by commas for storage.
    );
  }



  //Method: delConvo.
  //Parameters: Conversation object corresponding to the database entry to be deleted.
  //Returns: Nothing.
  //Example Usage: "clientdb1.delConvo(<a_Conversation_object>);".
  //Description: Remove a message log entry from the database using the convoID. Will do nothing if the given conversation isn't in the database. NOTE: Also
  //  deletes the message log table for the conversation. Be careful with usage.
  Future<void> delConvo(Conversation convo) async{
    final db = await database;
    await db.rawQuery("""
    DELETE FROM $_conversationTableName 
    WHERE $_convoIDName = ?
    """,
    [convo.convoID]
    );

    //Delete conversation message log table.
    await db.rawQuery("""
    DROP TABLE "${convo.convoID}"
    """
    );
  }



  //Message log methods-----------------------------------------------------------------------------------------------------------------------------------------



  //Method: addMsgLog.
  //Parameters: MsgLog object to be added. Note that no fields can be null.
  //Returns: Nothing.
  //Example Usage: "clientdb1.addMsgLog(<a_message_log_object>);".
  //Description: Adds a new message log to the database. There must already be a conversation table for it (created alongside the table entry made with 
  //  the addConvo method).
  Future<void> addMsgLog(MsgLog msglog) async{
    final db = await database;
    //Insert msglog into conversation table.
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
      FROM "$targetConvoID"
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
  Future<void> modifyMsgLog(MsgLog msglog) async{
    final db = await database;
    await db.rawQuery("""
      UPDATE 
      "${msglog.convoID}" 
      SET 
      $_msglogsMessageTypeName = ?, 
      $_msglogsSenderIDName = ?,
      $_msglogsReceivedTimeName = ?,
      $_msglogsMessageName = ?
      WHERE 
      $_msglogsMessageIDName = ?
      """,
      [msglog.msgType, msglog.senderID, msglog.rcvTime, msglog.message, msglog.msgID]
    );
  }



  //Method: delMsgLog.
  //Parameters: MsgLog object corresponding to the database entry to be deleted.
  //Returns: Nothing.
  //Example Usage: "clientdb1.delMsgLog(<a_message_log_object>);".
  //Description: Remove a message log entry from the database using the convoID and msgID. Will do nothing if the given message isn't in the database.
  Future<void> delMsgLog(MsgLog msglog) async{
    final db = await database;
    await db.rawQuery(
    """
    DELETE FROM "${msglog.convoID}" 
    WHERE $_msglogsMessageIDName = ?
    """,
    [msglog.msgID]
    );
  }



  //Method: delOlderMsgLogs.
  //Parameters: DateTime object to serve as cutoff point for messages.
  //Returns: Nothing.
  //Example Usage: "clientdb1.delOlderMsgLogs(DateTime(11,3,2025));" would delete any message logs older than March 11, 2025 00:00:00, so everything from march
  //  11 back would be deleted.
  //Description: Remove all message logs in the database older than the given date (inclusive). Date should be provided as a dart DateTime object using the
  //  local time zone.
  Future<void> delOlderMsgLogs(DateTime date) async{
    final db = await database;
    //Fetch all conversations and use their convoIDs in message retrieval.
    List<Conversation> convos = await getAllConvos(); 
    //For each conversation's table, delete any messages with dates older than the specified one.
    for(int i = 0; i < convos.length; i++){
      print(convos[i].convoMembers);
      await db.rawQuery(
      """
      DELETE FROM "${convos[i].convoID}" 
      WHERE $_msglogsReceivedTimeName >= ?
      """,
      [date.toString()]
      );
    }
  }
}