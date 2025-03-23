import 'package:dmaft/chat_test_list.dart';
import 'package:flutter/material.dart';

import 'package:dmaft/client_db.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {

  final TextEditingController _searchController = TextEditingController();

  final ClientDB database_service = ClientDB.instance;

  ({List<Conversation> list, List<String> names}) chat_list = (list: [], names: []);

  List<Conversation> _filteredList = [];
  late List<bool> _selected;

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
      _filteredList = chat_list.list;
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

  void initializeSelection() {
    _selected = List<bool>.generate(chat_list.list.length, (_) => false);
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
        _filteredList = chat_list.list
          .where((element) => element.convoID
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()))
          .toList();
      }
      else {
        isSearchingMode = false;
        _filteredList = chat_list.list;
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
                  itemCount: _filteredList.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: Icon(Icons.person),
                    title: Text(
                      _filteredList[index].convoID,
                      //chat_names[index][0].name, // Ideally I don't want to do this because as soon as you search the names are off.
                      //resolve_sender_name2(_filteredList[index].convoID),
                      //resolve_sender_name(_filteredList[index].convoID), // This is what I'm trying to achieve here.
                      style: const TextStyle(color: Colors.black),
                    ),
                    onTap: () => {
                      
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: Text(_filteredList[index].convoID),
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
                                child: Text(_filteredList[index].lastModified),
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
                                Center(
                                  child: Text(chat_list.list[index].lastModified),
                                )
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
