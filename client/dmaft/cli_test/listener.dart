import 'dart:core';
import 'dart:io';
import 'dart:convert';

void main() async {
  print("Trying to connect to server (persistent socket)...");
  var mySock = await Socket.connect('127.0.0.1', 5555);
  print("Established connection!");
  
  var listener = mySock.listen((data) {
      var msg = Utf8Decoder().convert(data);
      print("Received message: " + msg);
    });

  await listener.asFuture(); //This never stops listening, probably until the socket closes
}