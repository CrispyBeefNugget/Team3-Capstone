import 'dart:convert';

import 'package:dmaft/client_db.dart';
import 'package:flutter/material.dart';
import 'package:dmaft/splash_screen.dart';
import 'package:dmaft/network.dart';
import 'dart:io';
import 'package:dmaft/test_keys.dart';


//UNCOMMENT THIS TO WEAKEN SECURITY AND ALLOW FOR SELF-SIGNED TLS CERTIFICATES
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}


void main() {
  HttpOverrides.global = MyHttpOverrides(); //UNCOMMENT THIS TO WEAKEN SECURITY AND ALLOW FOR SELF-SIGNED TLS CERTIFICATES
  runApp(const DMAFT());
}

class DMAFT extends StatelessWidget {
  const DMAFT({super.key});

  // This widget is the root of the DMAFT app.
  @override
  Widget build(BuildContext context) {
    
    final net = Network();
    final id1 = testID1();
    final pair1 = testKeypair1();
    net.setUserKeypair(pair1.privateKey);
    net.setUserID(id1);
    net.setServerURL('wss://10.0.2.2:8765');
    net.clientSock.stream.listen((data) {
      // Replace with a call to my handler function.
      print(data);
    });
    print("Finished setting up the listener for the UI!");
    
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class Handler {


//   incomingMessageMsgFormat = {
//     'Command':'INCOMINGMESSAGE',
//     'ServerTimestamp': time.time(), 
//     'OriginalReceiptTimestamp':'', #timestamp of when the server received this message
//     'SenderId':'', #server-issued ID for the sender.
//     'ConversationId':'',
//     'MessageType':'',
//     'MessageData':'',
// }

  


  void handleMessage(Map data) {

    final ClientDB database_service = ClientDB.instance;

    switch (data['Command']) {
      case 'NEWCONVERSATIONCREATED':
        const requiredKeys = ['Members','ConversationId'];
        for (final rkey in requiredKeys) {
          if (!data.containsKey(rkey)) {
            print("Required key " + rkey + " is missing!");
            return;
          }
        }

        Conversation convo = Conversation(convoID: data['ConversationId'], convoMembers: data['Members'], lastModified: DateTime.now().toString());   
        database_service.addConvo(convo);

      case 'INCOMINGMESSAGE':
        const requiredKeys = ['OriginalReceiptTimestamp', 'MessageId', 'SenderId', 'ConversationId', 'MessageType', 'MessageData'];
        for (final rkey in requiredKeys) {
          if (!data.containsKey(rkey)) {
            print("Required key " + rkey + " is missing!");
            return;
          }
        }

        var message_content = data['MessageData'];
        if (data['MessageType'] == 'Text') {
          message_content = utf8.encode(message_content);
        }
        MsgLog msglog = MsgLog(convoID: data['ConversationId'], msgID: data['MessageId'], msgType: data['MessageType'], senderID: data['SenderId'], rcvTime: data['OriginalReceiptTimestamp'].toString(), message: message_content);
        
        break;
      default:
    }
  }
  
}