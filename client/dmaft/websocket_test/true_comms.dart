import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';
import 'asym_crypto.dart';

//I'm currently testing with self-signed certs to avoid the overhead
//of setting up a proper hosted server and Let's Encrypt.
//To connect to a self-signed cert server, the main.dart file must be modified to include:
/*
import 'dart.io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}
*/

//ONLY INCLUDE THE ABOVE IN TEST SCENARIOS. NEVER USE IN PRODUCTION!

late final RSAPublicKey publicKey;
late final RSAPrivateKey privateKey;
final invalidMailbox = Queue();
final validMailbox = Queue();

void initRandomUserKeys() {
  final pair = generateRSAkeyPair(exampleSecureRandom());
  try {
    publicKey = pair.publicKey;
    privateKey = pair.privateKey;
    print("Successfully set a random user keypair.");
  }
  catch(e) {
    print("User keypair has already been set and cannot be changed.");
  }
}

void testAuth() async {
  initRandomUserKeys();
  final serverChannel = await connectToServer('wss://10.0.2.2:8765');
  final connectRequest = constructConnectRequest(publicKey);
  serverChannel.sink.add(connectRequest);
  //Watch the rest play out from here! :D
}

Future<WebSocketChannel> connectToServer(String wsAddress) async {
  final wsUrl = Uri.parse(wsAddress);
    print("Constructed wsUrl.");
  final channel = WebSocketChannel.connect(wsUrl);
  print("Created the channel.");

  await channel.ready;

  //Set up listener function; redirect to the proper handler
  channel.stream.listen((message) {
    handleServerMessage(message, channel);
  });
  print("Constructed listener function. Channel is ready!");
  return channel;
}

void handleServerMessage(message, WebSocketChannel serverChannel) {
  print("Received message!");
  print(message);

  //Decode and verify the message
  var parsedMsg = jsonDecode(message);
  if (parsedMsg is! Map) {
    //This is likely junk data. The real server only sends JSON messages.
    invalidMailbox.addLast(parsedMsg);
    return;
  }

  if (! parsedMsg.containsKey('Command')) {
    //Also likely junk data. The server always sends a command.
    print("Response is missing the Command key.");
    invalidMailbox.addLast(parsedMsg);
    return;
  }

  switch (parsedMsg['Command'].toString().toUpperCase()) {
    case 'PING':
      print("Server sent a PING response.");
      validMailbox.addLast(parsedMsg);

    case 'CONNECT':
      print("Server sent a CONNECT response.");
      //Try to sign the challenge and send it back.
      //First, make sure it's valid.
      if (! isValidAuthChallenge(parsedMsg)) {
        print("Dart thinks that the message isn't valid, but the isValidAuthChallenge function completed.");
        invalidMailbox.addLast(parsedMsg);
        return;
      }
      print("We have a valid response!");
      //Sign the challenge and send back the result.
      final b64d = Base64Decoder();
      final challengeId = parsedMsg['ChallengeId'];
      final challengeData = b64d.convert(parsedMsg['ChallengeData']);
      final sigBytes = rsaSignSHA256(privateKey, challengeData).bytes;
      final authRequest = constructAuthRequest(challengeId, sigBytes);
      print("Sending an authentication request.");
      serverChannel.sink.add(authRequest);

    case 'AUTHENTICATE':
      print("Received AUTHENTICATE response: " + parsedMsg['Successful'].toString());
      validMailbox.addLast(parsedMsg);
      serverChannel.sink.close(status.normalClosure); //Temporary so that the socket doesn't live forever during testing

    default:
      invalidMailbox.add(parsedMsg);
  }
}


bool isValidAuthChallenge(Map responseData) {
  //Ensure all required keys are present
  const requiredKeys = ['Command','ChallengeId','ChallengeData','Successful'];
  for (final rkey in requiredKeys) {
    if (!responseData.containsKey(rkey)) {
      print("Required key " + rkey + " is missing!");
      return false;
    }
  }

  //Ensure all required keys have the right values and types
  if (responseData['Command'].toString().toUpperCase() != 'CONNECT') return false;
  if (responseData['ChallengeId'] is! String) return false;
  if (responseData['ChallengeData'] is! String) return false;

  //Ensure no blank values
  if (responseData['ChallengeId'] == '') return false;
  if (responseData['ChallengeData'] == '') return false;

  return true;
}

RSASignature rsaSignSHA256(RSAPrivateKey privateKey, Uint8List data) {
  final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
  signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  return signer.generateSignature(data);
}

String constructConnectRequest(RSAPublicKey userPublicKey) {
  final currentTime = DateTime.timestamp();
  
  final connectRequest = {
    'Command':'CONNECT',
    'UserPublicKeyMod': userPublicKey.modulus.toString(),
    'UserPublicKeyExp': userPublicKey.publicExponent.toString(),
    'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt() //Server only accepts second-level accuracy and Dart doesn't provide that natively
  };
  const encoder = JsonEncoder();
  return encoder.convert(connectRequest);
}

//Improve on this later to ensure the challengeId is in the right format. Should be a UUID given by the server.
String constructAuthRequest(String challengeId, Uint8List signatureBytes) {
  final currentTime = DateTime.timestamp();
  const b64 = Base64Encoder();
  final connectRequest = {
    'Command':'AUTHENTICATE',
    'ChallengeId':challengeId,
    'Signature': b64.convert(signatureBytes),
    'HashAlgorithm':'SHA256',
    'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt() //Server only accepts second-level accuracy and Dart doesn't provide that natively
  };
  const encoder = JsonEncoder();
  return encoder.convert(connectRequest);
}
