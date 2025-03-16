import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:convert';



//------------------------------------------------------------------------------------------------------------------------------------------------------------
//File access helper class
//------------------------------------------------------------------------------------------------------------------------------------------------------------



class FileAccess {
  //Fetches the local path for the settings.json file. If one doesn't exist, it creates one with the appropriate default settings.
  Future<File> _getSettingsFile() async{
    final settingsPath = await getApplicationSupportDirectory(); //This directory exists for all path_provider platforms and is used for persistent data.
    if(!await File('$settingsPath/settings.json').exists()){ //If no settings file exists.
      //Create a settings file.
      final settingsFile = File('$settingsPath/settings.json');
      //Insert default settings in JSON format.
      settingsFile.writeAsString("""
        {
        "




        }
      """);
    }

    return File('$settingsPath/settings.json'); //Return the settings file.
  }



  //Returns, using the settings file, a map of all settings and their current stored values.
  Future<Map<String, String>> getSettings() async{
    final settingsFile = await _getSettingsFile();
    
    //Fetch the contents of settings.json.
    final settings = json.encode(await settingsFile.readAsString()) as Map<String, String>;
    return settings;

  }




  Future<File> writeSettings(Map<String, String> settingsMap) async{
    final settingsFile = await _getSettingsFile();
    
    return settingsFile.writeAsString(jsonEncode(settingsMap));
  }



}