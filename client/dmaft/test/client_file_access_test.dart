import 'package:dmaft/client_file_access.dart';
import 'package:flutter/material.dart';

void main () async{
  WidgetsFlutterBinding.ensureInitialized();
  

  final settingsHelper = FileAccess.instance;

  Map<String, dynamic> settings = await settingsHelper.getSettings();
  print(settings);
  settings["test2"] = "pumpkins";
  print(settings);
  await settingsHelper.writeSettings(settings);
  print("---");
  settings = await settingsHelper.getSettings();
  print(settings);

  //final pic = await settingsHelper.getDefaultPic();
}