import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:dmaft/client_db.dart';
import 'package:dmaft/client_file_access.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final ClientDB databaseService = ClientDB.instance;

  late Contact user;

  @override
  void initState() {
    getUser().then((response) {
      setState(() {
        user = response;
      });
    });
    super.initState();
  }

  // Gets the current user from the client database.
  Future<Contact> getUser() async {
    var currentUser = await databaseService.getUser();
    return currentUser;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: FutureBuilder(
        future: getUser(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {

          if (snapshot.hasData) {
            return ListView(
              children: [

                ListTile(
                  leading: Icon(Icons.perm_identity_rounded),
                  title: Text('UserID'),
                  subtitle: Text(user.id), // Shows the user's ID.
                ),

                ListTile(
                  leading: Icon(Icons.account_circle_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => PFPScreen(user: user)), // Redirects to the widget that handles changing a profile picture.
                    );
                  },
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Profile Picture'),
                ),

                ListTile(
                  leading: Icon(Icons.alternate_email_outlined),
                  onTap: () {
                    Navigator.of(context)
                    .push(
                      MaterialPageRoute(builder: (context) => UsernameScreen(user: user)), // Redirects to the widget that handles changing the user's username.
                    )
                    .then((_) {

                    });
                  },
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Username'),
                  subtitle: Text(user.name),
                ),

                ListTile(
                  leading: Icon(Icons.description_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => BioScreen(user: user)), // Redirects to the widget that handles changing the user's bio.
                    );
                  },
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Bio'),
                  subtitle: Text(user.bio),
                ),

                ListTile(
                  leading: Icon(Icons.contact_emergency_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => PronounsScreen(user: user)), // Redirects to the widget that handles changing the user's pronouns.
                    );
                  },
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Pronouns'),
                  subtitle: Text(user.pronouns),
                ),

                ListTile(
                  leading: Icon(Icons.manage_history_sharp),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => MessageHistoryScreen(user: user)), // Redirects to the widget that handles deleting older messages.
                    );
                  },
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Message History'),
                ),

              ],
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

class PFPScreen extends StatefulWidget {
  const PFPScreen({
    super.key,
    required this.user,
  });

  final Contact user;

  @override
  State<PFPScreen> createState() => _PFPScreenState();
}

class _PFPScreenState extends State<PFPScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Picture'),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
        foregroundColor: Colors.white,
      ),

      // Replace with functionality that changes pfp
      body: Column(
        children: [
          Center(
            child: CircleAvatar(
              backgroundImage: Image.memory(widget.user.pic).image,
            ),
          ),
        ],
      ),

    );
  }
}

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({
    super.key,
    required this.user,
  });

  final Contact user;

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {

  final TextEditingController _usernameController = TextEditingController();
  final ClientDB databaseService = ClientDB.instance;

  @override
  void initState() {
    _usernameController.text = widget.user.name;
    super.initState();
  }

  void changeUsername(String newUsername) {
    widget.user.name = newUsername;
    databaseService.modifyUser(widget.user);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Username'),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          TextField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.black),
            cursorColor: Colors.black,
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () => changeUsername(_usernameController.text),
          ),
        ],
      ),

    );
  }
}

class BioScreen extends StatefulWidget {
  const BioScreen({
    super.key,
    required this.user,
  });

  final Contact user;

  @override
  State<BioScreen> createState() => _BioScreenState();
}

class _BioScreenState extends State<BioScreen> {

  final TextEditingController _bioController = TextEditingController();
  final ClientDB databaseService = ClientDB.instance;

  @override
  void initState() {
    _bioController.text = widget.user.bio;
    super.initState();
  }

  void changeBio(String newBio) {
    widget.user.bio = newBio;
    databaseService.modifyUser(widget.user);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bio'),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          TextField(
            controller: _bioController,
            style: const TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            autofocus: true,
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () => changeBio(_bioController.text),
          ),
        ],
      ),

    );
  }
}

class PronounsScreen extends StatefulWidget {
  const PronounsScreen({
    super.key,
    required this.user,
  });

  final Contact user;

  @override
  State<PronounsScreen> createState() => _PronounsScreenState();
}

class _PronounsScreenState extends State<PronounsScreen> {

  final TextEditingController _pronounsController = TextEditingController();
  final ClientDB databaseService = ClientDB.instance;

  @override
  void initState() {
    _pronounsController.text = widget.user.pronouns;
    super.initState();
  }

  void changePronouns(String newPronouns) {
    widget.user.pronouns = newPronouns;
    databaseService.modifyUser(widget.user);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pronouns'),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          TextField(
            controller: _pronounsController,
            style: const TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            autofocus: true,
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () => changePronouns(_pronounsController.text),
          ),
        ],
      ),

    );
  }
}

class MessageHistoryScreen extends StatefulWidget {
  const MessageHistoryScreen({
    super.key,
    required this.user,
  });

  final Contact user;

  @override
  State<MessageHistoryScreen> createState() => _MessageHistoryScreenState();
}

class _MessageHistoryScreenState extends State<MessageHistoryScreen> {
  final FileAccess fileService = FileAccess.instance;
  
  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Message History'),
          centerTitle: true,
          backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
          foregroundColor: Colors.white,
        ),

        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //Message history info text box
              Container(
                width: 500,
                decoration: BoxDecoration(
                  border: Border.all(),
                ),
                child: Text(
                  "If message history control is disabled, messages will be stored indefinitely until manually deleted.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
              //Message history text field
              FutureBuilder(
                future: fileService.getSettings(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    return TextFormField(
                      decoration: InputDecoration(
                        icon: Icon(Icons.calendar_month),
                      ),
                      initialValue: snapshot.data["messageHistory"], 
                      style: TextStyle(
                        fontSize: 20,
                      ),
                      
                    );
                  }
                  else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }
              ), 
            ], //Column children
          ),
        ),
      );
  }
}