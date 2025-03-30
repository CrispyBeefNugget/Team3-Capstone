import 'dart:ffi';

import 'package:flutter/material.dart';

import 'package:dmaft/contacts_screen.dart';
import 'package:dmaft/chats_screen.dart';
import 'package:dmaft/settings_screen.dart';
import 'package:dmaft/client_db.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {

  late int unread;

  int myIndex = 1; // Default page on app startup (Chats Screen).
  List<Widget> widgetList = const [
    Text(
      'Contacts',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),

    Text(
      'Conversations',
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

  final ClientDB databaseService = ClientDB.instance;
  late Contact user;

  @override
  void initState() {
    getUser().then((response) {
      user = response;
    });
    getMessageCount().then((response) {
      unread = response;
    });
    super.initState();
    //_incrementCounter();
  }

  // void _incrementCounter() async {
  //   while (true) {
  //     await Future.delayed(Duration(seconds: 5)); // Might use as inspiration to update the notification counter.
  //     ChatTestList.addToList('Test Test');
  //     setState(() {
  //       unread = ChatTestList.getSize();
  //     });
  //   }
  // }

  // Returns the contact information of the current user.
  Future<Contact> getUser() async {
    var currentUser = await databaseService.getUser();
    return currentUser;
  }

  // Returns the number of messages that the user has. This will be changed to the number of unread messages (need to differentiate between read and unread messages).
  Future<int> getMessageCount() async {
    List<Conversation> dbConversations = await databaseService.getAllConvos();
    return dbConversations.length;
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
        title: widgetList[myIndex], // Title changes based on which tab the user is on.
        backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
        centerTitle: true,
        foregroundColor: Colors.white,
        toolbarHeight: 50,
        leading: 
          (myIndex == 1)
          ? IconButton(
              onPressed: () {

                // Opens a new page that allows for the adding of new users to message.
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text('New Conversation'),
                      centerTitle: true,
                      backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
                      foregroundColor: Colors.white,
                    ),
                    body: Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search User',
                          ),
                        ),

                        // Insert FutureBuilder + ListBuilder here that queries the network for users based on username.

                      ],
                    ),
                  )),
                );

              },
              icon: const Icon(Icons.add),
          )
          : const SizedBox(), // Only the Chats Screen while have the add button.
        actions: <Widget>[
          IconButton(
            onPressed: () {

              // Shows the details of the user.
              showDialog<String>(
                context: context,
                builder: (BuildContext context) => FutureBuilder(
                  future: getUser(),
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
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      
      // Body of the app screen changes depending on which tab the user has selected.
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

          NavigationDestination( // Contacts tab.
            icon: Icon(Icons.contact_page),
            label: 'Contacts',
          ),

          NavigationDestination( // Conversations tab.
            icon: Badge(
              label: FutureBuilder(
                future: getMessageCount(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    return Text('$unread');
                  }
                  else {
                    return Text('?');
                  }
                },
              ),             
              child: Icon(Icons.message_rounded),
            ),
            label: 'Conversations',
          ),

          NavigationDestination( // Settings tab.
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

// class ChatsScreenController extends ChangeNotifier { // Might need change notifier for updating the unread count.
//   List<String> _testList = ChatTestList.getList();

// }