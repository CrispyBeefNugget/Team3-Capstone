import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';


/*
Note: Database files for Android apps are stored in the "/data/data/{package}/databases" folder in device storage. Access this in Android Studio 
by opening the emulated device in device explorer and navigating to "/data/data/{package name}/databases/contact_db". This folder is 
accessible only by someone with root access and the app that made the database.
*/

//Class to store chat logs retrieved from and sent to the database.
class ChatLog {
  final int convoID; //The ID for the chat conversation in which the message was sent.
  final int msgID; //The unique ID for the message.
  final int senderID; //UserID for the message's sender.
  final DateTime sentTime; //Time the sender sent the message.
  final DateTime rcvTime; //Time the recipient received the message.
  //Maybe add most recent update time too?
  int msgLength; //Length in bytes of the message contents sent.
  Uint8List message; //Message, file, etc. sent to the recipient.

  ChatLog({
    required this.convoID,
    required this.msgID,
    required this.senderID,
    required this.sentTime,
    required this.rcvTime,
    required this.msgLength,
    required this.message,
  });

  //Test function used to view chat log attributes more easily.
  List<dynamic> getChatLogAttr(){
    return [convoID, msgID, senderID, sentTime, rcvTime, msgLength, message];
  }
}

//Class for ChatLog Database operations.
class ChatLogDB{
  static Database? _db; //Database
  static final ChatLogDB instance = ChatLogDB._constructor(); //Only one instance of ChatLogDB may exist at once.
  //Store column names for easier code revision
  final String _chatlogsMessageIDName = "msgID";
  final String _chatlogsSenderIDName = "senderID";
  final String _chatlogsSentTimeName = "sendTime";
  final String _chatlogsReceivedTimeName = "receivedTime";
  final String _chatlogsMsgLengthName = "msgLength";
  final String _chatlogsMessageName = "message";

  ChatLogDB._constructor();

  //If a db is already open, return it. Otherwise, open the db.
  Future<Database> get database async{
    if(_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }

  //Opens the chat log database and returns the database object. Automatically called during ChatLogDB instance construction.
  //Parameters: None.
  //Returns: Sqflite Database object.
  Future<Database> getDatabase() async{
    //Get database path.
    final dbDirPath = await getDatabasesPath();
    final dbPath = join(dbDirPath, 'chatlog_db');
    //Open database. Creates one if it doesn't exist.
    final database = await openDatabase(
      dbPath,
      version: 1,
    );
    //Note that no tables are created on database creation.
    return database;
  }

  //Adds a new chat log to the database. Creates a table for the conversation if needed.
  //Parameters: ChatLog object to be added. Note that no fields can be null.
  //Returns: Nothing.
  void addChatLog(ChatLog chatlog) async{
    final db = await database;
    //Check if a table already exists for the conversation.
    dynamic tables = await db.rawQuery("""
      SELECT count(*) FROM sqlite_master WHERE type = "table" AND name = ?
    """, [chatlog.convoID]);
    //Table does not exist, so create one.
    if(tables == 0){
      await db.rawQuery("""
      CREATE TABLE "${chatlog.convoID}" (
          $_chatlogsMessageIDName INTEGER PRIMARY KEY,
          $_chatlogsSenderIDName INTEGER NOT NULL, 
          $_chatlogsSentTimeName TEXT NOT NULL,
          $_chatlogsReceivedTimeName TEXT NOT NULL,
          $_chatlogsMsgLengthName INTEGER NOT NULL, 
          $_chatlogsMessageName BLOB NOT NULL
      )"""
      );
    }
    //Add chat log to the table.
    try {
      await db.rawQuery("""
        INSERT INTO "${chatlog.convoID}"
        VALUES(
          ?, 
          ?, 
          ?, 
          ?, 
          ?, 
          ?
        )
        """, [chatlog.msgID, chatlog.senderID, chatlog.sentTime, chatlog.rcvTime, chatlog.msgLength, chatlog.message]
      );
    } on DatabaseException{
      int msgid = chatlog.msgID;
      print("Failed to insert entry. MessageID $msgid is already in database!"); //Can change to return something more helpful.
    }
  }
    /*

  //Returns a list of contact entries from the database. 
  //Parameters: Optional search pattern in RegEx format.
  //Returns: Nothing.
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
      $_contactsIDName LIKE %?% OR
      $_contactsNameName LIKE %?% OR
      $_contactsBioName LIKE %?%
      """,
      [searchPattern]
      );
    }
    //Transform database data into a list of Contact objects
    List<Contact> contacts = data
      .map(
        (e) => Contact( //Map database data into Contact class fields.
          id: e[_contactsIDName] as int, 
          name: e[_contactsNameName] as String,
          bio: e[_contactsBioName] as String,  
          pic: e[_contactsPictureName] as Uint8List,
        )
      ).toList().cast<Contact>(); //Cast dynamic type data to Contact type.
    return contacts;
  }

  //Remove a contact entry from the database.
  //Parameters: Contact to be deleted (Contact).
  //Returns: None.
  void delContact(Contact contact) async{
    final db = await database;
    final userID = contact.id;
    await db.rawQuery("""
    DELETE FROM 
    $_contactsTableName 
    WHERE $_contactsIDName = ?
    """,
    [userID]
    );
  }

  //Modify a contact entry in the database. Assumes that the userID was not changed.
  //Parameters: Updated contact (Contact).
  //Returns: None.
  Future<bool> modifyContact(Contact contact) async{
    final db = await database;
    await db.rawQuery("""
      UPDATE 
      $_contactsTableName 
      SET 
      $_contactsNameName = ?, 
      $_contactsBioName = ?
      
      WHERE 
      $_contactsIDName = ?
      """,
      [contact.name, contact.bio, contact.id]
    );

    return true;
  }

  //Attempt to close the open database. Not required, but best practice.
  //Parameters: None.
  //Returns: Boolean indicating success.
  Future<bool> closeDatabase() async {
    final Database db = await database;
    db.close();
    return true;
  }*/
}
