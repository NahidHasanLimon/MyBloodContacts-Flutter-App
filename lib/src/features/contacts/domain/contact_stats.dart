import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';

class ContactStats {
  const ContactStats({
    required this.total,
    required this.available,
    required this.nearby,
    required this.groupCounts,
  });

  final int total;
  final int available;
  final int nearby;
  final Map<String, int> groupCounts;

  factory ContactStats.fromContacts(List<BloodContact> contacts) {
    return ContactStats(
      total: contacts.length,
      available: contacts.where((contact) => contact.isAvailable).length,
      nearby: contacts.where((contact) => contact.isNearby).length,
      groupCounts: {
        for (final group in bloodGroups)
          group: contacts
              .where((contact) => contact.bloodGroup == group)
              .length,
      },
    );
  }
}
