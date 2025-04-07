import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:dmaft/client_db.dart';
import 'package:dmaft/client_file_access.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final ClientDB databaseService = ClientDB.instance;

  final FileAccess fileService = FileAccess.instance;

  late Contact user;

  late Map<String, dynamic> settings;

  @override
  void initState() {
    getUser().then((response) {
      setState(() {
        user = response;
      });
    });
    getSettings().then((response) {
      setState(() {
        settings = response;
      });
    });
    super.initState();
  }

  // Gets the current user from the client database.
  Future<Contact> getUser() async {
    var currentUser = await databaseService.getUser();
    return currentUser;
  }

  //Gets the current settings state from the client's settings file.
  Future<Map<String, dynamic>> getSettings() async{
    var currentSettings = await fileService.getSettings();
    return currentSettings;
  }

  // Converts the Future of the current user to a Stream. This allows for refreshing the page after a change is made by the user.
  Stream refreshPage() {
    return Stream.fromFuture(getUser());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: StreamBuilder(
        stream: refreshPage(),
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
                    Navigator.of(context)
                    .push(
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
                      setState(() {
                        refreshPage();
                      });
                    });
                  },
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Username'),
                  subtitle: Text(user.name),
                ),

                ListTile(
                  leading: Icon(Icons.description_rounded),
                  onTap: () {
                    Navigator.of(context)
                    .push(
                      MaterialPageRoute(builder: (context) => BioScreen(user: user)), // Redirects to the widget that handles changing the user's bio.
                    )
                    .then((_) {
                      setState(() {
                        refreshPage();
                      });
                    });
                  },
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Bio'),
                  subtitle: Text(user.bio),
                ),

                ListTile(
                  leading: Icon(Icons.contact_emergency_rounded),
                  onTap: () {
                    Navigator.of(context)
                    .push(
                      MaterialPageRoute(builder: (context) => PronounsScreen(user: user)), // Redirects to the widget that handles changing the user's pronouns.
                    )
                    .then((_) {
                      setState(() {
                        refreshPage();
                      });
                    });
                  },
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Pronouns'),
                  subtitle: Text(user.pronouns),
                ),

                ListTile(
                  leading: Icon(Icons.manage_history_sharp),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => MessageHistoryScreen(settings: settings)), // Redirects to the widget that handles deleting older messages.
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

        },
      ),

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
  final ClientDB databaseService = ClientDB.instance;
  
  void changeProfilePic(Uint8List newPic) {
      widget.user.pic = newPic;
      databaseService.modifyUser(widget.user);
      Navigator.pop(context);
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Picture'),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(4, 150, 255, 1),
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          //Display current profile pic.
          Center(
            child: CircleAvatar(
              backgroundImage: Image.memory(widget.user.pic).image,
              radius: 200,
            ),
          ),

          //Small divider.
          Divider(
            color: Colors.black,
            height: 20,
          ),

          //Profile picture updating row.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Update profile picture text.
              Flexible(
                child: Text(
                  "Update profile picture: ",
                  style: TextStyle(
                    fontSize: 20,
                  )
                ),
              ),

              //Upload icon.
              Flexible(
                child: SizedBox( 
                  width: 100,
                  child: IconButton(
                    onPressed: () async {      
                      //Fetch a specified file from the user.
                      final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png']);
                      if(result == null) return;
                      final PlatformFile file = result.files.first;
                      //Update the user's data.
                      changeProfilePic(file.bytes!);

                    },
                    icon: Icon(Icons.upload),
                  ),
                ),
              ),
            ],
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
    required this.settings,
    });

  final Map<String, dynamic> settings;

  @override
  State<MessageHistoryScreen> createState() => _MessageHistoryScreenState();
}

class _MessageHistoryScreenState extends State<MessageHistoryScreen> {
  final TextEditingController _historyController = TextEditingController();
  final FileAccess fileService = FileAccess.instance;

  @override
  void initState() {
    _historyController.text = widget.settings["historyDuration"].toString();
    super.initState();
  }

 void changeHistoryControl(bool newValue) {
    widget.settings["deleteHistory"] = newValue;
    fileService.writeSettings(widget.settings);
  }

  void changeHistoryDuration(String newValue) {
    //Validate the input.
    if(int.tryParse(newValue) != null && int.tryParse(newValue)! >= 1 ){
      //Update the settings file.
      widget.settings["historyDuration"] = int.tryParse(newValue);
      fileService.writeSettings(widget.settings);
    }
    Navigator.pop(context);
  }

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
            //Automatic message history control switch.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  child: Text(
                    style: TextStyle(fontSize: 20),
                    "Enable Automatic History Management:",
                    textAlign: TextAlign.center,
                  ),
                  
                ),
                Flexible(
                  child: Switch(
                    value: widget.settings["deleteHistory"],
                    activeColor: Colors.blue,
                    onChanged: (bool value) {
                      setState(() {
                        changeHistoryControl(value);
                      });
                    },
                  ),
                ),
              ],
            ),

            //Small divider between history settings.
            Divider(
              color: Colors.black,
              height: 20,
            ),

            //Message history text field
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  flex: 2,
                  child: Text(
                    style: TextStyle(fontSize: 20),
                    "Keep messages for "
                  ),
                ),
                Flexible(
                  child: TextFormField(
                    controller: _historyController,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    style: TextStyle(fontSize: 20),
                    " days"
                  ),
                ),
              ],
            ),

            TextButton(
              child: Text('Save Duration'),
              onPressed: () => changeHistoryDuration(_historyController.text),
            ),

            //Information message below day input field.
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text(
                  "Messages older than this will automatically be deleted each time Peregrine is opened.",
                  style: TextStyle(
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          ], //Column children
        ),
      ),
    );
  }
}