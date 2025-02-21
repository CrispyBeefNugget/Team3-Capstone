import 'package:flutter/material.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SearchBar(
        padding: const WidgetStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 16.0),
        ),
        onTap: () {
          //controller.openView();
        },
        onChanged: (_) {
          //controller.openView();
        },
        onSubmitted: (query) {
          // Perform a search based on the query.
        },
        onTapOutside: (_) {

        },


        leading: const Icon(Icons.search),
        hintText: 'Search',
        shape: WidgetStatePropertyAll(
          BeveledRectangleBorder(),
        ),

      ),
    );
  }
}