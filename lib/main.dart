import 'package:blood_contacts/src/app/blood_contacts_app.dart';
import 'package:blood_contacts/src/features/contacts/data/google_drive_sync_service.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GoogleDriveSyncService.initializeGoogleSignIn();
  runApp(const MyApp());
}

class MyApp extends BloodContactsApp {
  const MyApp({super.key, super.databaseFactory});
}
