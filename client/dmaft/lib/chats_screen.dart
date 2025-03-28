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

  List<MsgLog> messages = [];

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

  Future<List<MsgLog>> get_chat_messages(conversation_id) async {
    List<MsgLog> logs = await database_service.getMsgLogs(conversation_id);
    return logs;
  }

  void refresh_conversations() {
    get_chat_info().then((response) {
      setState(() {
        chat_list = (list: response.$1, names: response.$2);
      });
      initializeSelection();
      _filteredList = chat_list;
    });
  }

  void refresh_messages(String conversation_id) {
    get_chat_messages(conversation_id).then((response) {
      setState(() {
        messages = response;
      });
    });
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
                        
                        for (int i = 0; i < chat_list.list.length; i++) {
                          if (_selected[i] == true) {
                            database_service.delConvo(chat_list.list[i]);
                          }
                        }
                        refresh_conversations();
                        setState(() {
                          isSelectionMode = false;
                          initializeSelection();
                        });

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
                      style: const TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      TextEditingController _messageContent = TextEditingController();

                      refresh_messages(_filteredList.list[index].convoID); // Need to fix

                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: Text(_filteredList.names[index]),
                            centerTitle: true,
                            backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
                            foregroundColor: Colors.white,
                            actions: [
                                IconButton(
                                  onPressed: () {
                                    database_service.delConvo(_filteredList.list[index]);
                                    refresh_conversations();
                                    Navigator.pop(context);
                                    _searchController.text = '';
                                  },
                                  icon: Icon(Icons.delete),
                                ),
                              ],
                          ),
                          body: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(10.0)
                              ),

                              FutureBuilder(
                                future: get_chat_messages(_filteredList.list[index].convoID),
                                builder: (BuildContext context2, AsyncSnapshot snapshot2) {

                                  if (snapshot2.connectionState != ConnectionState.done) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  else if (snapshot2.hasData) {
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
                                      
                                    );

                                  }
                                  else {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                },
                              ),

                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextField(
                                      controller: _messageContent,
                                      decoration: const InputDecoration(
                                        hintText: 'Type Message',
                                      ),
                                      style: const TextStyle(color: Colors.black),
                                      cursorColor: Colors.black,
                                    ),
                                  ),

                                  SizedBox(
                                    width: 50,
                                    child: IconButton(
                                      onPressed: () { // Need to fix the refresh to work with refreshing the futurebuilder
                                        print(_messageContent.text);
                                        MsgLog log = MsgLog(convoID: _filteredList.list[index].convoID, msgID: 'test', msgType: 'Text', senderID: 'test', rcvTime: 'test', message: utf8.encode(_messageContent.text));
                                        database_service.addMsgLog(log);

                                        refresh_messages(_filteredList.list[index].convoID);
                                      },
                                      icon: Icon(Icons.send),
                                    ),
                                  ),
                                
                                ],
                              ),

                              Padding(
                                padding: EdgeInsets.all(10.0)
                              ),

                              

                            ],
                          )
                        ))
                      );
                      

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
                    onTap: () {
                      if (isSelectionMode) {
                        _toggle(index);
                      }
                      else {
                        TextEditingController _messageContent = TextEditingController();

                        refresh_messages(_filteredList.list[index].convoID); // Need to fix

                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: Text(chat_list.names[index]),
                              centerTitle: true,
                              backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
                              foregroundColor: Colors.white,
                              actions: [
                                IconButton(
                                  onPressed: () {
                                    database_service.delConvo(chat_list.list[index]);
                                    refresh_conversations();
                                    Navigator.pop(context);
                                  },
                                  icon: Icon(Icons.delete),
                                ),
                              ],
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
                                          


                                        
                                      );


                                    }
                                    else {
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                  },
                                ),



                                  Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: TextField(
                                        controller: _messageContent,
                                        decoration: const InputDecoration(
                                          hintText: 'Type Message',
                                        ),
                                        style: const TextStyle(color: Colors.black),
                                        cursorColor: Colors.black,
                                      ),
                                    ),

                                    SizedBox(
                                      width: 50,
                                      child: IconButton(
                                        onPressed: () { // Need to fix the refresh to work with refreshing the futurebuilder
                                          print(_messageContent.text);
                                          MsgLog log = MsgLog(convoID: chat_list.list[index].convoID, msgID: 'test', msgType: 'Text', senderID: 'test', rcvTime: 'test', message: utf8.encode(_messageContent.text));
                                          database_service.addMsgLog(log);

                                          refresh_messages(chat_list.list[index].convoID);
                                        },
                                        icon: Icon(Icons.send),
                                      ),
                                    ),
                                  
                                  ],
                                ),

                                Padding(
                                  padding: EdgeInsets.all(10.0)
                                ),
                              ],
                            ),
                          ))
                        );
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
