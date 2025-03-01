import 'package:flutter/material.dart';

import 'package:dmaft/contacts_screen.dart';
import 'package:dmaft/chats_screen.dart';
import 'package:dmaft/settings_screen.dart';

import 'package:dmaft/chat_test_list.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {

  int unread = ChatTestList.getSize();

  int myIndex = 1; // Default page on app startup.
  List<Widget> widgetList = const [
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
  void initState() {
    super.initState();
    _incrementCounter();
  }

  void _incrementCounter() async {
    while (true) {
      await Future.delayed(Duration(seconds: 5));
      ChatTestList.addToList('Test Test');
      setState(() {
        unread = ChatTestList.getSize();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: widgetList[myIndex],
        backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
        centerTitle: true,
        foregroundColor: Colors.white,
        toolbarHeight: 50,
        leading: IconButton(
          onPressed: () {},
          icon: Icon(Icons.add)
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.person,
            ),
          ),
        ],
      ),
      
      body: <Widget>[
        ContactsScreen(),
        ChatsScreen(),
        SettingsScreen(),
      ][myIndex],

      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            myIndex = index;
          });
        },
        indicatorColor: const Color.fromRGBO(4, 150, 255, 1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: myIndex,
        destinations: <Widget>[
          NavigationDestination(
            icon: Icon(
              Icons.contact_page,
            ),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$unread'), // unread messages
              child: Icon(Icons.message_rounded),
            ),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.settings,
            ),
            label: 'Settings',
          ),
        ],
      ),
      
    );
  }
}



