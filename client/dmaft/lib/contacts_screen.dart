import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:dmaft/client_db.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {

  final TextEditingController _searchController = TextEditingController();

  final ClientDB database_service = ClientDB.instance;

  List<Contact> contact_list = [Contact(id: 'test', name: 'test', status: 'test', bio: 'test', pic: Uint8List(10))]; // This works.

  List<Contact> _filteredList = [];

  bool isSearchingMode = false;
  bool isSelectionMode = false;
  late List<bool> _selected;
  bool _selectAll = false;

  @override
  void initState() {
    // super.initState();

    get_contact_info().then((response) {
      setState(() {
        contact_list = response;
      });
      initializeSelection();
      _filteredList = contact_list;

      print('Contact List in setState():');
      print(contact_list);

    });

    print('Contact List outside setState():');
    print(contact_list);

    
    _searchController.addListener(_performSearch);

    super.initState();
  }

  Future<List<Contact>> get_contact_info() async {
    var db_contacts = await database_service.getContacts(); // For some reason the contact list is not updating here.
    return db_contacts;
  }

  void initializeSelection() { // COME BACK HERE
    _selected = List<bool>.generate(contact_list.length, (_) => false);
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
        _filteredList = contact_list
          .where((element) => element.name
            .toLowerCase()
            .startsWith(_searchController.text.toLowerCase()))
          .toList();
      }
      else {
        isSearchingMode = false;
        _filteredList = contact_list;
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
            hintText: 'Search Contacts',
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
        future: get_contact_info(),
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
                              // Insert delete function here
                              print(_selected);

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
                                _selected = List<bool>.generate(contact_list.length, (_) => _selectAll);
                              });
                            },
                          ),
                      ],
                      toolbarHeight: isSelectionMode ? 50 : 0,
              ),

              body:
                isSearchingMode
                ? ListView.builder(
                  itemCount: _filteredList!.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: Icon(Icons.person),
                    title: Text(
                      _filteredList[index].name,
                      style: const TextStyle(color: Colors.black),
                    ),
                    onTap: () => {

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
                : ListBuilder(
                  UIcontactList: contact_list,
                  isSelectionMode: isSelectionMode,
                  selectedList: _selected,
                  onSelectionChange: (bool x) {
                    setState(() {
                      isSelectionMode = x;
                    });
                  },
                ),
            );
          }
          else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        }
      )
      
      
    );
  }
}

class ListBuilder extends StatefulWidget {
  const ListBuilder({
    super.key,
    required this.UIcontactList,
    required this.selectedList,
    required this.isSelectionMode,
    required this.onSelectionChange,
  });

  final List<Contact> UIcontactList;
  final bool isSelectionMode;
  final List<bool> selectedList;
  final ValueChanged<bool>? onSelectionChange;

  @override
  State<ListBuilder> createState() => _ListBuilderState();
}

class _ListBuilderState extends State<ListBuilder> {
  void _toggle(int index) {
    setState(() {
      widget.selectedList[index] = !widget.selectedList[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.selectedList.length,
      itemBuilder: (_, int index) {
        return ListTile(
          leading: Icon(Icons.person),
          onTap: () => {
            if (widget.isSelectionMode) {
              _toggle(index)
            }
            else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('Details'),
                    centerTitle: true,
                    backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
                    foregroundColor: Colors.white,
                  ),
                  body: Column( // Left off here 
                    children: [
                      Padding(
                        padding: EdgeInsets.all(10.0),
                      ),
                      Center(
                        child: CircleAvatar(
                          backgroundImage: Image.memory(widget.UIcontactList[index].pic).image,
                          radius: 100,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10.0),
                      ),

                      ListTile(
                        title: Text(widget.UIcontactList[index].name),
                        onTap: () => {

                        },
                      ),
                      ListTile(
                        title: Text(widget.UIcontactList[index].id),
                      ),

                      
                    ],
                  )
                ))
              )
            }
          },
          onLongPress: () {
            if (!widget.isSelectionMode) {
              setState(() {
                widget.selectedList[index] = true;
              });
              widget.onSelectionChange!(true);
            }
          },
          trailing:
            widget.isSelectionMode
              ? Checkbox(
                value: widget.selectedList[index],
                onChanged: (bool? x) => _toggle(index),
              )
              : const SizedBox.shrink(),
          title: Text(widget.UIcontactList[index].name),
        );
      },
    );
  }
}