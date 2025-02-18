import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dmaft/homescreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive); // Makes the splash screen fullscreen.

    // Redirects from the splashscreen to the homescreen after a period of time.
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(),
        )
      );
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode( // Leaves fullscreen once the homescreen loads in.
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromRGBO(4, 150, 255, 1), const Color.fromRGBO(45, 58, 58, 1)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.messenger_rounded,
              size: 140,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'DMAFT',
              style: TextStyle(
                fontStyle: FontStyle.normal,
                color: Colors.white,
                fontSize: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}