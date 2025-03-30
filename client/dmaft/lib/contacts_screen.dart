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
  final ClientDB databaseService = ClientDB.instance;

  List<Contact> contactList = [];
  List<Contact> _filteredList = [];
  late List<bool> _selected; // List is generated later once the contacts are loaded in.
  
  bool isSearchingMode = false;
  bool isSelectionMode = false;
  bool _selectAll = false;

  @override
  void initState() {
    getContactInfo().then((response) { // Initializes the lists used for displaying and filtering (searching) contacts.
      setState(() {
        contactList = response;
      });
      initializeSelection();
      _filteredList = contactList;
    });
    _searchController.addListener(_performSearch); // Adds a listener so that we can search contacts.
    super.initState();
  }

  // Gets the contacts from the client database.
  Future<List<Contact>> getContactInfo() async {
    var dbContacts = await databaseService.getContacts();
    return dbContacts;
  }

  // Refreshes the contacts screen. Currently bugged resulting in you having to either delete twice or switch tabs.
  void refreshContacts() {
    getContactInfo().then((response) { // Initializes the lists used for displaying and filtering (searching) contacts.
      setState(() {
        contactList = response;
      });
      initializeSelection();
      _filteredList = contactList;
    });
  }

  // Initializes a list of bools which is used to determine if a contact is selected.
  void initializeSelection() {
    _selected = List<bool>.generate(contactList.length, (_) => false);
  }

  // Toggles whether the specified contact by index is selected or not.
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
        _filteredList = contactList
          .where((element) => element.name
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()))
          .toList();
      }
      else {
        isSearchingMode = false;
        _filteredList = contactList;
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
        future: getContactInfo(),
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
                        
                        for (int i = 0; i < contactList.length; i++) {
                          if (_selected[i] == true) {
                            databaseService.delContact(contactList[i]);
                          }
                        }
                        refreshContacts();
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
                          _selected = List<bool>.generate(contactList.length, (_) => _selectAll);
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
                      
                      // Clicking on a contact opens a page containing more details.
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
                                  databaseService.delContact(_filteredList[index]);
                                  refreshContacts();
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
                          ),
                        )),
                      ),

                    },
                    
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
                                    databaseService.delContact(contactList[index]);
                                    refreshContacts();
                                    Navigator.pop(context);
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
                                    backgroundImage: Image.memory(contactList[index].pic).image,
                                    radius: 100,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(10.0),
                                ),

                                ListTile(
                                  title: Text(contactList[index].name),
                                  titleAlignment: ListTileTitleAlignment.center, // Not working. Might substitute listtiles for center or another widget.
                                ),
                                ListTile(
                                  title: Text(contactList[index].pronouns),
                                  titleAlignment: ListTileTitleAlignment.center,
                                ),
                                ListTile(
                                  title: Text(contactList[index].bio),
                                  titleAlignment: ListTileTitleAlignment.center,
                                ),
                                ListTile(
                                  title: Text(contactList[index].lastModified),
                                  titleAlignment: ListTileTitleAlignment.center,
                                ),

                              ],
                            )
                          ))

                        )
                      }
                    },

                    onLongPress: () { // Selection mode is enabled if a user holds on a contact.
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
                    title: Text(contactList[index].name),

                  ),
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
