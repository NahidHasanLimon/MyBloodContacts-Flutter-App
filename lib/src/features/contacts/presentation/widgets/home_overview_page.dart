import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_stats.dart';
import 'package:blood_contacts/src/features/contacts/presentation/widgets/home_widgets.dart';
import 'package:flutter/material.dart';

class HomeOverviewPage extends StatelessWidget {
  const HomeOverviewPage({
    super.key,
    required this.stats,
    required this.visibleContacts,
    required this.hasMoreContacts,
    required this.selectedBloodGroup,
    required this.selectedFilter,
    required this.driveFolder,
    required this.onAdd,
    required this.onImport,
    required this.onDriveFolder,
    required this.onBloodGroupSelected,
    required this.onFilterChanged,
    required this.onViewAll,
    required this.onEditContact,
    required this.onDeleteContact,
  });

  final ContactStats stats;
  final List<BloodContact> visibleContacts;
  final bool hasMoreContacts;
  final String? selectedBloodGroup;
  final ContactFilter selectedFilter;
  final String? driveFolder;
  final VoidCallback onAdd;
  final VoidCallback onImport;
  final VoidCallback onDriveFolder;
  final ValueChanged<String> onBloodGroupSelected;
  final ValueChanged<ContactFilter> onFilterChanged;
  final VoidCallback onViewAll;
  final ValueChanged<BloodContact> onEditContact;
  final ValueChanged<BloodContact> onDeleteContact;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 98),
        children: [
          HomeHeader(onAdd: onAdd),
          const SizedBox(height: 22),
          NeedBloodCard(onTap: onImport),
          const SizedBox(height: 22),
          const SectionHeader(title: 'At a glance'),
          const SizedBox(height: 10),
          BloodGroupGrid(
            counts: stats.groupCounts,
            selectedGroup: selectedBloodGroup,
            onSelected: onBloodGroupSelected,
          ),
          const SizedBox(height: 12),
          TotalContactsCard(
            count: stats.total,
            driveFolder: driveFolder,
            onTap: onDriveFolder,
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Quick filters'),
          const SizedBox(height: 10),
          QuickFilterBar(
            stats: stats,
            selectedFilter: selectedFilter,
            onChanged: onFilterChanged,
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Recent contacts',
            actionLabel: hasMoreContacts ? 'View all' : null,
            onAction: onViewAll,
          ),
          const SizedBox(height: 8),
          if (visibleContacts.isEmpty)
            const EmptyRecentContacts()
          else
            ...visibleContacts.map(
              (contact) => RecentContactTile(
                contact: contact,
                onTap: () => onEditContact(contact),
                onDelete: () => onDeleteContact(contact),
              ),
            ),
        ],
      ),
    );
  }
}
