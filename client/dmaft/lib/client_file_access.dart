import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';



//------------------------------------------------------------------------------------------------------------------------------------------------------------
//FileAccess exception classes
//------------------------------------------------------------------------------------------------------------------------------------------------------------



//The specified data can not be found.
class NotFoundException implements Exception{
  final String cause;
  NotFoundException(this.cause);
}



//------------------------------------------------------------------------------------------------------------------------------------------------------------
//File access helper class
//------------------------------------------------------------------------------------------------------------------------------------------------------------



class FileAccess {
  //Singleton pattern to ensure only one instance of FileAccess may exist at once.
  static final FileAccess instance = FileAccess._constructor();
  FileAccess._constructor();  

//Example code for FileAccess instance creation: "final filehelper1 = FileAccess.instance;".
  


//------------------------------------------------------------------------------------------------------------------------------------------------------------
//Settings access
//------------------------------------------------------------------------------------------------------------------------------------------------------------
  


  //Fetches the local path for the settings.json file. If one doesn't exist, it creates one with the appropriate default settings.
  Future<File> _getSettingsFile() async{
    //Use path_provider to fetch a directory for settings storage.
    final settingsDir = await getApplicationSupportDirectory(); //This directory exists for all path_provider platforms and is used for persistent data.
    final settingsPath = settingsDir.path;
    //Check if a settings.json file already exists in the directory.
    if(!await File('$settingsPath/settings.json').exists()){
      //No settings.json file exists, so create a settings file.
      final settingsFile = await File('$settingsPath/settings.json').create();
      //Insert default settings in JSON format.
      settingsFile.writeAsString("""
        {
        "historyDuration": -1,
        "test1": "apples",
        "test2": "oranges"
        }
      """);
    }
    //Return the settings file object.
    return File('$settingsPath/settings.json'); 
  }



  //Method: getSettings.
  //Parameters: None.
  //Returns: A map of settings names and their current stored values.
  //Example Usage: "Map<String, dynamic> settings = await filehelper1.getSettings();".
  //Description: Accesses the app settings file and retrieves the JSON content, transferring it into a map of setting names and their values. Fetches all stored
  //  settings.
  Future<Map<String, dynamic>> getSettings() async{
    //Access the settings file.
    final settingsFile = await _getSettingsFile();
    //Fetch and return the settings information.
    final settings = json.decode(await settingsFile.readAsString());
    return settings;
  }



  //Method: writeSettings.
  //Parameters: Updated settings map.
  //Returns: Nothing.
  //Example Usage: "await filehelper1.writeSettings(<a_settings_map>);".
  //Description: Update the settings.json file using the contents of the given map. The map should be obtained using the getSettings() method, adjusted as 
  //  needed, then written back to the file using this method.
  Future<void> writeSettings(Map<String, dynamic> settingsMap) async{
    final settingsFile = await _getSettingsFile();
    settingsFile.writeAsString(jsonEncode(settingsMap));
  }



//------------------------------------------------------------------------------------------------------------------------------------------------------------
//Default profile picture access
//------------------------------------------------------------------------------------------------------------------------------------------------------------



  //Method: getDefaultPic.
  //Parameters: None.
  //Returns: A file containing the default DMAFT profile picture.
  //Example Usage: "File pic = await filehelper1.getDefaultPic();".
  //Description: Accesses the locally-stored default profile picture for users, returning it as a generic file.
  Future<File> getDefaultPic() async{
    //Use path_provider to fetch a directory for storage of the default profile picture.
    final picDir = await getApplicationSupportDirectory(); //This directory exists for all path_provider platforms and is used for persistent data.
    final picPath = picDir.path;
    try{
      return File('$picPath/defaultProfilePic.png').absolute;
    } catch(e){
      throw NotFoundException("Default profile picture could not be located in $picPath");
    }
  }



//------------------------------------------------------------------------------------------------------------------------------------------------------------
//Secure communication data storage
//------------------------------------------------------------------------------------------------------------------------------------------------------------



