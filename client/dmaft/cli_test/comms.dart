import 'dart:convert';
import 'dart:core';
import 'package:uuid/uuid.dart';

class Comms {
  static RegExp ipv4Regex = RegExp(r'^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}$');

  String serverIPv4 = '0.0.0.0';
  String? serverIPv6;
  int serverPort = 5555;

  String? clientID;
  String? userID;

  Comms();
  Comms.ipv4(this.serverIPv4, this.serverPort);

  String getServerIPv4() {
    return this.serverIPv4;
  }

  int getServerPort() {
    return this.serverPort;
  }

  void setServerIPv4(String ipv4) {
    if (ipv4.isEmpty) {
      throw ArgumentError('Comms.setServerIPv4(): Received null or empty IPv4 address. IPv4 format must be: xxx.xxx.xxx.xxx, where 0 <= xxx <= 255.');
    }
    RegExpMatch? match = ipv4Regex.firstMatch(ipv4);
    if (match == null) {
      throw ArgumentError('Comms.setServerIPv4(): Received invalid IPv4 address. IPv4 format must be: xxx.xxx.xxx.xxx, where 0 <= xxx <= 255.');
    }

    this.serverIPv4 = ipv4;
    return;
  }

  void setServerPort(int port) {
    if (port < 0 || port > 65535) {
      throw ArgumentError('Comms.setServerPort(): Received invalid server port number. Port number must be between 0 - 65535. (Ports greater than 1024 preferred.)');
    }
    this.serverPort = port;
    return;
  }

  bool pingServer() {
    Message msgObject = Message('PING');
    String msg = jsonEncode(msgObject);

    return false;
  }
}

class Message {
  String command = 'PING';

  Message(this.command);

  Message.fromJson(Map<String, dynamic> json)
    : this.command = json['command'] as String;

  Map<String, dynamic> toJson() => {
    'command': this.command
  };
}