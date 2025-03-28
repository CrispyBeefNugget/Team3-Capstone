import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'network.dart';
import 'dart:io';
import 'test_keys.dart';

/*
This is an old copy of the lib/main.dart file that was slightly modified to allow for networking.
The instructions to start networking are included in the lib folder, in wbs_comms.dart.
*/

//REMOVE THIS FROM PRODUCTION; IT ALLOWS CONNECTING TO SERVERS WITH SELF-SIGNED CERTIFICATES
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides(); //REMOVE FROM PRODUCTION; ONLY FOR SELF-SIGNED CERTS
  runApp(const DMAFT());
}

class DMAFT extends StatelessWidget {
  const DMAFT({super.key});

  // This widget is the root of your application.
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
    
    return const MaterialApp(
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int myIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DMAFT'),
        backgroundColor: Color.fromRGBO(4, 150, 255, 1),
        centerTitle: true,
        foregroundColor: Colors.white,
        toolbarHeight: 50,
      ),
      body: const Text('Welcome to DMAFT!'),
      bottomNavigationBar: BottomNavigationBar(

        onTap: (index) {
          setState(() {
            myIndex = index;
          });
        },

        currentIndex: myIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
            ),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.maps_ugc_rounded,
            ),
            label: 'New Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.search,
            ),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
            ),
            label: 'Settings',
          ),
        ],
        selectedItemColor: Color.fromRGBO(4, 150, 255, 1),
        unselectedItemColor: Color.fromRGBO(45, 58, 58, 1),
      ),
    );
  }
}



