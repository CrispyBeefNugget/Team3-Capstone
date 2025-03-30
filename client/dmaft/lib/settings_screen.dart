import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:dmaft/client_db.dart';

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
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => UsernameScreen(user: user)), // Redirects to the widget that handles changing the user's username.
                    );
                  },
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Username'),
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
  bool saveChanges = false;

  @override
  void initState() {
    _usernameController.addListener(_detectUsername);
    _usernameController.text = widget.user.name;
    super.initState();
  }

  // Need to fix
  Future<void> _detectUsername() async {
    setState(() {
      print(saveChanges);
      if (saveChanges) {
        String newUsername = _usernameController.text;
        print(widget.user.name);
        widget.user.name = newUsername;
        print(widget.user.name);
        databaseService.modifyUser(widget.user);
        saveChanges = false;
      }
      if (_usernameController.text != widget.user.name) {

      }
    });
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

      // Replace with functionality that changes username
      body: Column(
        children: [
          TextField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            autofocus: true,
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              setState(() {
                saveChanges = true;
              });
            },
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
  bool saveChanges = false;

  @override
  void initState() {
    _bioController.addListener(_detectBio);
    _bioController.text = widget.user.bio;
    super.initState();
  }

  // Need to fix
  Future<void> _detectBio() async {
    setState(() {
      print(saveChanges);
      if (saveChanges) {
        String newBio = _bioController.text;
        print(widget.user.bio);
        widget.user.bio = newBio;
        print(widget.user.bio);
        databaseService.modifyUser(widget.user);
        saveChanges = false;
      }
      if (_bioController.text != widget.user.bio) {

      }
    });
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

      // Replace with functionality that changes bio
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
            onPressed: () {
              setState(() {
                saveChanges = true;
              });
            },
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
  bool saveChanges = false;

  @override
  void initState() {
    _pronounsController.addListener(_detectPronouns);
    _pronounsController.text = widget.user.pronouns;
    super.initState();
  }

  // Need to fix
  Future<void> _detectPronouns() async {
    setState(() {
      print(saveChanges);
      if (saveChanges) {
        String newPronouns = _pronounsController.text;
        print(widget.user.pronouns);
        widget.user.pronouns = newPronouns;
        print(widget.user.pronouns);
        databaseService.modifyUser(widget.user);
        saveChanges = false;
      }
      if (_pronounsController.text != widget.user.pronouns) {

      }
    });
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

      // Replace with functionality that changes pfp
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
            onPressed: () {
              setState(() {
                saveChanges = true;
                
              });
            },
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Message History'),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
        foregroundColor: Colors.white,
      ),

      // Replace with functionality that changes pfp
      body: Center(
        child: Text(widget.user.lastModified),
      ),

    );
  }
}