import 'package:flutter/material.dart';

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
        type: BottomNavigationBarType.fixed,
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



