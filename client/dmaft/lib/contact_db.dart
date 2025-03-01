import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

/*
Note: Database files for Android apps are stored in the "/data/data/{package}/databases" folder in device storage. Access this in Android Studio 
by opening the emulated device in device explorer and navigating to "/data/data/{packagename}/databases/contact_db". This folder is 
accessible only by someone with root access and the app that made the database.
*/

//Class to store contacts retrieved from and sent to the database.
class Contact {
  final String id;
  String name;
  String status;
  String bio;
  Uint8List pic;

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

//Class for Contact Database operations. 
class ContactDB{
  static Database? _db; //Database
  static final ContactDB instance = ContactDB._constructor(); //Only one instance of ContactDB may exist at once.
  ContactDB._constructor();
  //Store table and column names for easier code revision
  final String _contactsTableName = "contactTable";
  final String _contactsIDName = "userID";
  final String _contactsNameName = "userName";
  final String _contactsStatusName = "userStatus";
  final String _contactsBioName = "userBio";
  final String _contactsPictureName = "userProfilePic";
  //If a db is already open, return it. Otherwise, open the db.
  Future<Database> get database async{
    if(_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }



  //Method: getDatabase.
  //Opens the contact database and returns the Database object. Automatically called during ContactDB instance construction.
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
          $_contactsIDName TEXT PRIMARY KEY, 
          $_contactsNameName TEXT NOT NULL, 
          $_contactsStatusName TEXT NOT NULL,
          $_contactsBioName TEXT NOT NULL,
          $_contactsPictureName BLOB NOT NULL
        )
        """);
      }
    );
    return database;
  }



  //Method: addContact.
  //Adds a new Contact object to the database. Will throw an exception if the primary key value (userID) already exists in the database.
  //Parameters: Contact object to be added.
  //Returns: Nothing.
  void addContact(Contact contact) async{
    final db = await database;
    //Ensure name string is not empty.
    if(contact.name.isEmpty){
      throw FormatException("Contact name can not be empty.");
    }
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
  //Fetches some or all data from the contacts database and returns them as a list of Contact objects. Can be given a string search phrase which will
  //  be applied to the id, name, and bio fields of each contact. Contacts containing the search string in any of these fields will be returned.
  //  Example: A search string of "45" would select a contact with an id of "123456" and a contact with a bio containing "I am 45 years old."
  //Parameters: Optional search pattern string format.
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
      print("search: $searchPattern");
      data = await db.rawQuery("""
      SELECT 
      * 
      FROM $_contactsTableName 
      WHERE
      $_contactsIDName LIKE ? OR
      $_contactsNameName LIKE ? OR
      $_contactsStatusName LIKE ? OR
      $_contactsBioName LIKE ?
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


  //Method: delContact.
  //Remove a contact entry from the database. Will do nothing if the given contact isn't in the database.
  //Parameters: Contact object corresponding to the database entry to be deleted.
  //Returns: Nothing.
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



  //Method: modifyContact.
  //Modify a contact entry in the database. Assumes that the userID was not changed. Does nothing if no entry exists with the given userID.
  //Parameters: Updated contact object.
  //Returns: Nothing.
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
}
