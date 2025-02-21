import 'package:flutter/material.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {

  List<String> testList = [
    'Dallin Parry',
    'Kacey Tharp',
    'Cameron Beaty',
    'Azaria Hundley',
    'Arthur Ayala',
    'Annette Stallings',
    'Axel Eller',
    'Demarcus Archuleta',
    'Jett Cotter',
    'Margo Truong',
    'Hezekiah Callaway',
    'Marquis Whiting',
    'Rayna Burleson',
    'Giovanna Pritchett',
    'Ajay Seidel',
    'Niya Reeves',
    'Alexus Jeter',
    'Halle Andrew',
    'Keith Levin',
    'Carol Hargrove',
  ];

  bool isSelectionMode = false;
  late List<bool> _selected;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    initializeSelection();
  }

  void initializeSelection() {
    _selected = List<bool>.generate(testList.length, (_) => false);
  }

  @override
  void dispose() {
    _selected.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            TextButton(
              child:
                !_selectAll
                  ? const Text('select all', style: TextStyle(color: Colors.black))
                  : const Text('unselect all', style: TextStyle(color: Colors.black)),
              onPressed: () {
                _selectAll = !_selectAll;
                setState(() {
                  _selected = List<bool>.generate(testList.length, (_) => _selectAll);
                });
              },
            ),
        ],
      ),

      body: ListBuilder(
        contactList: testList,
        isSelectionMode: isSelectionMode,
        selectedList: _selected,
        onSelectionChange: (bool x) {
          setState(() {
            isSelectionMode = x;
          });
        },
      ),

      // body: SearchBar(
      //   //builder: (BuildContext context, SearchController controller) {
      //     //return SearchBar(
      //       //controller: controller,
      //       padding: const WidgetStatePropertyAll<EdgeInsets>(
      //         EdgeInsets.symmetric(horizontal: 16.0),
      //       ),
      //       onTap: () {
      //         //controller.openView();
      //       },
      //       onChanged: (_) {
      //         //controller.openView();
      //       },
      //       onSubmitted: (query) {
      //         // Perform a search based on the query.
      //       },
      //       onTapOutside: (_) {

      //       },


      //       leading: const Icon(Icons.search),
      //       hintText: 'Search',
      //       shape: WidgetStatePropertyAll(
      //         BeveledRectangleBorder(),
      //       ),
      //     //);
      //   //},
      //   //suggestionsBuilder: (BuildContext context, SearchController controller) {
      //   //  return List<ListTile>.empty();
      //   //},
      // ),




    );
  }
}

class ListBuilder extends StatefulWidget {
  const ListBuilder({
    super.key,
    required this.contactList,
    required this.selectedList,
    required this.isSelectionMode,
    required this.onSelectionChange,
  });

  final List<String> contactList;
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
          title: Text(widget.contactList[index]),
        );
      },
    );
  }
}