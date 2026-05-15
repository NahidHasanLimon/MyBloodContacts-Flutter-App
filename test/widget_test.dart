import 'dart:convert';
import 'dart:typed_data';

import 'package:blood_contacts/main.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  test('keeps contact photo bytes through json persistence', () {
    final bytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
    final contact = BloodContact(
      id: 'photo-contact',
      name: 'Photo Donor',
      phone: '01700000000',
      photoBase64: base64Encode(bytes),
      bloodGroup: 'A+',
      availability: DonorAvailability.available,
      updatedAt: DateTime(2026),
    );

    final restored = BloodContact.fromJson(contact.toJson());

    expect(restored.photoBytes, bytes);
  });

  test('normalizes phone numbers for duplicate checks', () {
    expect(normalizedPhoneNumber('+880 1700-000000'), '01700000000');
    expect(normalizedPhoneNumber('008801700000000'), '01700000000');
    expect(normalizedPhoneNumber('01700 000 000'), '01700000000');
  });

  testWidgets('renders quick overview home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MyApp(databaseFactory: databaseFactoryFfiNoIsolate),
    );
    final exception = tester.takeException();
    expect(exception, isNull);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpUntilFound(find.text('Need blood urgently?'));

    expect(find.textContaining('Good'), findsOneWidget);
    expect(find.text('Need blood urgently?'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Find Donors by Blood Group'),
      160,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Find Donors by Blood Group'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Quick Actions'),
      160,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('New Need'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();

    expect(find.text('Contacts'), findsWidgets);
    expect(find.text('Find and connect with blood donors.'), findsOneWidget);
    expect(find.text('Total contacts'), findsNothing);
    expect(find.text('Total Donors'), findsOneWidget);
    expect(find.text('Available Now'), findsOneWidget);
    expect(find.text('Status'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('No contacts match'),
      160,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('No contacts match'), findsOneWidget);

    await tester.tap(find.text('Needs'));
    await tester.pumpAndSettle();

    expect(
      find.text('Browse blood requests and help save lives.'),
      findsOneWidget,
    );
    expect(find.text('Blood Group').hitTestable(), findsNothing);
    expect(find.text('Urgency').hitTestable(), findsNothing);
    expect(find.text('Status').hitTestable(), findsNothing);

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();

    expect(find.text('Blood Group'), findsOneWidget);
    expect(find.text('Urgency'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
  });
}

extension _WidgetTesterWaits on WidgetTester {
  Future<void> pumpUntilFound(Finder finder) async {
    for (var i = 0; i < 40; i++) {
      await pump(const Duration(milliseconds: 100));
      if (any(finder)) return;
    }
    final visibleText = widgetList<Text>(
      find.byType(Text),
    ).map((widget) => widget.data).whereType<String>().join(', ');
    throw TestFailure(
      'Timed out waiting for $finder. Visible text: $visibleText',
    );
  }
}
