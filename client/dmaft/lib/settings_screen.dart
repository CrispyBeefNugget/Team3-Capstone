import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:dmaft/client_db.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final ClientDB database_service = ClientDB.instance;

  late Contact user;

  @override
  void initState() {
    get_user().then((response) {
      setState(() {
        user = response;
      });
    });
    super.initState();
  }

  Future<Contact> get_user() async {
    var current_user = await database_service.getUser();
    return current_user;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: get_user(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.alternate_email_outlined),
                  title: Text('UserID'),
                  subtitle: Text(user.id),
                ),
                ListTile(
                  leading: Icon(Icons.account_circle_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => PFPScreen(user: user)),
                    );
                  },
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Profile Picture'),
                ),
                ListTile(
                  leading: Icon(Icons.alternate_email_outlined),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => UsernameScreen(user: user)),
                    );
                  },
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Username'),
                ),
                ListTile(
                  leading: Icon(Icons.description_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => BioScreen(user: user)),
                    );
                  },
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Bio'),
                ),
                ListTile(
                  leading: Icon(Icons.contact_emergency_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => PronounsScreen(user: user)),
                    );
                  },
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Pronouns'),
                ),
                ListTile(
                  leading: Icon(Icons.manage_history_sharp),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => MessageHistoryScreen(user: user)),
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
      body: Center(
        child: Text(widget.user.name),
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
      body: Center(
        child: Text(widget.user.bio),
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
      body: Center(
        child: Text(widget.user.pronouns),
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