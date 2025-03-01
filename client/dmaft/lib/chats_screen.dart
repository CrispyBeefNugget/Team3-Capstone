import 'package:dmaft/chat_test_list.dart';
import 'package:flutter/material.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {

  final TextEditingController _searchController = TextEditingController();

  List<String> testList = ChatTestList.getList();

  List<String> _filteredList = [];

  bool isSearchingMode = false;
  bool isSelectionMode = false;
  late List<bool> _selected;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    initializeSelection();
    _filteredList = testList;
    _searchController.addListener(_performSearch);
  }

  void initializeSelection() {
    //testList.sort();
    //testList.add('Test Test');
    _selected = List<bool>.generate(testList.length, (_) => false);
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
        _filteredList = testList
          .where((element) => element
            .toLowerCase()
            .startsWith(_searchController.text.toLowerCase()))
          .toList();
      }
      else {
        isSearchingMode = false;
        _filteredList = testList;
      }
      testList = ChatTestList.getList(); // Doesn't update in real-time. Have to change tabs to update.
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
                _filteredList[index],
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
            contactList: testList,
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
          title: Text(widget.contactList[index]),
        );
      },
    );
  }
}