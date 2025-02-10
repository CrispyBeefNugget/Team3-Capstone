import 'dart:core';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

RegExp ipRegex = RegExp(r'^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}$');

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

void main1() async {
    //First create an HTTP request. We'll upgrade it later to a WebSocket.
    //Obviously in production code we'll get HTTPS working first.
    Random r = new Random();
    String key = base64.encode(List<int>.generate(8, (_) => r.nextInt(256)));

    HttpClient hclient = HttpClient();
    HttpClientRequest request = await hclient.get('127.0.0.1', 5555, "");
    request.headers.add('Connection', 'upgrade');
    request.headers.add('Upgrade', 'websocket');
    request.headers.add('sec-websocket-version', '13');
    request.headers.add('sec-websocket-key', key);

    HttpClientResponse response = await request.close();
    //Check status code, key, etc.
    //Get the underlying socket from the intial HTTP connection so we can use it for a WebSocket.
    Socket socket = await response.detachSocket();

    WebSocket ws = WebSocket.fromUpgradedSocket(socket, serverSide: false);
}

void main2() async {
    //Create a websocket connection.
}