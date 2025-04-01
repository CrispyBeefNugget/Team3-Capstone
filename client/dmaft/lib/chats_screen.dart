import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:dmaft/client_db.dart';
import 'package:dmaft/network.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {

  // Allows us to search in the appbar textfield.
  final TextEditingController _searchController = TextEditingController();

  // Allows us to access the client database, the contents of which are stored locally on device.
  final ClientDB databaseService = ClientDB.instance;

  ({List<Conversation> list, List<String> names}) conversationList = (list: [], names: []);
  ({List<Conversation> list, List<String> names}) _filteredList = (list: [], names: []);
  late List<bool> _selected;
  List<MsgLog> messages = [];

  Map<String, Map<String, String>> userIDsToNames = {}; //Holds the userIDs and userNames for participants in each conversation.

  bool isSearchingMode = false;
  bool isSelectionMode = false;
  bool _selectAll = false;

  @override
  void initState() {
    getConversationInfo().then((response) {
      setState(() {
        conversationList = (list: response.$1, names: response.$2);
      });
      initializeSelection();
      _filteredList = conversationList;
    });
    _searchController.addListener(_performSearch);
    super.initState();
  }

  // Gets the conversations from the client database.
  Future<(List<Conversation>, List<String>)> getConversationInfo() async {
    List<Conversation> dbConversations = await databaseService.getAllConvos();
    List<String> conversationNames = [];
    //For each conversation, create a single string containing all other users in the convo.
    for(int i = 0; i < dbConversations.length; i++){
      List<Contact> convoMembers = await databaseService.getConvoMembers(dbConversations[i].convoID);
      String temp = "";
      //For each convo member, add their name to the string.
      for(int j = 0; j < convoMembers.length; j++){
        temp = "$temp   ${convoMembers[j].name}";
      }
      conversationNames.add(temp);
      //Also update the userIDToName list with convo member data and the user's data.
      Contact user = await databaseService.getUser();
      convoMembers.add(user);
      Map<String, String> temp2 = ClientDB.userIDNameMap(convoMembers);
      userIDsToNames[dbConversations[i].convoID] = temp2;
    }
    return (dbConversations, conversationNames); //Returns a Record
  }

  // Gets the messages of a specific conversation from the client database.
  Future<List<MsgLog>> getChatMessages(conversationId) async {
    List<MsgLog> logs = await databaseService.getMsgLogs(conversationId);
    return logs;
  }

  // Refreshes the conversations screen.
  void refreshConversations() {
    getConversationInfo().then((response) {
      setState(() {
        conversationList = (list: response.$1, names: response.$2);
      });
      initializeSelection();
      _filteredList = conversationList;
    });
  }

  // Refreshes the messages in a conversation. Currently bugged iirc.
  void refreshMessages(String conversationId) {
    getChatMessages(conversationId).then((response) {
      setState(() {
        messages = response;
      });
    });
  }

  // Initializes a list of bools which is used to determine if a conversation is selected.
  void initializeSelection() {
    _selected = List<bool>.generate(conversationList.names.length, (_) => false);
  }

  // Toggles whether the specified conversation by index is selected or not.
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

  // Toggles searching mode depending on if the user types in the text field.
  Future<void> _performSearch() async {
    setState(() {
      if (isSelectionMode) { // Prevents the user from using the search bar if selection mode is enabled.
        _searchController.text = '';
      }
      if (_searchController.text != '') { // Searching mode is enabled as soon as there is text in the search bar.
        isSearchingMode = true;
        ({List<Conversation> list, List<String> names}) tempList = (list: [], names: []);
        for (int i = 0; i < conversationList.list.length; i++) {
          if (conversationList.names[i].toLowerCase().contains(_searchController.text.toLowerCase())) {
            tempList.list.add(conversationList.list[i]);
            tempList.names.add(conversationList.names[i]);
          }
        }
        _filteredList = tempList;
      }
      else {
        isSearchingMode = false;
        _filteredList = conversationList;
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar( // The search bar is located in the appbar.
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
            hintText: 'Search Conversations',
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
        future: getConversationInfo(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {

            return Scaffold( // Whenever selection mode is enabled an appbar with options appears under the search bar.
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
                        
                        for (int i = 0; i < conversationList.list.length; i++) {
                          if (_selected[i] == true) {
                            databaseService.delConvo(conversationList.list[i]);
                          }
                        }
                        refreshConversations();
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
                          _selected = List<bool>.generate(conversationList.list.length, (_) => _selectAll);
                        });
                      },
                    ),
                ],

                toolbarHeight: isSelectionMode ? 50 : 0,
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
                      TextEditingController messageContent = TextEditingController();

                      refreshMessages(_filteredList.list[index].convoID);

                      // Clicking on a conversation opens a page containing the messages part of that conversation.
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
                                    databaseService.delConvo(_filteredList.list[index]);
                                    refreshConversations();
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

                              FutureBuilder( // The messages portion of the conversation.
                                future: getChatMessages(_filteredList.list[index].convoID),
                                builder: (BuildContext context2, AsyncSnapshot snapshot2) {

                                  if (snapshot2.connectionState != ConnectionState.done) { // Left off here on trying to get the FutureBuilder to refresh.
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  else if (snapshot2.hasData) { // Messages are loaded in with the ListView.builder.
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

                              Row( // The textfield and sending portion of the conversation.
                                children: <Widget>[
                                  Expanded(
                                    child: TextField(
                                      controller: messageContent,
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
                                        print(messageContent.text);
                                        MsgLog log = MsgLog(convoID: _filteredList.list[index].convoID, msgID: 'test', msgType: 'Text', senderID: 'test', rcvTime: DateTime.now().toString(), message: utf8.encode(messageContent.text));
                                        databaseService.addMsgLog(log);
                                        Network net = Network();
                                        net.sendTextMessage(_filteredList.list[index].convoID, messageContent.text);
                                        refreshMessages(_filteredList.list[index].convoID);
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
                        TextEditingController messageContent = TextEditingController();

                        refreshMessages(_filteredList.list[index].convoID);

                        // Clicking on a conversation opens a page containing the messages part of that conversation.
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: Text(conversationList.names[index]),
                              centerTitle: true,
                              backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
                              foregroundColor: Colors.white,
                              actions: [
                                IconButton(
                                  onPressed: () {
                                    databaseService.delConvo(conversationList.list[index]);
                                    refreshConversations();
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

                                FutureBuilder( // The messages portion of the conversation.
                                  future: getChatMessages(conversationList.list[index].convoID),
                                  builder: (BuildContext context2, AsyncSnapshot snapshot2) {

                                    if (snapshot2.hasData) { // Messages are loaded in with the ListView.builder.
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

                                Row( // The textfield and sending portion of the conversation.
                                  children: <Widget>[
                                    Expanded(
                                      child: TextField(
                                        controller: messageContent,
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
                                          print(messageContent.text);
                                          MsgLog log = MsgLog(convoID: conversationList.list[index].convoID, msgID: 'test', msgType: 'Text', senderID: 'test', rcvTime: DateTime.now().toString(), message: utf8.encode(messageContent.text)); // Change to the generated IDs provided by Ben's methods.
                                          databaseService.addMsgLog(log);
                                          Network net = Network();
                                          net.sendTextMessage(conversationList.list[index].convoID, messageContent.text);
                                          refreshMessages(conversationList.list[index].convoID);
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

                    onLongPress: () { // Selection mode is enabled if a user holds on a conversation.
                      if (!isSelectionMode) {
                        setState(() {
                          _selected[index] = true;
                        });
                        isSelectionMode = true;
                      }
                    },
                    trailing: 
                      isSelectionMode
                        ? Checkbox( // Checkboxes appear on the right side of the tiles if selection mode is enabled.
                          value: _selected[index],
                          onChanged: (bool? x) => _toggle(index),
                        )
                        : const SizedBox.shrink(),
                    title: Text(conversationList.names[index]),
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
