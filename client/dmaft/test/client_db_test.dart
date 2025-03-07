import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dmaft/contact_db.dart';
import 'package:dmaft/chatlog_db.dart';

void main () async{
  WidgetsFlutterBinding.ensureInitialized();
  
  //Contactdb testing
  /*
  final ContactDB databaseservice = ContactDB.instance; //Access Contacts Database class.
  Contact user1 = Contact(id: "142445", name: "test101name", status: "teststatus", bio: "testbio", pic: Uint8List(8));
  Contact user2 = Contact(id: "242445", name: "test102name", status: "teststatus2", bio: "testbio2", pic: Uint8List(8));
  Contact user3 = Contact(id: "35", name: "t", status: "teststatus3", bio: "testbio2", pic: Uint8List(8));
  Contact user4 = Contact(id: "351", name: "t", status: "teststatus4", bio: "testbio2", pic: Uint8List(8));
  databaseservice.addContact(user1);
  //databaseservice.addContact(user2);
  //databaseservice.addContact(user3);
  List<Contact> contactlist = await databaseservice.getContacts();
  for(var i = 0; i < contactlist.length; i++){
    print(contactlist[i].getContactAttr());
  }

  databaseservice.delContact(user4);

  user2.bio = "New bio2!";
  databaseservice.modifyContact(user4);
  print("modified");
  
  contactlist = await databaseservice.getContacts();
  for(var i = 0; i < contactlist.length; i++){
    print(contactlist[i].getContactAttr());
  }
  */

  //Chatlogdb testing
  

  final ChatLogDB databaseservice2 = ChatLogDB.instance; //Access chatlog Database class.
  ChatLog log1 = ChatLog(msgID: "192", convoID: "001", senderID: "100", rcvTime: DateTime.now().toString(), message: Uint8List(8));
  databaseservice2.addChatLog(log1);
  databaseservice2.delChatLog(log1);
  

}