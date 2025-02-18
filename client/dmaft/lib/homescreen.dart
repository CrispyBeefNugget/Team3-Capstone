import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int myIndex = 1;
  List<Widget> widgetList = [
    Text(
      'Contacts',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    Text(
      'Chats',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    Text(
      'Settings',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widgetList[myIndex],
        backgroundColor: Color.fromRGBO(4, 150, 255, 1),
        centerTitle: true,
        foregroundColor: Colors.white,
        toolbarHeight: 50,
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.person,

            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            SizedBox(
              height: 59.0,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(4, 150, 255, 1),
                ),
                child: Text(
                  'DMAFT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),

            ListTile(
              title: const Text('New Chat'),
              onTap: () {},
            ),
            ListTile(
              title: const Text('Search'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Center(
        child: Text('Placeholder'),
      ),
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
              Icons.contact_page,
            ),
            label: 'Contacts',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.message_rounded,
            ),
            label: 'Chats',
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



