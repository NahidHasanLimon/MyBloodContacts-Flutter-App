import 'package:blood_contacts/src/app/app_theme.dart';
import 'package:blood_contacts/src/features/contacts/presentation/pages/blood_contacts_home.dart';
import 'package:flutter/material.dart';

class BloodContactsApp extends StatelessWidget {
  const BloodContactsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blood Contacts',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) {
        return ColoredBox(
          color: const Color(0xfff3f0ee),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      home: const BloodContactsHome(),
    );
  }
}
