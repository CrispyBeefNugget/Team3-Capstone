import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:dmaft/client_db.dart';
import 'package:dmaft/network.dart';

import 'package:file_picker/file_picker.dart';

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
  List<bool> _selected = [];
  static Map<String, List<MsgLog>> messages = {}; //Stores the message logs for each conversation. Accessed using the convoID.

  Map<String, Map<String, String>> userIDsToNames = {}; //Holds the userIDs and userNames for participants in each conversation.

  bool isSearchingMode = false;
  bool isSelectionMode = false;
  bool _selectAll = false;

  String userID = "";

  StreamController<Map<String, List<MsgLog>>> messageController = StreamController<Map<String, List<MsgLog>>>.broadcast();
  final ScrollController _scrollController = ScrollController();

  Timer? timer; //Used to periodically refresh the message stream to see sent messages.

  @override
  void initState() {
    fetchAllMessages();

    //Passes the messageController the current messages state.
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => fetchAllMessages());
    
    
    getUserID().then((response){
      userID = response;
    });

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

  //Fetches all messages in the database and passes the info on to the message stream.
  Future<void> fetchAllMessages() async {
    //Fill the messages static variable with all conversations' existing messageLogs.
    databaseService.getAllConvos().then((response) async{
      List<Conversation> conversations = response;
      for(int i = 0; i < conversations.length; i++){
        messages[conversations[i].convoID] = await getChatMessages(conversations[i].convoID);
      } 
      if(_scrollController.hasClients){
        //_scrollDown(); This implementation will continually scroll down, not allowing the user to scroll through message history.
      }
    });
    //Update the message stream.
    messageController.add(messages);
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
  Future<List<MsgLog>> getChatMessages(String conversationId) async {
    List<MsgLog> logs = await databaseService.getMsgLogs(conversationId);
    return logs;
  }

  Future<void> setChatMessageVariable(String convoID) async {
    List<MsgLog> logs = await databaseService.getMsgLogs(convoID);
    messages[convoID] = logs;
  }

  // Generates a message ID for a message in a conversation.
  Future<String> getMessageID(String conversationID) async {
    String messageID = await databaseService.generateMsgID(conversationID);
    return messageID;
  }

  // Gets the user (sender) ID.
  Future<String> getUserID() async {
    Contact user = await databaseService.getUser();
    return user.id;
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
      //messages = response;
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

  //Stream

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

  // Converts the Future of the current user to a Stream. This allows for refreshing the page after a change is made by the user.
  Stream refreshPage() {
    return Stream.fromFuture(getConversationInfo());
  }

  Stream refreshMessagePage(int index) {
    return Stream.fromFuture(getChatMessages(_filteredList.list[index].convoID));
  }

  //When called, moves the scroll view all the way to the current bottom position.
  void _scrollDown() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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

      body: StreamBuilder(
        stream: refreshPage(),
        //future: getConversationInfo(),
        initialData: conversationList,
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

                                StreamBuilder( // The messages portion of the conversation.
                                  stream: messageController.stream,
                                  initialData: messages,
                                  builder: (BuildContext context2, AsyncSnapshot snapshot2) {
                                    if (snapshot2.hasData) { // Messages are loaded in with the ListView.builder.
                                      return Expanded(
                                        child: SizedBox(
                                          child: ListView.builder(
                                            controller: _scrollController,
                                            padding: EdgeInsets.zero,
                                            itemCount: snapshot2.data[_filteredList.list[index].convoID].length,
                                            itemBuilder: (context3, index2) {
                                              DateTime timestamp = DateTime.parse(snapshot2.data[_filteredList.list[index].convoID][index2].rcvTime).toLocal();
                                              List<String> monthMap = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                                              return ChatBubble(
                                                message: utf8.decode(snapshot2.data[_filteredList.list[index].convoID][index2].message),
                                                isSentByMe: (snapshot2.data[_filteredList.list[index].convoID][index2].senderID == userID),
                                                rcvTime: "${timestamp.hour.toString()}:${(timestamp.minute < 10) ? '0' : ''}${timestamp.minute.toString()} ${monthMap[timestamp.month - 1]} ${timestamp.day.toString()}",
                                              );
                                            }
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

                                FutureBuilder(
                                  future: getUserID(),
                                  builder: (BuildContext context2, AsyncSnapshot snapshot2) {

                                    if (snapshot2.hasData) {

                                      return Row( // The textfield and sending portion of the conversation.
                                        children: <Widget>[
                                          //Upload icon.
                                            /* Not enough time to implement this.
                                            SizedBox( 
                                              width: 50,
                                              child: IconButton(
                                                onPressed: () async {
                                                  final result = await FilePicker.platform.pickFiles();
                                                  if(result == null) return;
                                                  final PlatformFile file = result.files.first;
                                                  setState(() {
                                                  });
                                                },
                                                icon: Icon(Icons.upload),
                                              ),
                                            ),
                                          */ 
                                          //Message text field.
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
                                          
                                          //Send icon.
                                          SizedBox(
                                            width: 50,
                                            child: IconButton(
                                              onPressed: () async { // Need to fix the refresh to work with refreshing the futurebuilder
                                                String newMsgID = await getMessageID(conversationList.list[index].convoID);                                              
                                                String userID = snapshot2.data;
                                                MsgLog log = MsgLog(convoID: _filteredList.list[index].convoID, msgID: newMsgID, msgType: 'Text', senderID: userID, rcvTime: DateTime.now().toUtc().toString(), message: utf8.encode(messageContent.text));
                                                databaseService.addMsgLog(log);
                                                Network net = Network();
                                                net.sendTextMessage(_filteredList.list[index].convoID, messageContent.text, newMsgID);
                                                //refreshMessages(_filteredList.list[index].convoID);
                                                fetchAllMessages();
                                                _scrollDown();
                                                messageContent.clear();
                                                },
                                              icon: Icon(Icons.send),
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    else {
                                      return CircularProgressIndicator();
                                    }

                                  }
                                ),

                                Padding(
                                  padding: EdgeInsets.all(10.0)
                                ),
                              ],
                            ),
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
                        setChatMessageVariable(_filteredList.list[index].convoID);
                         messageController.add(messages);
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
                                    setChatMessageVariable(_filteredList.list[index].convoID);
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

                                StreamBuilder( // The messages portion of the conversation.
                                  stream: messageController.stream,
                                  initialData: messages,
                                  builder: (BuildContext context2, AsyncSnapshot snapshot2) {
                                    if (snapshot2.hasData) { // Messages are loaded in with the ListView.builder.
                                      return Expanded(
                                        child: SizedBox(
                                          child: ListView.builder(
                                            controller: _scrollController,
                                            padding: EdgeInsets.zero,
                                            itemCount: snapshot2.data[_filteredList.list[index].convoID].length,
                                            itemBuilder: (context3, index2) {
                                              DateTime timestamp = DateTime.parse(snapshot2.data[_filteredList.list[index].convoID][index2].rcvTime).toLocal();
                                              List<String> monthMap = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                                              return ChatBubble(
                                                message: utf8.decode(snapshot2.data[_filteredList.list[index].convoID][index2].message),
                                                isSentByMe: (snapshot2.data[_filteredList.list[index].convoID][index2].senderID == userID),
                                                rcvTime: "${timestamp.hour.toString()}:${(timestamp.minute < 10) ? '0' : ''}${timestamp.minute.toString()} ${monthMap[timestamp.month - 1]} ${timestamp.day.toString()}",
                                              );
                                            }
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

                                FutureBuilder(
                                  future: getUserID(),
                                  builder: (BuildContext context2, AsyncSnapshot snapshot2) {

                                    if (snapshot2.hasData) {

                                      return Row( // The textfield and sending portion of the conversation.
                                        children: <Widget>[
                                          //Upload icon.
                                            /* Not enough time to implement this.
                                            SizedBox( 
                                              width: 50,
                                              child: IconButton(
                                                onPressed: () async {
                                                  final result = await FilePicker.platform.pickFiles();
                                                  if(result == null) return;
                                                  final PlatformFile file = result.files.first;
                                                  setState(() {
                                                  });
                                                },
                                                icon: Icon(Icons.upload),
                                              ),
                                            ),
                                          */ 
                                          //Message text field.
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
                                          
                                          //Send icon.
                                          SizedBox(
                                            width: 50,
                                            child: IconButton(
                                              onPressed: () async { // Need to fix the refresh to work with refreshing the futurebuilder
                                                String newMsgID = await getMessageID(conversationList.list[index].convoID);                                              
                                                String userID = snapshot2.data;
                                                MsgLog log = MsgLog(convoID: _filteredList.list[index].convoID, msgID: newMsgID, msgType: 'Text', senderID: userID, rcvTime: DateTime.now().toUtc().toString(), message: utf8.encode(messageContent.text));
                                                databaseService.addMsgLog(log);
                                                Network net = Network();
                                                net.sendTextMessage(_filteredList.list[index].convoID, messageContent.text, newMsgID);
                                                //refreshMessages(_filteredList.list[index].convoID);
                                                fetchAllMessages();
                                                _scrollDown();
                                                messageContent.clear();
                                                },
                                              icon: Icon(Icons.send),
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    else {
                                      return CircularProgressIndicator();
                                    }

                                  }
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

// Courtesy of https://maxim-gorin.medium.com/advanced-flutter-ui-how-to-build-a-chat-app-with-custom-message-bubbles-4f90282b8be0
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isSentByMe;
  final String rcvTime;

  ChatBubble({required this.message, required this.isSentByMe, required this.rcvTime});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isSentByMe ? Color.fromRGBO(4, 150, 255, 1) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: isSentByMe ? Radius.circular(15) : Radius.zero,
            bottomRight: isSentByMe ? Radius.zero : Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
            ),
          ],
        ),
        child: ListTile(
          title: Text(
            message,
            style: TextStyle(
              color: isSentByMe ? Colors.white : Colors.black87,
            ),
            softWrap: true,  // Ensures line breaks are handled properly
          ),
          subtitle: Text(
            rcvTime,
            style: TextStyle(
              color: isSentByMe ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

