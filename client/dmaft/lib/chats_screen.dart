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

  List<Conversation> chat_list = [];
  List<Conversation> _filteredList = [];
  late List<bool> _selected;

  // List<String> testList = ChatTestList.getList();

  bool isSearchingMode = false;
  bool isSelectionMode = false;
  bool _selectAll = false;

  @override
  void initState() {
    get_chat_info().then((response) {
      setState(() {
        chat_list = response;
      });
      initializeSelection();
      _filteredList = chat_list;
    });
    _searchController.addListener(_performSearch);
    super.initState();
  }

  Future<List<Conversation>> get_chat_info() async {
    var db_conversations = await database_service.getAllConvos();
    return db_conversations;
  }

  // String get_name_from_id(String ) {

  // }

  void initializeSelection() {
    _selected = List<bool>.generate(chat_list.length, (_) => false);
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
        _filteredList = chat_list
          .where((element) => element.convoMembers[1]
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()))
          .toList();
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
                          _selected = List<bool>.generate(chat_list.length, (_) => _selectAll);
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
                      _filteredList[index].convoMembers[1],
                      style: const TextStyle(color: Colors.black),
                    ),
                    onTap: () => {
                      
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: Text(_filteredList[index].convoMembers[1]),
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
                              title: Text(chat_list[index].convoMembers[1]),
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
                                  child: Text(chat_list[index].lastModified),
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
                    title: Text(chat_list[index].convoMembers[1])
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
