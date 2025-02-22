import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

/*
Note: Database files for Android apps are stored in the "/data/data/{package}/databases" folder in device storage. Access this in Android Studio 
by opening the emulated device in device explorer and navigating to "/data/data/com.example.client_db/databases/contact_db". This folder is 
accessible only by someone with root access and the app that made the database.
*/

//Class to store contacts retrieved from the database.
class Contact {
  final int id;
  String name;
  String bio;
  Uint8List pic;

  Contact({
    required this.id,
    required this.name,
    required this.bio,
    required this.pic,
  });

  //Test function used to view contact attributes more easily.
  List<dynamic> getContactAttr(){
    return [id, name, bio, pic];
  }
}

//Class for Contact Database operations.
class ContactDB{
  static Database? _db; //Database
  static final ContactDB instance = ContactDB._constructor(); //Only one instance of ContactDB may exist at once.
  //Store table and column names for easier code revision
  final String _contactsTableName = "contactTable";
  final String _contactsIDName = "userID";
  final String _contactsNameName = "userName";
  final String _contactsBioName = "userBio";
  final String _contactsPictureName = "userProfilePic";

  ContactDB._constructor();

  //If a db is already open, return it. Otherwise, open the db.
  Future<Database> get database async{
    if(_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }

  //Opens the contact database and returns the database object. Automatically called during ContactDB instance construction.
  //Parameters: None.
  //Returns: Sqflite Database object.
  Future<Database> getDatabase() async{
    //Get database path.
    final dbDirPath = await getDatabasesPath();
    final dbPath = join(dbDirPath, 'contact_db');
    //Open database. Create one if it doesn't exist.
    final database = await openDatabase(
      dbPath,
      version: 1,
      //When a new database is created, create the contacts table.
      onCreate: (db, version) { 
        db.execute("""
        CREATE TABLE $_contactsTableName (
          $_contactsIDName INTEGER PRIMARY KEY, 
          $_contactsNameName TEXT NOT NULL, 
          $_contactsBioName TEXT NOT NULL,
          $_contactsPictureName BLOB NOT NULL
        )
        """);
      }
    );
    return database;
  }

  //Adds a new contact to the database.
  //Parameters: Contact object to be added. Note that all fields can't be null.
  //Returns: Nothing.
  void addContact(Contact contact) async{
    final db = await database;
    //Insert data. Returned value not needed.
    try {
      await db.insert(
      _contactsTableName, 
      {
        _contactsIDName: contact.id,
        _contactsNameName: contact.name,
        _contactsBioName: contact.bio,
        _contactsPictureName: contact.pic,
      }
    );
    } on DatabaseException {
      int uid = contact.id;
      print("Failed to insert entry. UserID $uid is already in database!"); //Can change to return something more helpful.
    }
  }

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
      SELECT * FROM $_contactsTableName WHERE
      $_contactsIDName LIKE '%$searchPattern%' OR
      $_contactsNameName LIKE '%$searchPattern%' OR
      $_contactsBioName LIKE '%$searchPattern%'
      """);
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
    DELETE FROM $_contactsTableName WHERE $_contactsIDName = $userID
    """);
  }

  //Modify a contact entry in the database. Assumes that the userID was not changed.
  //Parameters: Updated contact (Contact).
  //Returns: None.
  void modifyContact(Contact contact) async{
    final db = await database;
    await db.rawQuery("""
    UPDATE 
    $_contactsTableName 
    SET 
    $_contactsNameName = '${contact.name}', 
    $_contactsBioName = '${contact.bio}', 
    $_contactsPictureName = ${contact.pic}
    WHERE 
    $_contactsIDName = ${contact.id}
    """);
  }

  //Attempt to close the open database. Not required, but best practice.
  //Parameters: None.
  //Returns: Boolean indicating success.
  Future<bool> closeDatabase() async {
    final Database db = await database;
    db.close();
    return true;
  }
}