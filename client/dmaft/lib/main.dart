import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
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

void setIdAndKeyPair1() async {

  final FileAccess fileHelper = FileAccess.instance;

  // Old
  final pair2 = testKeypair1();
  final id2 = testID1();

  final privateKey = pair2.privateKey;
  final p = privateKey.p.toString();
  final q = privateKey.q.toString();
  final n = privateKey.n.toString();
  final d = privateKey.privateExponent.toString();
  final e = privateKey.publicExponent.toString();

  // Attempt to new
  //await fileHelper.setUUID(id2);
  await fileHelper.setUUID("550516DA-9F37-483F-AB87-A0DAA19203D9");
  await fileHelper.setRSAKeys(p, q, n, d, e);
}

void setIdAndKeyPair2() async {

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
  //await fileHelper.setUUID(id2);
  await fileHelper.setUUID("58EA80BE-B7E2-4E9F-A37D-E175C27904EB");
  await fileHelper.setRSAKeys(p, q, n, d, e);
}

void startNetwork() async {

  final FileAccess fileHelper = FileAccess.instance;
  final dbHelper = ClientDB.instance;
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
  net.connectAndAuth().then((data) async {
    final profile = await dbHelper.getUser();
    net.updateProfileOnServer(profile.name, profile.pic, profile.pronouns, profile.bio);
  });
}

//Retrieves the settings file contents and, if automatic history management is enabled, deletes any message logs older than the set period.
void enforceMessageHistory() async{
  FileAccess fileService = FileAccess.instance;
  ClientDB dbService = ClientDB.instance;
  Map<String, dynamic> settings = await fileService.getSettings();
  //Enforce current history settings.
  if(settings["deleteHistory"] == true){
    await dbService.delOlderMsgLogs(settings["historyDuration"]);
  }
}

class DMAFT extends StatelessWidget {
  const DMAFT({super.key});

  // This widget is the root of the DMAFT app.
  @override
  Widget build(BuildContext context) {

    //Enforce current automatic message history management settings.
    enforceMessageHistory();

    startNetwork();
    //setIdAndKeyPair1(); // Run this on the first client.
    //setIdAndKeyPair2(); // Run this on the second client.
    
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

  static void handleMessage(var data) async {

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
        List<String> members = (data['Members'] as List).map((item) => item as String).toList();
        Conversation convo = Conversation(convoID: data['ConversationId'], convoMembers: members, lastModified: DateTime.now().toUtc().toString());
        databaseService.addConvo(convo);

        final net = Network();
        if (data['MemberData'] != null) {
          for (var item in data['MemberData']) {
            if (item['UserId'] == net.getUserID()) continue;
            else {
              Contact temp = Contact(
                id: item['UserId'],
                name: item['UserName'],
                pronouns: item['Status'],
                bio: item['Bio'],
                pic: base64Decode(item['ProfilePic']),
                lastModified: DateTime.now().toUtc().toString()
              );
              databaseService.addContact(temp);
              print("Successfully added user ${item['UserId']} as a contact!");
            }
          }
        }
        else {
          print("No member detail data was found in the new conversation request.");
        }

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
        final ClientDB clientDBHelper = ClientDB.instance;
        await fileHelper.setUUID(data['UserId']);
        await clientDBHelper.modifyUser(Contact(id: data['UserId'], name: "", pronouns: "", bio: "", pic: Uint8List(8), lastModified: DateTime.now().toUtc().toString())); //Adds the newly-assigned UUID to the userID database field.
        await fileHelper.setRSAKeys(data['p'], data['q'], data['n'], data['d'], data['e']);
        print("UI saved credentials for new user " + data['UserId'] + "!");
      default:
    }
  }
  
}