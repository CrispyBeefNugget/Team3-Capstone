/*
A basic server that can broadcast itself, receive a message and send one back.
Will expand this later to start accepting commands such as PING.
*/

import 'dart:io';
import 'dart:typed_data';

void main() async {
  final ip = InternetAddress.anyIPv4;
  final server = await ServerSocket.bind('127.0.0.1', 5555);
  print("Server is listening at ${ip.address} on port 5555");

  server.listen((Socket clientSock) {
    print("Server: Connected to ${clientSock.remoteAddress.address}:${clientSock.remotePort}");
    handleConnection(clientSock);
    clientSock.close();
  });
  return;
}

void handleConnection(Socket clientSock) {
  clientSock.listen((Uint8List data) {
    final clientMsg = String.fromCharCodes(data);
    print("Client: " + clientMsg);
    clientSock.write("Server: Received your message!");
  },
  onError: (error) {
    print("ERROR: " + error);
    clientSock.close();
  },
  onDone: () {
    print("WARNING: Client left");
    clientSock.close();
  });
}

