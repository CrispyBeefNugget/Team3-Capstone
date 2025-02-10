import 'dart:collection';
import 'dart:core';
import 'dart:io';
import 'dart:convert';

var receivedMessages = Queue();

void main() async {
  final server = await ServerSocket.bind('127.0.0.1', 5555);
  print('Server listening on ${server.address}:${server.port}');
  
  //This seems to run perpetually. Look into ServerSocket.bind().
  await for (var socket in server) {
    var listener = socket.listen((data) {
      var msg = Utf8Decoder().convert(data);
      receivedMessages.addLast(msg);
    });

    while (true) {
    sendMessage(socket);
    print("Messages received: ");
    while (receivedMessages.isNotEmpty) {
      print(receivedMessages.elementAt(0));
      receivedMessages.removeFirst();
    }
    print('\n');
  }
  }
  print("I escaped!"); //This never executes
  return;
}

void sendMessage(Socket socket) {
  print("Type a reply to send to the client.");
  String? msg = stdin.readLineSync();
  socket.write(msg);
  return;
}