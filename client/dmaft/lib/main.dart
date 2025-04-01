import 'dart:io';
import 'dart:convert';
import 'package:dmaft/client_file_access.dart';
import 'package:flutter/material.dart';

import 'package:dmaft/client_db.dart';
import 'package:dmaft/splash_screen.dart';
import 'package:dmaft/network.dart';
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

void setIdAndKeyPair() async {

  final FileAccess fileHelper = FileAccess.instance;

  // Old
  final pair1 = testKeypair1();
  final id1 = testID1();

  final privateKey = pair1.privateKey;
  final p = privateKey.p.toString();
  final q = privateKey.q.toString();
  final n = privateKey.n.toString();
  final d = privateKey.privateExponent.toString();
  final e = privateKey.publicExponent.toString();

  // Attempt to new
  await fileHelper.setUUID(id1);
  await fileHelper.setRSAKeys(p, q, n, d, e);

}

void startNetwork() async {

  final FileAccess fileHelper = FileAccess.instance;

  final net = Network();

  final id1 = await fileHelper.getUUID();
  final rsalist = await fileHelper.getRSAKeys();
  print(rsalist);
  print('--------------------------');


  net.setUserKeypair(pair1.privateKey);
  net.setUserID(id1);
  net.setServerURL('wss://10.0.2.2:8765');
  net.clientSock.stream.listen((data) {
    // Replace with a call to my handler function.
    print(data);
  });
  print("Finished setting up the listener for the UI!");

}

class DMAFT extends StatelessWidget {
  const DMAFT({super.key});

  // This widget is the root of the DMAFT app.
  @override
  Widget build(BuildContext context) {
    
    startNetwork();
    
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


// Handles the sending and receiving of messages over the network and updates the client DB accordingly.
class Handler {

  void handleMessage(Map data) {

    final ClientDB databaseService = ClientDB.instance;

    switch (data['Command']) {
      case 'NEWCONVERSATIONCREATED':
        const requiredKeys = ['Members','ConversationId'];
        for (final rkey in requiredKeys) {
          if (!data.containsKey(rkey)) {
            print("Required key $rkey is missing!");
            return;
          }
        }

        Conversation convo = Conversation(convoID: data['ConversationId'], convoMembers: data['Members'], lastModified: DateTime.now().toString());   
        databaseService.addConvo(convo);

      case 'INCOMINGMESSAGE':
        const requiredKeys = ['OriginalReceiptTimestamp', 'MessageId', 'SenderId', 'ConversationId', 'MessageType', 'MessageData'];
        for (final rkey in requiredKeys) {
          if (!data.containsKey(rkey)) {
            print("Required key $rkey is missing!");
            return;
          }
        }

        var messageContent = data['MessageData'];
        if (data['MessageType'] == 'Text') {
          messageContent = utf8.encode(messageContent);
        }
        MsgLog msglog = MsgLog(convoID: data['ConversationId'], msgID: data['MessageId'], msgType: data['MessageType'], senderID: data['SenderId'], rcvTime: data['OriginalReceiptTimestamp'].toString(), message: messageContent);
        databaseService.addMsgLog(msglog);
        
        break;
      default:
    }
  }
  
}