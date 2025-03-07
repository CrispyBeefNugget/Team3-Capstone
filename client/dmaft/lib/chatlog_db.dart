import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';


/*
Note: Database files for Android apps are stored in the "/data/data/{package}/databases" folder in device storage. Access this in Android Studio 
by opening the emulated device in device explorer and navigating to "/data/data/{package name}/databases/ChatLog_DB.db". This folder is 
accessible only by someone with root access and the app that made the database.
*/

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

  //Test function used to view contact attributes more easily.
  List<dynamic> getContactAttr(){
    return [id, name, status, bio, pic];
  }
}


//Class to store conversations retrieved from and sent to the database.


//Class to store chat logs retrieved from and sent to the database.
class ChatLog {
  final String convoID; //The ID for the chat conversation in which the message was sent.
  final String msgID; //The unique ID for the message.
  final String senderID; //UserID for the message's sender.
  final String rcvTime; //Time the server received the message. May not align with the time the recipient's client gets the message if they were offline.
  Uint8List message; //Message, file, etc. sent to the recipient.

  ChatLog({
    required this.convoID,
    required this.msgID,
    required this.senderID,
    required this.rcvTime,
    required this.message,
  });

  //Test function used to view chat log attributes more easily.
  List<dynamic> getChatLogAttr(){
    return [convoID, msgID, senderID, rcvTime, message];
  }
}



//Class for ChatLog Database operations.
class ChatLogDB{
  static Database? _db; //Database
  static final ChatLogDB instance = ChatLogDB._constructor(); //Only one instance of ChatLogDB may exist at once.
  //Store column names for easier code revision
  final String _chatlogsMessageIDName = "msgID";
  final String _chatlogsSenderIDName = "senderID";
  final String _chatlogsReceivedTimeName = "receivedTime";
  final String _chatlogsMessageName = "message";

  ChatLogDB._constructor();

  //If a db is already open, return it. Otherwise, open the db.
  Future<Database> get database async{
    if(_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }



  //Method: getDatabase.
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
      //When a new database is created, create the ? table.
      onCreate: (db, version) { 
        db.execute("""
        CREATE TABLE "" (
          
        )
        """);
      }
    );
    
    return database;
  }



  //Method: addChatLog.
  //Adds a new chat log to the database. Creates a table for the conversation if needed.
  //Parameters: ChatLog object to be added. Note that no fields can be null.
  //Returns: Nothing.
  void addChatLog(ChatLog chatlog) async{
    final db = await database;
    //Check if a table already exists for the conversation. Query returns a list containing a map with "COUNT(*)" as the key and the count as the value.
    dynamic tables = await db.rawQuery("""
      SELECT COUNT(*) 
      FROM sqlite_master 
      WHERE type = 'table' 
      AND name = ?
    """, [chatlog.convoID]);
    //Table does not exist, so create one.
    if(tables[0]["COUNT(*)"] == 0){
      await db.rawQuery("""
      CREATE TABLE "${chatlog.convoID}" (
          $_chatlogsMessageIDName TEXT PRIMARY KEY,
          $_chatlogsSenderIDName TEXT NOT NULL, 
          $_chatlogsReceivedTimeName TEXT NOT NULL,
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
          ?
        )
        """, [chatlog.msgID, chatlog.senderID, chatlog.rcvTime, chatlog.message]
      );
    } on DatabaseException{
      String msgid = chatlog.msgID;
      print("Failed to insert entry. MessageID $msgid is already in database!"); //Can change to return something more helpful.
    }
  }

/*

  //Method: getAllChatLogs.
  //Returns a list of all chat log entries from the database. 
  //Parameters: Optional search pattern in RegEx format.
  //Returns: Nothing.
  Future<List<ChatLog>> getAllChatLogs([String searchPattern = ""]) async{
    final db = await database;
    final dynamic data;
    //No search pattern given, so fetch the entire table of contacts.
    if(searchPattern.isEmpty){
      data = await db.rawQuery("""
      SELECT $_chatlogsMessageIDName, $_ch
      FROM 
      


      """);
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
*/
  //Method: delChatLog.
  //Remove a chat log entry from the database using the msgID. Will do nothing if the given message isn't in the database.
  //Parameters: ChatLog object corresponding to the database entry to be deleted.
  //Returns: None.
  void delChatLog(ChatLog chatlog) async{
    final db = await database;
    await db.rawQuery("""
    DELETE FROM 
    ${chatlog.convoID} 
    WHERE $_chatlogsMessageIDName = ?
    """,
    [chatlog.msgID]
    );
  }

/*

  void delConvo(ChatLog chatlog) async{


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