  //Specify an options object for use with flutter_secure_storage. Allows accessing stored data while the app is in the background.
  final options = IOSOptions(accessibility: KeychainAccessibility.first_unlock);
  //Specify names for the RSA keys in storage. Can be altered to allow for a different number of keys than 5.
  final List<String> keynames = ["RSAKey1", "RSAKey2", "RSAKey3", "RSAKey4", "RSAKey5"];



  //Method: setUUID.
  //Parameters: New UUID in String format to replace the currently stored UUID.
  //Returns: Nothing.
  //Example Usage: "await filehelper1.setUUID(<a_String>);".
  //Description: Overwrites the contents of the UUID field in flutter secure storage with the given String. Stored persistently.
  Future<void> setUUID(String newID) async{
    //Access flutter secure storage.
    final storage = FlutterSecureStorage();
    //Store the new UUID in flutter secure storage.
    await storage.write(key: "UUID", value: newID, iOptions: options);
  }



  //Method: getUUID.
  //Parameters: None.
  //Returns: The currently-stored UUID in String format.
  //Example Usage: "String uuid1 = await filehelper1.getUUID();".
  //Description: Fetches the UUID value currently stored in flutter secure storage and returns it as a String. Throws an exception if there is no UUID value
  //  in storage.
  Future<String> getUUID() async {
    //Access flutter secure storage.
    final storage = FlutterSecureStorage();
    //Read and return the UUID currently in flutter secure storage and throw an error if there is no value present.
    String ?uuid = await storage.read(key: "UUID");
    if(uuid == null){
      throw NotFoundException("No UUID exists in storage!");
    }
    return uuid;
  }



  //Method: delUUID.
  //Parameters: None.
  //Returns: Nothing.
  //Example Usage: "await filehelper1.delUUID();".
  //Description: Deletes the currently-stored UUID from flutter secure storage. Will throw an exception if there is no UUID in storage.
  Future<void> delUUID() async{
    //Access flutter secure storage.
    final storage = FlutterSecureStorage();
    //Delete the stored uuid.
    await storage.delete(key: "UUID", iOptions: options);
  }



  //Method: setRSAKeys.
  //Parameters: A list of Strings containing the RSA keys to be stored.
  //Returns: Nothing.
  //Example Usage: "await filehelper1.setRSAKeys(<a_list_of_Strings>);".
  //Description: Overwrites the contents of the RSAKeys field in flutter secure storage with the provided list of new keys. Stored persistently.
  Future<void> setRSAKeys(List<String> newkeys) async{
    //Access flutter secure storage.
    final storage = FlutterSecureStorage();
    //Store each of the RSA keys in flutter secure storage.
    for(int i = 0; i < newkeys.length; i++){
      await storage.write(key: keynames[i], value: newkeys[i], iOptions: options);
    }
  }



  //Method: getRSAKeys.
  //Parameters: None.
  //Returns: The currently-stored list of RSA Keys, each in String format.
  //Example Usage: "List<String> keys = await filehelper1.getRSAKeys();".
  //Description: Fetches each of the RSAKey Strings currently stored in flutter secure storage and returns them as a list of Strings. The list of keys is 
  //  ordered exactly as the list of keys given to setRSAKeys was. Throws an exception if there are no RSAKey values in storage or if there are fewer
  //  keys in storage than there are names in the "keynames" list at the start of the "Secure communication data storage" section.
  Future<Map<String, String>> getRSAKeys() async {
    //Access flutter secure storage.
    final storage = FlutterSecureStorage();
    //Read and return the RSA keys currently in flutter secure storage and throw an error if there is no value present.
    Map<String, String> keys ={};
    for(int i = 0; i < keynames.length; i++){
      String ?key = await storage.read(key: keynames[i]);
      if(key == null){
        throw NotFoundException("Not enough RSA keys in storage!");
      }
      keys[keynames[i]] = key; //Load RSA keys from storage into a map. Uses the keynames list for keys.
    }
    return keys;
  }



