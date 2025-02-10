import 'dart:core';
import 'dart:io';
import 'dart:convert';

void main() async {
  final server = await ServerSocket.bind('127.0.0.1', 5555);
  print('Server listening on ${server.address}:${server.port}');
  
  //This seems to run perpetually. Look into ServerSocket.bind().
  await for (var socket in server) {
    while (true) {
      socket.listen((data) async {
        final clientMsg = String.fromCharCodes(data);
        
      });
    }
  }
  print("I escaped!"); //This never executes
  return;
}

void sendMessage(Socket socket) {
  print("Type a message to send to the client.");
  String? msg = stdin.readLineSync();
  socket.write(msg);
}