/*
A basic test client that can connect to a server and send a text message.
Will modify later on to send better data.
*/

import 'dart:io';
import 'dart:typed_data';

RegExp ipRegex = RegExp(r'^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}$');

void main() async {
  String? serverIP;
  int? serverPort;
  
  do {
    print("Enter the server IP:");
    String? ip = stdin.readLineSync();
    print("Enter the server port:");
    String? port = stdin.readLineSync();

    if (ip == null || ip.isEmpty) {
      print("Please enter the server's IP address to connect to.");
      print("");
      continue;
    }

    if (port == null || port.isEmpty) {
      print("Please enter the server's port to connect to.");
      print("");
      continue;
    }

    RegExpMatch? match = ipRegex.firstMatch(ip);
    if (match == null) {
      print("Please enter a valid IPv4 address in the form: XXX.XXX.XXX.XXX");
      print("");
      continue;
    }

    try {
      serverPort = int.parse(port);
      serverIP = ip;
    }
    on Exception {
      serverPort = null;
      serverIP = null;
      continue;
    }

  }
  while ((serverPort == null) && (serverIP == null || serverIP.isEmpty));

  print("Connecting...");
  final serverSocket = await Socket.connect(serverIP!, serverPort!);
  print("Client: Connected to ${serverSocket.remoteAddress.address}:${serverSocket.remotePort}");

  //Set up a listening function
  serverSocket.listen((Uint8List data) {
    final serverResponse = String.fromCharCodes(data);
    print('$serverResponse');
  },
  onError: (error) {
    print("Client: $error");
    serverSocket.destroy();
  },
  onDone: () {
    print("Client: Server disconnected!");
    serverSocket.destroy();
  });

  //Now send some data
  String? message;
  do {
    print("Please type a message: ");
    message = stdin.readLineSync();
  } while (message == null || message.isEmpty);

  serverSocket.write(message);
}