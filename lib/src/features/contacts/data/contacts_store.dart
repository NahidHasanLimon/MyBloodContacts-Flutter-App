import 'dart:convert';

import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsStore {
  ContactsStore(this._prefs);

  static const _contactsKey = 'blood_contacts.contacts';
  static const _driveFolderKey = 'blood_contacts.drive_folder';

  final SharedPreferences _prefs;

  List<BloodContact> loadContacts() {
    final rawContacts = _prefs.getStringList(_contactsKey) ?? [];
    return rawContacts
        .map((contact) => BloodContact.fromJson(jsonDecode(contact)))
        .toList()
      ..sort(sortContacts);
  }

  Future<void> saveContacts(List<BloodContact> contacts) {
    final encoded = contacts.map((contact) => jsonEncode(contact.toJson()));
    return _prefs.setStringList(_contactsKey, encoded.toList());
  }

  String? loadDriveFolder() => _prefs.getString(_driveFolderKey);

  Future<void> saveDriveFolder(String folderName) {
    return _prefs.setString(_driveFolderKey, folderName);
  }
}
