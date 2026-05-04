import 'package:blood_contacts/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders quick overview home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('My Blood Contacts'), findsOneWidget);
    expect(find.text('Need blood?'), findsOneWidget);
    expect(find.text('At a glance'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Quick filters'),
      160,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Quick filters'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('No contacts found'),
      160,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('No contacts found'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();

    expect(find.text('Contacts'), findsWidgets);
    expect(find.text('All your important contacts'), findsOneWidget);
    expect(find.text('Total contacts'), findsOneWidget);
    expect(find.text('Blood group'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Available'), findsWidgets);
    expect(find.text('Nearby'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('No contacts match'),
      160,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('No contacts match'), findsOneWidget);
  });
}
