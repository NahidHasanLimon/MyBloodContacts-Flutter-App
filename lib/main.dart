import 'package:blood_contacts/src/app/blood_contacts_app.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends BloodContactsApp {
  const MyApp({super.key, super.databaseFactory});
}
