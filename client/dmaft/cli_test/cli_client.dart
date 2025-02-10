import 'dart:collection';
import 'dart:core';
import 'dart:io';
import 'dart:convert';

var receivedMessages = Queue();

void main() async {
  print("Trying to connect to server (persistent socket)...");
  var mySock = await Socket.connect('127.0.0.1', 5555);
  print("Established connection!");
  
  var listener = mySock.listen((data) {
      var msg = Utf8Decoder().convert(data);
      receivedMessages.addLast(msg);
    });

  while (true) {
    sendMessage(mySock);
    print("Messages received: ");
    while (receivedMessages.isNotEmpty) {
      print(receivedMessages.elementAt(0));
      receivedMessages.removeFirst();
    }
    print('\n');
  }
}

void sendMessage(Socket socket) {
  print("Type a message to send to the server.");
  String? msg = stdin.readLineSync();
  socket.write(msg);
  return;
}