import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';

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

void testConnection() async {
  final wsUrl = Uri.parse('wss://10.0.2.2:8765');
  print("Constructed wsUrl.");
  final channel = WebSocketChannel.connect(wsUrl);
  print("Created the channel.");
  final pingJson = constructPingRequest();
  print("JSON is ready for sending.");

  await channel.ready;
  print("Channel is ready!");
  channel.sink.add(pingJson);

  channel.stream.listen((message) {
    print(message);
    channel.sink.close(status.normalClosure); //Can't use anything other than this; method only accepts error code 1000 (this) or range 3000-4999.
  });
}

void testJson() {
  var json = constructPingRequest();
  print(json);
}

//Use default serverAddress with TLS 'wss://10.0.2.2:8765' if running the Python server on your computer and this in an Android simulator.
WebSocketChannel getServerWebSocket(String serverAddress) {
  final wsUrl = Uri.parse(serverAddress);
  final channel = WebSocketChannel.connect(wsUrl);
  return channel;
}

String constructPingRequest() {
  final currentTime = DateTime.timestamp();
  final pingRequest = {
    'Command':'PING',
    'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt() //Server only accepts second-level accuracy and Dart doesn't provide that natively
  };
  const encoder = JsonEncoder();
  return encoder.convert(pingRequest);
}

String constructConnectRequest(Uint8List publicKeyBytes) {
  final currentTime = DateTime.timestamp();
  const b64 = Base64Encoder();
  final connectRequest = {
    'Command':'CONNECT',
    'UserPublicKey': b64.convert(publicKeyBytes),
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
    'Command':'CONNECT',
    'ChallengeId':challengeId,
    'Signature': b64.convert(signatureBytes),
    'HashAlgorithm':'SHA256',
    'ClientTimestamp': (currentTime.millisecondsSinceEpoch / 1000).toInt() //Server only accepts second-level accuracy and Dart doesn't provide that natively
  };
  const encoder = JsonEncoder();
  return encoder.convert(connectRequest);
}