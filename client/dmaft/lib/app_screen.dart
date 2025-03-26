import 'dart:ffi';

import 'package:flutter/material.dart';

import 'package:dmaft/contacts_screen.dart';
import 'package:dmaft/chats_screen.dart';
import 'package:dmaft/settings_screen.dart';

import 'package:dmaft/client_db.dart';

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

  final ClientDB database_service = ClientDB.instance;
  late Contact user;

  @override
  void initState() {
    get_user().then((response) {
      user = response;
    });
    get_message_count().then((response) {
      unread = response;
    });
    super.initState();
    //_incrementCounter();
  }

  // void _incrementCounter() async {
  //   while (true) {
  //     await Future.delayed(Duration(seconds: 5));
  //     ChatTestList.addToList('Test Test');
  //     setState(() {
  //       unread = ChatTestList.getSize();
  //     });
  //   }
  // }

  Future<Contact> get_user() async {
    var current_user = await database_service.getUser();
    return current_user;
  }

  Future<int> get_message_count() async {
    List<Conversation> db_conversations = await database_service.getAllConvos();
    return db_conversations.length;
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
        leading: 
          (myIndex == 1)
          ? IconButton(
              onPressed: () {
                Navigator.of(context).push(

                  MaterialPageRoute(builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text('New Conversation'),
                      centerTitle: true,
                      backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
                      foregroundColor: Colors.white,
                    ),
                    body: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search User',
                      ),
                    ),

                  ))

                );


              },
              icon: Icon(Icons.add)
          )
          : const SizedBox(),
        actions: <Widget>[
          IconButton(
            onPressed: () {

              showDialog<String>(
                context: context,
                builder: (BuildContext context) => FutureBuilder(
                  future: get_user(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      return AlertDialog(
                        title: Text(user.name),
                        content: Column(
                          children: [
                            Center(
                              child: CircleAvatar(
                                backgroundImage: Image.memory(user.pic).image,
                              ),
                            ),
                            Text(user.id),
                            Text(user.pronouns),
                            Text(user.bio),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'Done'),
                            child: const Text('Done'),
                          ),
                        ],
                      );
                    }
                    else {
                      return AlertDialog(
                        title: const Text('Loading User'),
                        content: const Text('Loading Details'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'Done'),
                            child: const Text('Done'),
                          ),
                        ],
                      );
                    }
                  }
                )
              );
                
                
                
                

            },
            icon: const Icon(
              Icons.person,
            ),
          ),
        ],
      ),
      
      body: <Widget>[
        ContactsScreen(),
        // ContactsTest(),
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
              label: FutureBuilder(
                future: get_message_count(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    return Text('$unread');
                  }
                  else {
                    return Text('?');
                  }
                },
              ),             
              // label: Text('$unread'), // unread messages
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

// class ChatsScreenController extends ChangeNotifier {
//   List<String> _testList = ChatTestList.getList();

// }

