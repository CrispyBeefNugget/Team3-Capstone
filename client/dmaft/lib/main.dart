import 'package:flutter/material.dart';
import 'package:dmaft/splash_screen.dart';
import 'package:dmaft/network.dart';


/*
UNCOMMENT THIS TO WEAKEN SECURITY AND ALLOW FOR SELF-SIGNED TLS CERTIFICATES
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
*/

void main() {
  //HttpOverrides.global = MyHttpOverrides(); //UNCOMMENT THIS TO WEAKEN SECURITY AND ALLOW FOR SELF-SIGNED TLS CERTIFICATES
  runApp(const DMAFT());
}

class DMAFT extends StatelessWidget {
  const DMAFT({super.key});

  // This widget is the root of the DMAFT app.
  @override
  Widget build(BuildContext context) {
    //testConnectionNoTLS(); //Uncomment this to send a PING command to insecureServer.py.
    //testConnectionTLS(); //Uncomment this to send a PING command to tlsServer.py. Requires a valid certificate and private key.
    //testAuth();          //Uncomment this to send a full test authentication handshake to the TLS server. Non-TLS doesn't support this.
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