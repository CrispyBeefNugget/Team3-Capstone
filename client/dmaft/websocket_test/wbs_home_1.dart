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
    final id1 = testID1();
    final pair1 = testKeypair1();
    net.setUserKeypair(pair1.privateKey);
    net.setUserID(id1);
    net.setServerURL('wss://10.0.2.2:8765');
    net.clientSock.stream.listen((data) {
      print("UI received message!");
      print(data);
    });
    print("Finished setting up the listener for the UI!");
    net.sendTextMessage('0D50D38E-C2B9-41F3-B28B-7A59A7264718', 'Hello there!');
    
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