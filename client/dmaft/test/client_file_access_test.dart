import 'package:dmaft/client_file_access.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

void main () async{
  WidgetsFlutterBinding.ensureInitialized();
  

  final filehelper = FileAccess.instance;
Map<String, dynamic> settings = await filehelper.getSettings();
  print(settings);
  /*  
  Map<String, dynamic> settings = await settingsHelper.getSettings();
  print(settings);
  settings["test2"] = "pumpkins";
  print(settings);
  await settingsHelper.writeSettings(settings);
  print("---");
  settings = await settingsHelper.getSettings();
  print(settings);

  //final pic = await settingsHelper.getDefaultPic();
  */

  /*

  print("UUID:");
  //await filehelper.setUUID("testUUID1");
  //await filehelper.delUUID();
  print(await filehelper.getUUID());
  
  print("RSAKeys:");
  await filehelper.setRSAKeys("testkeyp", "testkeyq", "testkeyn", "testkeyd", "testkeye");
  //await filehelper.delRSAKeys();
  print(await filehelper.getRSAKeys());

  print("TokenID:");
  //await filehelper.setTokenID("testTokenID1");
  //await filehelper.delTokenID();
  print(await filehelper.getTokenID());

  print("TokenSecret:");
  //await filehelper.setTokenSecret(utf8.encode("testTokenSecret1"));
  //await filehelper.delTokenSecret();
  print(await filehelper.getTokenSecret());
  print(utf8.decode(await filehelper.getTokenSecret()));
  */
}