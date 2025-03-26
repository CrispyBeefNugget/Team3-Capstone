import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:dmaft/client_db.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {

  // Allows us to search in the appbar textfield.
  final TextEditingController _searchController = TextEditingController();

  // Allows us to access the client database, the contents of which are stored locally on device.
  final ClientDB database_service = ClientDB.instance;

  List<Contact> contact_list = [Contact(id: 'test', name: 'test', pronouns: 'test', bio: 'test', pic: Uint8List(10), lastModified: '2025-03-15')]; // Placeholder list. Will remove.
  List<Contact> _filteredList = [];
  late List<bool> _selected; // List is generated later once the contacts are loaded in.
  
  bool isSearchingMode = false;
  bool isSelectionMode = false;
  bool _selectAll = false;

  @override
  void initState() {
    get_contact_info().then((response) { // Initializes the lists used for displaying and filtering (searching) contacts.
      setState(() {
        contact_list = response;
      });
      initializeSelection();
      _filteredList = contact_list;
    });
    _searchController.addListener(_performSearch); // Adds a listener so that we can search contacts.
    super.initState();
  }

  // Gets the contacts from the client database.
  Future<List<Contact>> get_contact_info() async {
    var db_contacts = await database_service.getContacts();
    return db_contacts;
  }

  Future<void> delete_contact(Contact contact) async {
    await database_service.delContact(contact);
  }

  void refresh_contacts() {
    get_contact_info().then((response) { // Initializes the lists used for displaying and filtering (searching) contacts.
      setState(() {
        contact_list = response;
      });
      initializeSelection();
      _filteredList = contact_list;
    });
  }

  void initializeSelection() {
    _selected = List<bool>.generate(contact_list.length, (_) => false);
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

  // Toggles searching mode depending on if the user types in the text field.
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
            .contains(_searchController.text.toLowerCase()))
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
                              
                              for (int i = 0; i < contact_list.length; i++) {
                                if (_selected[i] == true) {
                                  delete_contact(contact_list[i]);
                                }
                              }
                              refresh_contacts();
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
                  itemCount: _filteredList.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: Icon(Icons.person),
                    title: Text(
                      _filteredList[index].name,
                      style: const TextStyle(color: Colors.black),
                    ),
                    onTap: () => {
                      
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: Text('Details'),
                            centerTitle: true,
                            backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
                            foregroundColor: Colors.white,
                            actions: [
                              IconButton(
                                onPressed: () {
                                  delete_contact(_filteredList[index]);
                                  refresh_contacts();
                                  Navigator.pop(context);
                                  _searchController.text = '';
                                },
                                icon: Icon(Icons.delete),
                              ),
                            ],
                        ),
                          body: Column( // Left off here 
                            children: [
                              Padding(
                                padding: EdgeInsets.all(10.0),
                              ),
                              Center(
                                child: CircleAvatar(
                                  backgroundImage: Image.memory(_filteredList[index].pic).image,
                                  radius: 100,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10.0),
                              ),

                              ListTile(
                                title: Text(_filteredList[index].name),
                                titleAlignment: ListTileTitleAlignment.center, // Not working. Might substitute listtiles for center or another widget.
                              ),
                              ListTile(
                                title: Text(_filteredList[index].id),
                                titleAlignment: ListTileTitleAlignment.center,
                              ),
                              ListTile(
                                title: Text(_filteredList[index].pronouns),
                                titleAlignment: ListTileTitleAlignment.center,
                              ),
                              ListTile(
                                title: Text(_filteredList[index].bio),
                                titleAlignment: ListTileTitleAlignment.center,
                              ),
                              ListTile(
                                title: Text(_filteredList[index].lastModified),
                                titleAlignment: ListTileTitleAlignment.center,
                              ),

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
                              title: Text('Details'),
                              centerTitle: true,
                              backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
                              foregroundColor: Colors.white,
                              actions: [
                                IconButton(
                                  onPressed: () {
                                    delete_contact(contact_list[index]);
                                    refresh_contacts();
                                    Navigator.pop(context);
                                  },
                                  icon: Icon(Icons.delete),
                                ),
                              ],
                            ),
                            body: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(10.0),
                                ),
                                Center(
                                  child: CircleAvatar(
                                    backgroundImage: Image.memory(contact_list[index].pic).image,
                                    radius: 100,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(10.0),
                                ),

                                ListTile(
                                  title: Text(contact_list[index].name),
                                  titleAlignment: ListTileTitleAlignment.center,
                                ),
                                ListTile(
                                  title: Text(contact_list[index].pronouns),
                                  titleAlignment: ListTileTitleAlignment.center,
                                ),
                                ListTile(
                                  title: Text(contact_list[index].bio),
                                  titleAlignment: ListTileTitleAlignment.center,
                                ),
                                ListTile(
                                  title: Text(contact_list[index].lastModified),
                                  titleAlignment: ListTileTitleAlignment.center,
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
                    title: Text(contact_list[index].name),

                  ),
                )





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