  //Method: delRSAKeys.
  //Parameters: None.
  //Returns: Nothing.
  //Example Usage: "await filehelper1.delRSAKeys();".
  //Description: Deletes all of the currently-stored RSA Keys from flutter secure storage. Will throw an exception if any aren't in storage.
  Future<void> delRSAKeys() async{
    //Access flutter secure storage.
    final storage = FlutterSecureStorage();
    //Delete each stored rsa key.
    for(int i = 0; i < keynames.length; i++){
      await storage.delete(key: keynames[i], iOptions: options);
    }
  }



  //Method: setTokenID.
  //Parameters: New TokenID in String format to replace the currently stored TokenID.
  //Returns: Nothing.
  //Example Usage: "await filehelper1.setTokenID(<a_String>);".
  //Description: Overwrites the contents of the TokenID field in flutter secure storage with the given String. Stored persistently.
  Future<void> setTokenID(String newID) async{
    //Access flutter secure storage.
    final storage = FlutterSecureStorage();
    //Store the new TokenID in flutter secure storage.
    await storage.write(key: "TokenID", value: newID, iOptions: options);
  }



  //Method: getTokenID.
  //Parameters: None.
  //Returns: The currently-stored TokenID in String format.
  //Example Usage: "String tokenid1 = await filehelper1.getTokenID();".
  //Description: Fetches the TokenID value currently stored in flutter secure storage and returns it as a String. Throws an exception if there is no TokenID 
  //  value in storage.
  Future<String> getTokenID() async {
    //Access flutter secure storage.
    final storage = FlutterSecureStorage();
    //Read and return the TokenID currently in flutter secure storage and throw an error if there is no value present.
    String ?tokenid = await storage.read(key: "TokenID");
    if(tokenid == null){
      throw NotFoundException("No TokenID exists in storage!");
    }
    return tokenid;
  }



  //Method: delTokenID.
  //Parameters: None.
  //Returns: Nothing.
  //Example Usage: "await filehelper1.delTokenID();".
  //Description: Deletes the currently-stored token ID from flutter secure storage. Will throw an exception if there is no TokenID in storage.
  Future<void> delTokenID() async{
    //Access flutter secure storage.
    final storage = FlutterSecureStorage();
    //Delete the stored tokenid.
    await storage.delete(key: "TokenID", iOptions: options);
  }



  //Method: setTokenSecret.
  //Parameters: New TokenSecret in Uint8List format to replace the currently stored TokenSecret.
  //Returns: Nothing.
  //Example Usage: "await filehelper1.setTokenSecret(<a_Uint8List_object>);".
  //Description: Overwrites the contents of the TokenSecret field in flutter secure storage with the given bytes. Stored persistently.
  Future<void> setTokenSecret(Uint8List newToken) async{
    //Access flutter secure storage.
    final storage = FlutterSecureStorage();
    //Store the new TokenSecret in flutter secure storage as a String.
    await storage.write(key: "TokenSecret", value: utf8.decode(newToken), iOptions: options);
  }



  //Method: getTokenSecret.
  //Parameters: None.
  //Returns: The currently-stored TokenSecret in Uint8List format.
  //Example Usage: "Uint8List tokensec1 = await filehelper1.getTokenSecret();".
  //Description: Fetches the TokenSecret value currently stored in flutter secure storage and returns it as a Uint8List object. Throws an exception if there is
  //  no TokenSecret value in storage.
  Future<Uint8List> getTokenSecret() async {
    //Access flutter secure storage.
    final storage = FlutterSecureStorage();
    //Read and return the TokenSecret currently in flutter secure storage and throw an error if there is no value present.
    String ?tokensec = await storage.read(key: "TokenSecret");
    if(tokensec == null){
      throw NotFoundException("No TokenID exists in storage!");
    }
    return utf8.encode(tokensec); //Converted from String to Uint8List and returned.
  }



  //Method: delTokenSecret.
  //Parameters: None.
  //Returns: Nothing.
  //Example Usage: "await filehelper1.delTokenSecret();".
  //Description: Deletes the currently-stored token secret from flutter secure storage. Will throw an exception if there is no TokenSecret in storage.
  Future<void> delTokenSecret() async{
    //Access flutter secure storage.
    final storage = FlutterSecureStorage();
    //Delete the stored tokensecret.
    await storage.delete(key: "TokenSecret", iOptions: options);
  }
}