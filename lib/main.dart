import 'package:blood_contacts/src/app/blood_contacts_app.dart';
import 'package:blood_contacts/src/features/contacts/data/background_sync_worker.dart';
import 'package:blood_contacts/src/features/contacts/data/google_drive_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GoogleDriveSyncService.initializeGoogleSignIn();
  await Workmanager().initialize(backgroundSyncCallbackDispatcher);
  runApp(const MyApp());
}

class MyApp extends BloodContactsApp {
  const MyApp({super.key, super.databaseFactory});
}
