import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dmaft/client_db.dart';
import 'dart:convert';


void main () async{
  WidgetsFlutterBinding.ensureInitialized();
  
final ClientDB databaseservice = ClientDB.instance; //Access ClientDB database.

print(await databaseservice.generateMsgID("2"));
print(await databaseservice.generateMsgID("2"));
print(await databaseservice.generateMsgID("2"));
print(await databaseservice.generateMsgID("2"));
print(await databaseservice.generateMsgID("2"));
print(await databaseservice.generateMsgID("2"));
print(await databaseservice.generateMsgID("2"));
print(await databaseservice.generateMsgID("2"));
print(await databaseservice.generateMsgID("2"));
print(await databaseservice.generateMsgID("2"));

/*
var contacts = await databaseservice.getConvoMembers("1");
contacts.add(await databaseservice.getUser());
Map<String, String> map = ClientDB.userIDNameMap(contacts);


//Contact user1 = Contact(id: "550516DA-9F37-483F-AB87-A0DAA19203D9", name: "TestUser1", pronouns: "He/Him", bio: "The first test user.", pic: Uint8List(8), lastModified: DateTime.now().toString());
//Contact user2 = Contact(id: "A052F0CB-235B-4A6A-BAF5-A1E4903FDD75", name: "TestUser2", pronouns: "He/Him", bio: "The second test user.", pic: Uint8List(8), lastModified: DateTime.now().toString());
//await databaseservice.addContact(user1);
//await databaseservice.modifyUser(user2);
//Conversation convo1 = Conversation(convoID: "0D50D38E-C2B9-41F3-B28B-7A59A7264718", convoMembers: ["550516DA-9F37-483F-AB87-A0DAA19203D9", "A052F0CB-235B-4A6A-BAF5-A1E4903FDD75"], lastModified: DateTime.now().toString());
//Conversation convo2 = Conversation(convoID: "0D50D38E-C2B9-41F3-B28B-7A59A7264718", convoMembers: ["A052F0CB-235B-4A6A-BAF5-A1E4903FDD75", "550516DA-9F37-483F-AB87-A0DAA19203D9"], lastModified: DateTime.now().toString());
//await databaseservice.addConvo(convo2);



Contact user1 = Contact(id: "0", name: "TestUser1", pronouns: "They/Them", bio: "testuserbio", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
await databaseservice.modifyUser(user1);

Contact cont1 = Contact(id: "1", name: "Frank Richardson", pronouns: "He/Him", bio: "testbio1", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
Contact cont2 = Contact(id: "2", name: "David Alfonzo", pronouns: "He/Him", bio: "testbio2", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970"); 
Contact cont3 = Contact(id: "3", name: "Craig Collins", pronouns: "He/Him", bio: "testbio3", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
Contact cont4 = Contact(id: "4", name: "Michelle Holly", pronouns: "They/Them", bio: "testbio4", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
Contact cont5 = Contact(id: "5", name: "Dustin Smith", pronouns: "He/Him", bio: "testbio5", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
Contact cont6 = Contact(id: "6", name: "Janelle Collins", pronouns: "She/Her", bio: "testbio6", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
Contact cont7 = Contact(id: "7", name: "Richard Hoffman", pronouns: "They/Them", bio: "testbio7", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
Contact cont8 = Contact(id: "8", name: "Amanda Dillon", pronouns: "She/Her", bio: "testbio8", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
Contact cont9 = Contact(id: "9", name: "Carly Sylvester", pronouns: "She/Her", bio: "testbio9", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
Contact cont10 = Contact(id: "10", name: "William Masters", pronouns: "He/Him", bio: "testbio10", pic: Uint8List(8), lastModified: "2025-03-14 22:27:29.761970");
await databaseservice.addContact(cont1);
await databaseservice.addContact(cont2);
await databaseservice.addContact(cont3);
await databaseservice.addContact(cont4);
await databaseservice.addContact(cont5);
await databaseservice.addContact(cont6);
await databaseservice.addContact(cont7);
await databaseservice.addContact(cont8);
await databaseservice.addContact(cont9);
await databaseservice.addContact(cont10);

Conversation conv1 = Conversation(convoID: "1", convoMembers: ["0", "3"], lastModified: "2025-03-14 22:27:29.761970");
Conversation conv2 = Conversation(convoID: "2", convoMembers: ["0", "7"], lastModified: "2025-03-14 22:27:29.761970");
Conversation conv3 = Conversation(convoID: "3", convoMembers: ["0", "10"], lastModified: "2025-03-14 22:27:29.761970");
await databaseservice.addConvo(conv1);
await databaseservice.addConvo(conv2);
await databaseservice.addConvo(conv3);

MsgLog msg1 = MsgLog(convoID: "1", msgID: "1", msgType: "Text", senderID: "3", rcvTime: "2025-03-10 22:27:29.761970", message: utf8.encode("Meeting today at 4:15pm."));
MsgLog msg2 = MsgLog(convoID: "2", msgID: "2", msgType: "Text", senderID: "0", rcvTime: "2025-03-11 22:27:29.761970", message: utf8.encode("Are you still available for the function on Wednesday?"));
MsgLog msg3 = MsgLog(convoID: "1", msgID: "3", msgType: "Text", senderID: "0", rcvTime: "2025-03-12 22:27:29.761970", message: utf8.encode("Ok. Thanks for the heads up!"));
MsgLog msg4 = MsgLog(convoID: "3", msgID: "4", msgType: "Text", senderID: "7", rcvTime: "2025-03-13 22:27:29.761970", message: utf8.encode("Could you let Adam know I'm not going to make it in time?"));
MsgLog msg5 = MsgLog(convoID: "2", msgID: "5", msgType: "Text", senderID: "10", rcvTime: "2025-03-14 22:27:29.761970", message: utf8.encode("Still waiting to get my time off request approved."));
await databaseservice.addMsgLog(msg1);
await databaseservice.addMsgLog(msg2);
await databaseservice.addMsgLog(msg3);
await databaseservice.addMsgLog(msg4);
await databaseservice.addMsgLog(msg5);
*/

  //Conversation conv1 = Conversation(convoID: "1", convoMembers: ["5", "10"]);
  //Conversation conv2 = Conversation(convoID: "2", convoMembers: ["6", "3"]);
  //Conversation conv3 = Conversation(convoID: "3", convoMembers: ["1", "10"]);

  //Conversation conv3 = Conversation(convoID: "3", convoMembers: ["2", "10"]);
  //databaseservice.modifyConvo(conv3);

  //DateTime date = DateTime(2025,03,11);
  //databaseservice.delOlderMsgLogs(date);

  //var convos = await databaseservice.getAllConvos();
  //for(int i = 0; i < 3; i++){
  //  print(convos[i].convoID);
  //  print(convos[i].convoMembers);
  //}

 // databaseservice.modifyConvo(conv2);
  //databaseservice.modifyConvo(conv3);



  


}