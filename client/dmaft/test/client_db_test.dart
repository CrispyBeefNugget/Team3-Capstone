import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:dmaft/client_db.dart';

void main () async{
  WidgetsFlutterBinding.ensureInitialized();
  
  final ClientDB databaseservice = ClientDB.instance; //Access ClientDB database.
  
  var convos = await databaseservice.getAllConvos();
  for(int i = 0; i < 3; i++){
    print(convos[i].convoID);
    print(convos[i].lastModified);
    print("------");
  }

  //Conversation conv1 = Conversation(convoID: "1", convoMembers: ["5", "10"]);
  //Conversation conv2 = Conversation(convoID: "2", convoMembers: ["6", "3"]);
  //Conversation conv3 = Conversation(convoID: "3", convoMembers: ["1", "10"]);

  //Conversation conv3 = Conversation(convoID: "3", convoMembers: ["2", "10"]);
  //databaseservice.modifyConvo(conv3);

  //DateTime date = DateTime(2025,03,11);
  //databaseservice.delOlderMsgLogs(date);
/*
  var convos = await databaseservice.getAllConvos();
  for(int i = 0; i < 3; i++){
    print(convos[i].convoID);
    print(convos[i].convoMembers);
  }
*/
 // databaseservice.modifyConvo(conv2);
  //databaseservice.modifyConvo(conv3);
}