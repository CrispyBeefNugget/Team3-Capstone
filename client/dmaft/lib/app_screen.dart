import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:dmaft/network.dart';
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

  // late int unread; // No longer implemented due to time constraints.

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
    // getMessageCount().then((response) { // No longer implemented due to time constraints.
    //   unread = response;
    // });
    super.initState();
  }

  // Returns the contact information of the current user.
  Future<Contact> getUser() async {
    var currentUser = await databaseService.getUser();
    return currentUser;
  }

  // Returns the number of conversations that the user has (no longer implemented due to time constraints).
  // Future<int> getMessageCount() async {
  //   List<Conversation> dbConversations = await databaseService.getAllConvos();
  //   return dbConversations.length;
  // }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final ThemeData theme = Theme.of(context);
    final TextEditingController userIDController = TextEditingController();


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
                  MaterialPageRoute(builder: (context) {
                    List results = [];
                    return Scaffold(
                      appBar: AppBar(
                        title: Text('New Conversation'),
                        centerTitle: true,
                        backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
                        foregroundColor: Colors.white,
                      ),
                      body: Column(
                        children: [
                          TextField(
                            controller: userIDController,
                            decoration: const InputDecoration(
                              hintText: 'Enter UserID',
                            ),
                          ),
                          TextButton(
                            child: Text('Submit'),
                            onPressed: () async {
                              final net = Network();
                              net.createNewConversation([userIDController.text]);
                              Navigator.pop(context);
                            }
                          ),

                          // Does not work. The whole block of code in the MaterialPageRoute may need to be put in either a FutureBuilder or StreamBuilder.
                          Expanded(
                            child: SizedBox(
                              child: ListView.builder(
                                itemCount: results.length,
                                itemBuilder: (_, index) => ListTile(
                                  leading: Icon(Icons.person),
                                  title: Text(
                                    results[index]['UserName']
                                  ),
                                  onTap:() {
                                  },
                                ),
                              ),
                            ),
                          ),

                          
                      
                        ],
                      ),
                    );
                  }),
                );

              },
              icon: const Icon(Icons.add),
          )
          : const SizedBox(), // Only the Chats Screen while have the add button.
        // actions: <Widget>[ // No longer implemented due to time constraints.
        //   IconButton(
        //     onPressed: () {

        //       // Shows the details of the user.
        //       showDialog<String>(
        //         context: context,
        //         builder: (BuildContext context) => FutureBuilder(
        //           future: getUser(),
        //           builder: (BuildContext context, AsyncSnapshot snapshot) {
        //             if (snapshot.hasData) {
        //               return AlertDialog(
        //                 title: Text(user.name),
        //                 content: Column(
        //                   children: [
        //                     Center(
        //                       child: CircleAvatar(
        //                         backgroundImage: Image.memory(user.pic).image,
        //                       ),
        //                     ),
        //                     Text(user.id),
        //                     Text(user.pronouns),
        //                     Text(user.bio),
        //                   ],
        //                 ),
        //                 actions: <Widget>[
        //                   TextButton(
        //                     onPressed: () => Navigator.pop(context, 'Done'),
        //                     child: const Text('Done'),
        //                   ),
        //                 ],
        //               );
        //             }
        //             else {
        //               return AlertDialog(
        //                 title: const Text('Loading User'),
        //                 content: const Text('Loading Details'),
        //                 actions: <Widget>[
        //                   TextButton(
        //                     onPressed: () => Navigator.pop(context, 'Done'),
        //                     child: const Text('Done'),
        //                   ),
        //                 ],
        //               );
        //             }
        //           }
        //         )
        //       );  

        //     },
        //     icon: const Icon(Icons.person),
        //   ),
        // ],
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

          /* Remnants from old "unread message count" system
          Badge(
              label: Text(''),
              // FutureBuilder( // No longer implemented due to time constraints.
              //   future: getMessageCount(),
              //   builder: (BuildContext context, AsyncSnapshot snapshot) {
              //     if (snapshot.hasData) {
              //       return Text('$unread');
              //     }
              //     else {
              //       return Text('?');
              //     }
              //   },
              // ),             
              child: 
          */

          NavigationDestination( // Conversations tab.
            icon: Icon(
              Icons.message_rounded
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