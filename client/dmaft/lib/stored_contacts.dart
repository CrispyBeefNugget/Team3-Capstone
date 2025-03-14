import 'dart:io';
import 'dart:typed_data';
import 'package:dmaft/contact_db.dart';


void main() async {

  Contact test = Contact(id: 'datboi', name: 'John', status: 'Dying inside', bio: 'Comp Sci Dummy', pic: File('test.png').readAsBytesSync());

  final ContactDB database_service = ContactDB.instance;

  database_service.addContact(test);

  List<Contact> contact_list = await database_service.getContacts();

  

  for (int i = 0; i < contact_list.length; i++) {
    print(contact_list[i]);
  }


}
