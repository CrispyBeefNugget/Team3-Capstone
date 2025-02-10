import 'dart:core';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

void main() async {
  final ip = InternetAddress.anyIPv4;
  final server = await ServerSocket.bind('127.0.0.1', 5555);
  print("Server is listening at 127.0.0.1 on port 5555");

  HttpServer hserver = HttpServer.listenOn(server);
  await for (var socket in hserver) { //Do this for every connection that's received

  }
}