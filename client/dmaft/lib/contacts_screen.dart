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

  List<Contact> ?contact_list = []; // This works.

  // List<String> testList = [
  //   'Dallin Parry',
  //   'Kacey Tharp',
  //   'Cameron Beaty',
  //   'Azaria Hundley',
  //   'Arthur Ayala',
  //   'Annette Stallings',
  //   'Axel Eller',
  //   'Demarcus Archuleta',
  //   'Jett Cotter',
  //   'Margo Truong',
  //   'Hezekiah Callaway',
  //   'Marquis Whiting',
  //   'Rayna Burleson',
  //   'Giovanna Pritchett',
  //   'Ajay Seidel',
  //   'Niya Reeves',
  //   'Alexus Jeter',
  //   'Halle Andrew',
  //   'Keith Levin',
  //   'Carol Hargrove',
  // ];

  List<Contact> _filteredList = [];

  bool isSearchingMode = false;
  bool isSelectionMode = false;
  late List<bool> _selected;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    get_contact_info();
    initializeSelection();
    print('Contact List:');
    
    print(contact_list);

    
    _searchController.addListener(_performSearch);

    
  }

  void get_contact_info() async {

    contact_list = await database_service.getContacts(); // For some reason the contact list is not updating here.
    _filteredList = contact_list!;

  }

  void initializeSelection() { // COME BACK HERE
    // testList.sort();
    // testList.add('Test Test');
    if (contact_list == Null) {
      get_contact_info();
    }
    _selected = List<bool>.generate(contact_list!.length, (_) => false);
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
        _filteredList = contact_list!
          .where((element) => element.name
            .toLowerCase()
            .startsWith(_searchController.text.toLowerCase()))
          .toList();
      }
      else {
        isSearchingMode = false;
        _filteredList = contact_list!;
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

      body: Scaffold(
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
                    _selected = List<bool>.generate(contact_list!.length, (_) => _selectAll);
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
            itemCount: _filteredList!.length,
            itemBuilder: (context, index) => ListTile(
              leading: Icon(Icons.person),
              title: Text(
                _filteredList[index].name,
                style: const TextStyle(color: Colors.black),
              ),
              onTap: () => {
                if (isSelectionMode) {

                }
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
            UIcontactList: contact_list!,
            isSelectionMode: isSelectionMode,
            selectedList: _selected,
            onSelectionChange: (bool x) {
              setState(() {
                isSelectionMode = x;
              });
            },
          ),
      ),
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
    if (widget.isSelectionMode) {
      setState(() {
        widget.selectedList[index] = !widget.selectedList[index];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.selectedList.length,
      itemBuilder: (_, int index) {
        return ListTile(
          leading: Icon(Icons.person),
          onTap: () => _toggle(index),
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