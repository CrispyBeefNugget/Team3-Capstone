import 'dart:core';
import 'comms.dart';

void main() {
  Comms comms = Comms.ipv4('127.0.0.1', 5555);
  comms.pingServer();
  return;
}

