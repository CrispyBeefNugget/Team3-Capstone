import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:convert';



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
    //fillDatabase();
    return database;
  }

  Future<void> fillDatabase() async{
    Contact user1 = Contact(id: "550516DA-9F37-483F-AB87-A0DAA19203D9", name: "TestUser1", pronouns: "He/Him", bio: "I'm the first test user for Peregrine!", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
    //Contact user1 = Contact(id: "A052F0CB-235B-4A6A-BAF5-A1E4903FDD75", name: "TestUser2", pronouns: "He/Him", bio: "I'm the second test user for Peregrine!", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
    await modifyUser(user1);

    Contact cont1 = Contact(id: "72537670-1371-11F0-Bf31-B13C5532B1CE", name: "Frank Richardson", pronouns: "He/Him", bio: "testbio1", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
    Contact cont2 = Contact(id: "A09BD016-9985-4355-B75D-E26F1975130F", name: "David Alfonzo", pronouns: "He/Him", bio: "testbio2", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970"); 
    Contact cont3 = Contact(id: "67C6D4B3-7BD8-45F5-A8C8-12504C5FB65B", name: "Craig Collins", pronouns: "He/Him", bio: "testbio3", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
    Contact cont4 = Contact(id: "2DD759F9-D6BA-4D3A-A421-1494E006DB96", name: "Michelle Holly", pronouns: "They/Them", bio: "testbio4", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
    Contact cont5 = Contact(id: "5813F613-5A73-4226-B089-662833020006", name: "Dustin Smith", pronouns: "He/Him", bio: "testbio5", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
    Contact cont6 = Contact(id: "8E83BE55-C3D2-4827-B4DC-86D34BB22376", name: "Janelle Collins", pronouns: "She/Her", bio: "testbio6", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
    Contact cont7 = Contact(id: "F2D0CF5D-DF23-408A-97A3-DBD672E75D74", name: "Richard Hoffman", pronouns: "They/Them", bio: "testbio7", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
    Contact cont8 = Contact(id: "54E13B9A-D59C-48AD-A1AA-EA3DE082F027", name: "Amanda Dillon", pronouns: "She/Her", bio: "testbio8", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
    Contact cont9 = Contact(id: "16E372AE-6DF5-425F-BBA9-D62338F7D44D", name: "Carly Sylvester", pronouns: "She/Her", bio: "testbio9", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
    Contact cont10 = Contact(id: "AC0BC022-6CA9-4503-8E02-9E30BAD522E2", name: "William Masters", pronouns: "He/Him", bio: "testbio10", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
    Contact cont11 = Contact(id: "A052F0CB-235B-4A6A-BAF5-A1E4903FDD75", name: "TestUser2", pronouns: "He/Him", bio: "I'm the second test user for Peregrine!", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
    //Contact cont11 = Contact(id: "550516DA-9F37-483F-AB87-A0DAA19203D9", name: "TestUser1", pronouns: "He/Him", bio: "I'm the first test user for Peregrine!", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
    await addContact(cont1);
    await addContact(cont2);
    await addContact(cont3);
    await addContact(cont4);
    await addContact(cont5);
    await addContact(cont6);
    await addContact(cont7);
    await addContact(cont8);
    await addContact(cont9);
    await addContact(cont10);
    await addContact(cont11);

    Conversation conv1 = Conversation(convoID: "2EF90485-DEE0-406D-9573-6219CCBEA82A", convoMembers: ["550516DA-9F37-483F-AB87-A0DAA19203D9", "67C6D4B3-7BD8-45F5-A8C8-12504C5FB65B"], lastModified: "2025-03-14 22:27:29.761970");
    Conversation conv2 = Conversation(convoID: "B5BE731D-2A89-4427-9645-DD1B256B9163", convoMembers: ["550516DA-9F37-483F-AB87-A0DAA19203D9", "F2D0CF5D-DF23-408A-97A3-DBD672E75D74"], lastModified: "2025-03-14 22:27:29.761970");
    Conversation conv3 = Conversation(convoID: "F5ED7DA2-40AD-417A-B0E4-F06BCB2F622F", convoMembers: ["550516DA-9F37-483F-AB87-A0DAA19203D9", "AC0BC022-6CA9-4503-8E02-9E30BAD522E2"], lastModified: "2025-03-14 22:27:29.761970");
    Conversation conv4 = Conversation(convoID: "0D50D38E-C2B9-41F3-B28B-7A59A7264718", convoMembers: ["550516DA-9F37-483F-AB87-A0DAA19203D9", "A052F0CB-235B-4A6A-BAF5-A1E4903FDD75"], lastModified: "2025-03-14 22:27:29.761970");
    //Conversation conv1 = Conversation(convoID: "2EF90485-DEE0-406D-9573-6219CCBEA82A", convoMembers: ["A052F0CB-235B-4A6A-BAF5-A1E4903FDD75", "67C6D4B3-7BD8-45F5-A8C8-12504C5FB65B"], lastModified: "2025-03-14 22:27:29.761970");
    //Conversation conv2 = Conversation(convoID: "B5BE731D-2A89-4427-9645-DD1B256B9163", convoMembers: ["A052F0CB-235B-4A6A-BAF5-A1E4903FDD75", "F2D0CF5D-DF23-408A-97A3-DBD672E75D74"], lastModified: "2025-03-14 22:27:29.761970");
    //Conversation conv3 = Conversation(convoID: "F5ED7DA2-40AD-417A-B0E4-F06BCB2F622F", convoMembers: ["A052F0CB-235B-4A6A-BAF5-A1E4903FDD75", "AC0BC022-6CA9-4503-8E02-9E30BAD522E2"], lastModified: "2025-03-14 22:27:29.761970");
    //Conversation conv4 = Conversation(convoID: "0D50D38E-C2B9-41F3-B28B-7A59A7264718", convoMembers: ["A052F0CB-235B-4A6A-BAF5-A1E4903FDD75", "550516DA-9F37-483F-AB87-A0DAA19203D9"], lastModified: "2025-03-14 22:27:29.761970");
    await addConvo(conv1);
    await addConvo(conv2);
    await addConvo(conv3);
    await addConvo(conv4);

    MsgLog msg1 = MsgLog(convoID: "2EF90485-DEE0-406D-9573-6219CCBEA82A", msgID: "B4BD90BD-2510-43D7-8173-3054086793F2", msgType: "Text", senderID: "67C6D4B3-7BD8-45F5-A8C8-12504C5FB65B", rcvTime: "2025-03-10 22:27:29.761970", message: utf8.encode("Meeting today at 4:15pm."));
    MsgLog msg2 = MsgLog(convoID: "B5BE731D-2A89-4427-9645-DD1B256B9163", msgID: "3F47C2B3-8EED-43CF-BD51-76AA794F4B70", msgType: "Text", senderID: "550516DA-9F37-483F-AB87-A0DAA19203D9", rcvTime: "2025-03-11 22:27:29.761970", message: utf8.encode("Are you still available for the function on Wednesday?"));
    MsgLog msg3 = MsgLog(convoID: "2EF90485-DEE0-406D-9573-6219CCBEA82A", msgID: "E07AFE9E-8EAC-4C55-ACD0-A6BADCF66C25", msgType: "Text", senderID: "550516DA-9F37-483F-AB87-A0DAA19203D9", rcvTime: "2025-03-12 22:27:29.761970", message: utf8.encode("Ok. Thanks for the heads up!"));
    MsgLog msg4 = MsgLog(convoID: "F5ED7DA2-40AD-417A-B0E4-F06BCB2F622F", msgID: "3ED213DF-7CBE-4655-B7B3-262CB047B738", msgType: "Text", senderID: "F2D0CF5D-DF23-408A-97A3-DBD672E75D74", rcvTime: "2025-03-13 22:27:29.761970", message: utf8.encode("Could you let Adam know I'm not going to make it in time?"));
    MsgLog msg5 = MsgLog(convoID: "B5BE731D-2A89-4427-9645-DD1B256B9163", msgID: "3534579A-17FF-4032-86A8-821D4119BE70", msgType: "Text", senderID: "AC0BC022-6CA9-4503-8E02-9E30BAD522E2", rcvTime: "2025-03-14 22:27:29.761970", message: utf8.encode("Still waiting to get my time off request approved."));
    //MsgLog msg1 = MsgLog(convoID: "2EF90485-DEE0-406D-9573-6219CCBEA82A", msgID: "B4BD90BD-2510-43D7-8173-3054086793F2", msgType: "Text", senderID: "67C6D4B3-7BD8-45F5-A8C8-12504C5FB65B", rcvTime: "2025-03-10 22:27:29.761970", message: utf8.encode("Meeting today at 4:15pm."));
    //MsgLog msg2 = MsgLog(convoID: "B5BE731D-2A89-4427-9645-DD1B256B9163", msgID: "3F47C2B3-8EED-43CF-BD51-76AA794F4B70", msgType: "Text", senderID: "A052F0CB-235B-4A6A-BAF5-A1E4903FDD75", rcvTime: "2025-03-11 22:27:29.761970", message: utf8.encode("Are you still available for the function on Wednesday?"));
    //MsgLog msg3 = MsgLog(convoID: "2EF90485-DEE0-406D-9573-6219CCBEA82A", msgID: "E07AFE9E-8EAC-4C55-ACD0-A6BADCF66C25", msgType: "Text", senderID: "A052F0CB-235B-4A6A-BAF5-A1E4903FDD75", rcvTime: "2025-03-12 22:27:29.761970", message: utf8.encode("Ok. Thanks for the heads up!"));
    //MsgLog msg4 = MsgLog(convoID: "F5ED7DA2-40AD-417A-B0E4-F06BCB2F622F", msgID: "3ED213DF-7CBE-4655-B7B3-262CB047B738", msgType: "Text", senderID: "F2D0CF5D-DF23-408A-97A3-DBD672E75D74", rcvTime: "2025-03-13 22:27:29.761970", message: utf8.encode("Could you let Adam know I'm not going to make it in time?"));
    //MsgLog msg5 = MsgLog(convoID: "B5BE731D-2A89-4427-9645-DD1B256B9163", msgID: "3534579A-17FF-4032-86A8-821D4119BE70", msgType: "Text", senderID: "AC0BC022-6CA9-4503-8E02-9E30BAD522E2", rcvTime: "2025-03-14 22:27:29.761970", message: utf8.encode("Still waiting to get my time off request approved."));
    await addMsgLog(msg1);
    await addMsgLog(msg2);
    await addMsgLog(msg3);
    await addMsgLog(msg4);
    await addMsgLog(msg5);
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
    List<Contact> user = data
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
    return user[0];
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
      $_contactsPictureName = ?,
      $_contactsLastModifiedName = ?
      """,
      [user.id, user.name, user.pronouns, user.bio, user.pic, user.lastModified]
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
  //Example Usage: "await clientdb1.modifyContact(<a_Contact_object>);".
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
      $_contactsPictureName = ?,
      $_contactsLastModifiedName = ?
      
      WHERE 
      $_contactsIDName = ?
      """,
      [contact.name, contact.pronouns, contact.bio, contact.pic, contact.lastModified, contact.id]
    );
  }



  //Method: delContact.
  //Parameters: Contact object corresponding to the database entry to be deleted.
  //Returns: Nothing.
  //Example Usage: "await clientdb1.delContact(<a_Contact_object>);".
  //Description: Remove a contact entry from the database using the given Contact object's userID. Also deletes any conversations that included this contact! 
  //  Will do nothing if the given contact isn't in the database.
  Future<void> delContact(Contact contact) async{
    final db = await database;
    //Find any conversations including the contact you're deleting
    List<Conversation> allConvos = await getAllConvos();
    for(int i = 0; i < allConvos.length; i++){
      if(allConvos[i].convoMembers.contains(contact.id)){
        //Delete the conversation
        await delConvo(allConvos[i]);
      }
    }
    //Remove the contact entry
    await db.rawQuery("""
    DELETE FROM 
    $_contactsTableName 
    WHERE $_contactsIDName = ?
    """,
    [contact.id]
    );
  }



  //Method: userIDNameMap.
  //Parameters: List of contacts whose IDs and names you want in a map.
  //Returns: A Map of userIDs to userNames for the given contacts.
  //Example Usage: "ClientDB.userIDNameMap(<a_list_of_Contact_objects>);".
  //Description: To avoid asynchronous calls in the middle of UI operations, this method can be called early on and the resulting Map can be used to access
  //  usernames when needed. Pass a list of contacts, and this method will return a Map with the userIDs as the keys and the userNames as the values. 
  //  NOT AN ASYNC METHOD.
  static Map<String, String> userIDNameMap(List<Contact> contacts){
    //For each given userID, find the user's name.
    Map<String, String> idAndName = {};
    for(int i = 0; i < contacts.length; i++){
      idAndName[contacts[i].id] = contacts[i].name;
    }
    return idAndName;
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
    //Transform database data into a Conversation object.
    List<Conversation> convo = data
      .map(
        (e) => Conversation( //Map database data into Conversation class fields. Splits convo members around commas to reform a list.
          convoID: targetConvoID,
          convoMembers: e[_convoMembersName].split(",") as List<String>, 
          lastModified: e[_convoLastModifiedName],
        )
      ).toList().cast<Conversation>(); //Cast dynamic type data to Conversation type.
    return convo[0];
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



  //Method: getConvoMembers.
  //Parameters: ConvoID of the conversation you would like the members from.
  //Returns: A list of Contact objects for all conversation members EXCEPT for the client user.
  //Example Usage: "clientdb1.getConvoMembers(<a_ConvoID>);".
  //Description: When given a ConvoID, fetches the conversation using the convoID, then uses the convoMembers field of the Conversation to retrieve Contact 
  //  userIDs. The method then fetches and returns Contact objects using these userIDs and stores them in a list. Because the client user's information is not
  //  stored in the Contacts table, it will not be retrieved despite the user's own userID being in convoMembers.
  Future<List<Contact>> getConvoMembers(String targetconvoid) async{
    //Fetch the Conversation object using the given convoID.
    Conversation convo = await getConvo(targetconvoid);
    //Build a query based on the convoMembers.
    String query = "SELECT * FROM $_contactsTableName WHERE";
    bool firstFlag = true;
    for(int i = 0; i < convo.convoMembers.length; i++){
      //On all passes except the first, add an OR
      if(!firstFlag){
        query = "$query OR";
      }
      firstFlag = false;
      //Add a search for the convoMember's id.
      query = "$query $_contactsIDName = '${convo.convoMembers[i]}'";
    }
    //Fetch the Contacts using the constructed query.
    final db = await database;
    dynamic data;
    data = await db.rawQuery(query);
    //Cast fetched data into a Contact object.
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
    //Return the list of Contacts.
    return contacts;
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
      ORDER BY $_msglogsReceivedTimeName
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
    msglogs.sort((a, b) => a.rcvTime.compareTo(b.rcvTime));
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
  //Parameters: The number of days the user wants their messages saved for.
  //Returns: Nothing.
  //Example Usage: "await clientdb1.delOlderMsgLogs(10);" would delete any message logs older than 10 days.
  //Description: Remove all message logs in the database older than the given number of days from the current date.
  Future<void> delOlderMsgLogs(int numDays) async{
    //Calculate the cutoff date for messages.
    DateTime cutOffDate = DateTime.now().toUtc().subtract(Duration(days: numDays));
    print("Deleting all messages older than ${cutOffDate.toString()}");
    //Fetch all conversations.
    final db = await database;
    List<Conversation> convos = await getAllConvos(); 
    //For each conversation's table, delete any messages with dates older than the specified one.
    for(int i = 0; i < convos.length; i++){
      await db.rawQuery(
      """
      DELETE FROM "${convos[i].convoID}" 
      WHERE $_msglogsReceivedTimeName < ?
      """,
      [cutOffDate.toString()]
      );
    }
  }



  //Method: generateMsgID.
  //Parameters: The convoID of the conversation the message will be a part of.
  //Returns: An unused UUID msgID string to be used in a MsgLog.
  //Example Usage: "String newMsgID = await clientdb1.generateMsgID(<a_conversation_id>);".
  //Description: Generates a UUID string and ensures the ID does not already exist within the given conversation.
  Future<String> generateMsgID(String convoID) async{
    //Fetch all message logs for the given conversation.
    List<MsgLog> messages = await getMsgLogs(convoID);
    //Create a UUID.
    var uuidGen = Uuid();
    String newID = "";
    bool suitableID = false;
    //Until a suitable ID is generated, repeat this.
    while(suitableID == false){
      //Generate an ID.
      newID = uuidGen.v1();
      //Check if the ID exists in the conversation already.
      suitableID = true;
      for(int i = 0; i < messages.length; i++){
        //If any message is found to have this ID, immediately stop and restart the while loop to make a new one to try.
        if(newID == messages[i].msgID){
          suitableID = false;
          newID = "";
          break;
        }
      }
    }
    return newID;
  }
}