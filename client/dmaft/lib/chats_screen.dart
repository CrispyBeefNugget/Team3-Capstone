import 'package:dmaft/chat_test_list.dart';
import 'package:flutter/material.dart';

import 'package:dmaft/client_db.dart';
import 'dart:convert';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {

  final TextEditingController _searchController = TextEditingController();

  final ClientDB database_service = ClientDB.instance;

  ({List<Conversation> list, List<String> names}) chat_list = (list: [], names: []);
  ({List<Conversation> list, List<String> names}) _filteredList = (list: [], names: []);

  late List<bool> _selected;

  Map<String, Map<String, String>> userIDsToNames = {}; //Holds the userIDs and userNames for participants in each conversation.

  List<List<Contact>> chat_names = []; // Added another list to essentially substitute convoIDs with sender names.
                                       // Want to remove this and replace with a function that returns sender names
                                       // so that I don't need to make another filter list of names for searching.

  // List<String> testList = ChatTestList.getList();

  bool isSearchingMode = false;
  bool isSelectionMode = false;
  bool _selectAll = false;

  @override
  void initState() {
    get_chat_info().then((response) {
      setState(() {
        chat_list = (list: response.$1, names: response.$2);
      });
      initializeSelection();
      _filteredList = chat_list;
    });
    _searchController.addListener(_performSearch);
    super.initState();
  }

  Future<(List<Conversation>, List<String>)> get_chat_info() async {
    List<Conversation> db_conversations = await database_service.getAllConvos();
    List<String> conversation_names = [];
    //For each conversation, create a single string containing all other users in the convo.
    for(int i = 0; i < db_conversations.length; i++){
      List<Contact> convo_members = await database_service.getConvoMembers(db_conversations[i].convoID);
      String temp = "";
      //For each convo member, add their name to the string.
      for(int j = 0; j < convo_members.length; j++){
        temp = "$temp   ${convo_members[j].name}";
      }
      conversation_names.add(temp);
      //Also update the userIDToName list with convo member data and the user's data.
      Contact user = await database_service.getUser();
      convo_members.add(user);
      Map<String, String> temp2 = ClientDB.userIDNameMap(convo_members);
      userIDsToNames[db_conversations[i].convoID] = temp2;
    }
    return (db_conversations, conversation_names); //Returns a Record
  }

  // These are the methods I've created to try replacing the convoID's in the list with the sender names.
  // ----------------------------------------------------------------------------------------------------

  Future<void> get_chat_members() async { // This method works fine but I would rather not use a second list for just names.
    List<List<Contact>> db_contacts = [];
    for (int i = 0; i < chat_list.list.length; i++) {
      db_contacts.add(await database_service.getConvoMembers(chat_list.list[i].convoID));
    }
    setState(() {
      chat_names = db_contacts;
    });
  }

  // This method theoretically works but I'm struggling to add this in the FutureBuilder below because it takes a parameter.
  Future<String> resolve_sender_name(conversation_id) async { 
    List<Contact> sender = await database_service.getConvoMembers(conversation_id);
    return sender[0].name;
  }

  // This method has issues, as you can see when running the app and going to the chats tab.
  String resolve_sender_name2(conversation_id) {
    String name = '';
    database_service.getConvoMembers(conversation_id).then((response) {
      List<Contact> members = response;
      Contact sender = members[0];
      String sender_name = sender.name;
      setState(() {
        name = sender_name;
      });
      name = sender_name;
      print('Inside .then()');
      print(sender_name); // Names show up here.
      return sender_name;
    });
    print('Outside .then()');
    print(name); // Names are blank here.
    return name;
  }

  // ----------------------------------------------------------------------------------------------------

  Future<List<MsgLog>> get_chat_messages(conversation_id) async {
    List<MsgLog> messages = await database_service.getMsgLogs(conversation_id);
    return messages;
  }

  void initializeSelection() {
    _selected = List<bool>.generate(chat_list.names.length, (_) => false);
  }

  void _toggle(int index) {
    setState(() {
      _selected[index] = !_selected[index];
    });
  }

  @override
  void dispose() {
    _selected.clear();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      if (isSelectionMode) {
        _searchController.text = '';
      }
      if (_searchController.text != '') {
        isSearchingMode = true;

        ({List<Conversation> list, List<String> names}) temp_list = (list: [], names: []);
        for (int i = 0; i < chat_list.list.length; i++) {
          if (chat_list.names[i].toLowerCase().contains(_searchController.text.toLowerCase())) {
            temp_list.list.add(chat_list.list[i]);
            temp_list.names.add(chat_list.names[i]);
          }
        }
        _filteredList = temp_list;


        // _filteredList = chat_list
        //   .where((element_1, element_2) => element_2
        //     .toLowerCase()
        //     .contains(_searchController.text.toLowerCase()))
        //   .toList();
      }
      else {
        isSearchingMode = false;
        _filteredList = chat_list;
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        leading: Icon(Icons.search),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
            color: Colors.white,
          ),
        ),
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.black),
          cursorColor: Colors.black,
          decoration: const InputDecoration(
            hintText: 'Search Chats',
            hintStyle: TextStyle(color: Colors.black),
            border: InputBorder.none,
          ),
        ),
        actions: <Widget>[
          if (isSearchingMode)
            IconButton(
              onPressed: () {
                _searchController.text = '';
              },
              icon: Icon(Icons.close)
            ),
        ],
      ),

      body: FutureBuilder(
        future: get_chat_info(),
        //future: Future.wait([get_chat_info(), get_chat_members()]),
        //future: Future.wait([get_chat_info(), get_chat_members(), resolve_sender_name(conversation_id)]), // What I'm trying to do.
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {

            return Scaffold(
              appBar: AppBar(
                leading: 
                  isSelectionMode
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            isSelectionMode = false;
                          });
                          initializeSelection();
                        },
                    )
                    : const SizedBox(),
                actions: <Widget>[
                  if (isSelectionMode)
                    IconButton(
                      onPressed: () {
                        // for (int i = 0; i < testList.length; i++) {
                        //   if (_selected[i] == true) {
                        //     testList[i] = '';
                        //   }
                        // }
                        // testList.removeWhere((String chat) => chat == '');
                        // isSelectionMode = false; // Need to implement list refreshing and properly close out of selection mode.
                        // Insert delete function here.
                      },
                      icon: Icon(Icons.delete)
                    ),
                    TextButton(
                      child:
                        !_selectAll
                          ? const Text('select all', style: TextStyle(color: Colors.black))
                          : const Text('unselect all', style: TextStyle(color: Colors.black)),
                      onPressed: () {
                        _selectAll = !_selectAll;
                        setState(() {
                          _selected = List<bool>.generate(chat_list.list.length, (_) => _selectAll);
                        });
                      },
                    ),
                ],
                toolbarHeight:
                  isSelectionMode ? 50 : 0,
              ),

              body:
                isSearchingMode
                ? ListView.builder(
                  itemCount: _filteredList.names.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: Icon(Icons.person),
                    title: Text(
                      _filteredList.names[index],
                      //chat_names[index][0].name, // Ideally I don't want to do this because as soon as you search the names are off.
                      //resolve_sender_name2(_filteredList[index].convoID),
                      //resolve_sender_name(_filteredList[index].convoID), // This is what I'm trying to achieve here.
                      style: const TextStyle(color: Colors.black),
                    ),
                    onTap: () => {
                      
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: Text(_filteredList.names[index]),
                            //title: Text(chat_names[index][0].name), // Same as above.
                            //title: Text(resolve_sender_name2(_filteredList[index].convoID)),
                            centerTitle: true,
                            backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
                            foregroundColor: Colors.white,
                          ),
                          body: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(10.0)
                              ),





                              Center(
                                child: Text(_filteredList.names[index]),
                              )
                            ],
                          )
                        ))
                      )
                      

                    },
                    trailing:
                      isSelectionMode
                        ? Checkbox(
                          value: _selected[index],
                          onChanged: (bool? x) => {
                            setState(() {
                              _selected[index] = !_selected[index];
                            })
                          },
                        )
                        : const SizedBox.shrink(),
                  ),
                )

                : ListView.builder(
                  itemCount: _selected.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: Icon(Icons.person),
                    onTap: () => {
                      if (isSelectionMode) {
                        _toggle(index)
                      }
                      else {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: Text(chat_list.names[index]),
                              //title: Text(chat_names[index][0].name), // Same as above.
                              //title: Text(resolve_sender_name2(chat_list[index].convoID)),
                              centerTitle: true,
                              backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
                              foregroundColor: Colors.white,
                            ),
                            body: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(10.0)
                                ),


                                FutureBuilder(
                                  future: get_chat_messages(chat_list.list[index].convoID),
                                  builder: (BuildContext context2, AsyncSnapshot snapshot2) {
                                    if (snapshot2.hasData) {

                                      List<MsgLog> messages = snapshot2.data;
                                      return Expanded(
                                        child: SizedBox(
                                          child: ListView.builder(
                                            itemCount: messages.length,
                                            itemBuilder: (context3, index2) => ListTile(
                                              title: Text(utf8.decode(messages[index2].message)),
                                              subtitle: Text(messages[index2].rcvTime),
                                              titleAlignment: ListTileTitleAlignment.center,
                                              
                                            ),
                                          ),
                                        ),
                                          



                                          // ListTile(
                                          //   title: Text(utf8.decode(messages[0].message)),
                                          //   titleAlignment: ListTileTitleAlignment.center,
                                          // ),
                                          // ListTile(
                                          //   title: Text(utf8.decode(messages[1].message)),
                                          //   titleAlignment: ListTileTitleAlignment.center,
                                          // ),
                                        
                                      );

                                      // return ListView.builder(                                     // Left off here
                                      //   itemCount: messages.length,
                                      //   itemBuilder: (_, index2) => ListTile(
                                      //     title: Text(utf8.decode(messages[index2].message)),
                                      //     trailing: Text(messages[index2].rcvTime),
                                      //   ),
                                      // );
                                    }
                                    else {
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                  },
                                ),



                                // Center(
                                //   child: Text(chat_list.list[index]),
                                // ),


                                TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Type Message',
                                  ),
                                ),
                              ],
                            )
                          ))
                        )
                      }
                    },

                    onLongPress: () {
                      if (!isSelectionMode) {
                        setState(() {
                          _selected[index] = true;
                        });
                        isSelectionMode = true;
                      }
                    },
                    trailing: 
                      isSelectionMode
                        ? Checkbox(
                          value: _selected[index],
                          onChanged: (bool? x) => _toggle(index),
                        )
                        : SizedBox.shrink(),
                    title: Text(chat_list.names[index]),
                    //title: Text(chat_names[index][0].name ?? ""), // Same as above.
                    //title: Text(resolve_sender_name2(chat_list[index].convoID))
                  ),
                )


            );

          }
          else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }


        },
      )
      
      
      
    );
  }
}
