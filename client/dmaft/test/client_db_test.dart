import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:dmaft/client_db.dart';
import 'dart:convert';

void main () async{
  WidgetsFlutterBinding.ensureInitialized();
  
  final ClientDB databaseservice = ClientDB.instance; //Access ClientDB database.

  Conversation conv1 = Conversation(convoID: "7", convoMembers: utf8.encode("a, b"));
  databaseservice.delConvo(conv1);
/* 

  MsgLog log2 = MsgLog(convoID: "2", msgID: "2", msgType: "text", senderID: "3", rcvTime: DateTime.now().toString(), message: utf8.encode("My boss approved my vaction time request."));
  MsgLog log3 = MsgLog(convoID: "1", msgID: "3", msgType: "text", senderID: "5", rcvTime: DateTime.now().toString(), message: utf8.encode("Gotcha. Thanks for the heads-up."));
  MsgLog log4 = MsgLog(convoID: "3", msgID: "4", msgType: "text", senderID: "1", rcvTime: DateTime.now().toString(), message: utf8.encode("You still free after work?"));
  MsgLog log5 = MsgLog(convoID: "2", msgID: "5", msgType: "text", senderID: "6", rcvTime: DateTime.now().toString(), message: utf8.encode("I'm still waiting to hear from mine."));

  databaseservice.addMsgLog(log1);
  databaseservice.addMsgLog(log2);
  databaseservice.addMsgLog(log3);
  databaseservice.addMsgLog(log4);
  databaseservice.addMsgLog(log5);
*/
}