import 'dart:io';
import 'dart:convert';
import 'package:dmaft/client_file_access.dart';
import 'package:flutter/material.dart';

import 'package:dmaft/client_db.dart';
import 'package:dmaft/splash_screen.dart';
import 'package:dmaft/network.dart';
import 'package:dmaft/test_keys.dart';
import 'package:pointycastle/export.dart';

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
  final pair2 = testKeypair2();
  final id2 = testID2();

  final privateKey = pair2.privateKey;
  final p = privateKey.p.toString();
  final q = privateKey.q.toString();
  final n = privateKey.n.toString();
  final d = privateKey.privateExponent.toString();
  final e = privateKey.publicExponent.toString();

  // Attempt to new
  await fileHelper.setUUID(id2);
  await fileHelper.setRSAKeys(p, q, n, d, e);
}

void startNetwork() async {

  final FileAccess fileHelper = FileAccess.instance;
  final net = Network();

  try {
    final id = await fileHelper.getUUID();
    final rsalist = await fileHelper.getRSAKeys();
    RSAPrivateKey privateKey = RSAPrivateKey(
      BigInt.parse(rsalist['n']!),
      BigInt.parse(rsalist['d']!),
      BigInt.parse(rsalist['p']!),
      BigInt.parse(rsalist['q']!)
      );
    print(rsalist);
    print('--------------------------');

    net.setUserKeypair(privateKey);
    net.setUserID(id);
  }
  catch(e) {
    print("WARNING: Failed to retrieve user ID and keypair. Will request a new identity from server.");
  }

  net.setServerURL('wss://10.0.2.2:8765');
  net.clientSock.stream.listen((data) {
    print("UI received network message: " + data.toString());
    Handler.handleMessage(data);
  });
  print("Finished setting up the listener for the UI!");
  net.connectAndAuth();
}

class DMAFT extends StatelessWidget {
  const DMAFT({super.key});

  // This widget is the root of the DMAFT app.
  @override
  Widget build(BuildContext context) {

    startNetwork();
    // setIdAndKeyPair(); // Run this on the second client.
    
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

  static void handleMessage(Map data) async {

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

        Conversation convo = Conversation(convoID: data['ConversationId'], convoMembers: data['Members'], lastModified: DateTime.now().toUtc().toString());
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
        MsgLog msglog = MsgLog(convoID: data['ConversationId'], msgID: data['MessageId'], msgType: data['MessageType'], senderID: data['SenderId'], rcvTime: DateTime.fromMillisecondsSinceEpoch(1000 * int.parse(data['OriginalReceiptTimestamp'].toString()), isUtc: true).toString(), message: messageContent);
        databaseService.addMsgLog(msglog);
        
        break;

      case 'NEWCREDENTIALS':
        const requiredKeys = ['UserId', 'p', 'q', 'n', 'd', 'e'];
        for (final rkey in requiredKeys) {
          if (!data.containsKey(rkey)) {
            print("NEWCREDENTIALS Message: Required key $rkey is missing!");
            return;
          }
        }
        final FileAccess fileHelper = FileAccess.instance;
        await fileHelper.setUUID(data['UserId']);
        await fileHelper.setRSAKeys(data['p'], data['q'], data['n'], data['d'], data['e']);
        print("UI saved credentials for new user " + data['UserId'] + "!");
      default:
    }
  }
  
}