import 'package:flutter/material.dart';
import 'package:dmaft/splash_screen.dart';
import 'network.dart';
import 'dart:io';
import 'package:dmaft/test_keys.dart';


//UNCOMMENT THIS TO WEAKEN SECURITY AND ALLOW FOR SELF-SIGNED TLS CERTIFICATES
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}


void main() {
  HttpOverrides.global = MyHttpOverrides(); //UNCOMMENT THIS TO WEAKEN SECURITY AND ALLOW FOR SELF-SIGNED TLS CERTIFICATES
  runApp(const DMAFT());
}

class DMAFT extends StatelessWidget {
  const DMAFT({super.key});

  // This widget is the root of the DMAFT app.
  @override
  Widget build(BuildContext context) {
    
    final net = Network();
    final id2 = testID2();
    final pair2 = testKeypair2();
    net.setUserKeypair(pair2.privateKey);
    net.setUserID(id2);
    net.setServerURL('wss://10.0.2.2:8765');
    net.clientSock.stream.listen((data) {
      print("UI received message!");
      print(data);
    });
    print("Finished setting up the listener for the UI!");
    net.connectAndAuth();
    
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class Handler {



  
}