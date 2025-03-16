import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:convert';



//------------------------------------------------------------------------------------------------------------------------------------------------------------
//FileAccess exception classes
//------------------------------------------------------------------------------------------------------------------------------------------------------------



//My be thrown by getDefaultPic if the default profile picture file cannot be found in the directory.
class PicNotFoundException implements Exception{
  final String cause;
  PicNotFoundException(this.cause);
}



//------------------------------------------------------------------------------------------------------------------------------------------------------------
//File access helper class
//------------------------------------------------------------------------------------------------------------------------------------------------------------



class FileAccess {
  //Singleton pattern to ensure only one instance of FileAccess may exist at once.
  static final FileAccess instance = FileAccess._constructor();
  FileAccess._constructor();  
  


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
      throw PicNotFoundException("Default profile picture could not be located in $picPath");
    }
  }
}