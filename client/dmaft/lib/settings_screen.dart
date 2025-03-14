import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.alternate_email_outlined),
            title: Text('UserID'),
            subtitle: Text('Placeholder'),
          ),
          ListTile(
            leading: Icon(Icons.account_circle_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PFPScreen()),
              );
            },
            trailing: Icon(Icons.arrow_forward_ios),
            title: Text('Profile Picture'),
          ),
          ListTile(
            leading: Icon(Icons.alternate_email_outlined),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const UsernameScreen()),
              );
            },
            trailing: Icon(Icons.arrow_forward_ios),
            title: Text('Username'),
          ),
          ListTile(
            leading: Icon(Icons.description_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BioScreen()),
              );
            },
            trailing: Icon(Icons.arrow_forward_ios),
            title: Text('Bio'),
          ),
          ListTile(
            leading: Icon(Icons.contact_emergency_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PronounsScreen()),
              );
            },
            trailing: Icon(Icons.arrow_forward_ios),
            title: Text('Pronouns'),
          ),
          ListTile(
            leading: Icon(Icons.manage_history_sharp),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MessageHistoryScreen()),
              );
            },
            trailing: Icon(Icons.arrow_forward_ios),
            title: Text('Message History'),
          ),
        ],
      ),

    );
  }
}

class PFPScreen extends StatefulWidget {
  const PFPScreen({super.key});

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
      body: Center(
        child: Text('This is a test!'),
      ),

    );
  }
}

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

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
        child: Text('This is a test!'),
      ),

    );
  }
}

class BioScreen extends StatefulWidget {
  const BioScreen({super.key});

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
        child: Text('This is a test!'),
      ),

    );
  }
}

class PronounsScreen extends StatefulWidget {
  const PronounsScreen({super.key});

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
        child: Text('This is a test!'),
      ),

    );
  }
}

class MessageHistoryScreen extends StatefulWidget {
  const MessageHistoryScreen({super.key});

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
        child: Text('This is a test!'),
      ),

    );
  }
}