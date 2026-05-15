import 'package:blood_contacts/src/features/contacts/domain/blood_need_request.dart';
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
    required this.openNeedsCount,
    required this.completedNeedsCount,
    required this.driveFolder,
    required this.onAdd,
    required this.onNeed,
    required this.onDriveFolder,
    required this.onBloodGroupSelected,
    required this.onFilterChanged,
    required this.onViewAll,
    required this.onAvailableContacts,
    required this.onOpenNeeds,
    required this.onCompletedNeeds,
    required this.recentNeeds,
    required this.onOpenRecentNeed,
    required this.onViewAllNeeds,
    required this.onNotifications,
    required this.notificationCount,
    required this.onEditContact,
    required this.onDeleteContact,
  });

  final ContactStats stats;
  final List<BloodContact> visibleContacts;
  final bool hasMoreContacts;
  final String? selectedBloodGroup;
  final ContactFilter selectedFilter;
  final int openNeedsCount;
  final int completedNeedsCount;
  final String? driveFolder;
  final VoidCallback onAdd;
  final VoidCallback onNeed;
  final VoidCallback onDriveFolder;
  final ValueChanged<String> onBloodGroupSelected;
  final ValueChanged<ContactFilter> onFilterChanged;
  final VoidCallback onViewAll;
  final VoidCallback onAvailableContacts;
  final VoidCallback onOpenNeeds;
  final VoidCallback onCompletedNeeds;
  final List<BloodNeedRequest> recentNeeds;
  final ValueChanged<BloodNeedRequest> onOpenRecentNeed;
  final VoidCallback onViewAllNeeds;
  final VoidCallback onNotifications;
  final int notificationCount;
  final ValueChanged<BloodContact> onEditContact;
  final ValueChanged<BloodContact> onDeleteContact;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            HomeHeroHeader(
              onNeed: onNeed,
              onNotifications: onNotifications,
              notificationCount: notificationCount,
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SectionHeader(title: 'Overview'),
            ),
            const SizedBox(height: 0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: OverviewStatsGrid(
                stats: stats,
                openNeedsCount: openNeedsCount,
                completedNeedsCount: completedNeedsCount,
                onTotalDonors: onViewAll,
                onAvailable: onAvailableContacts,
                onOpenNeeds: onOpenNeeds,
                onCompletedHelps: onCompletedNeeds,
              ),
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: SectionHeader(title: 'Find Donors by Blood Group'),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: BloodGroupGrid(
                counts: stats.groupCounts,
                selectedGroup: selectedBloodGroup,
                onSelected: onBloodGroupSelected,
              ),
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: SectionHeader(title: 'Quick Actions'),
            ),
            const SizedBox(height: 6),
            QuickActionsScroller(onAdd: onAdd, onNeed: onNeed),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SectionHeader(
                title: 'Recent Needs',
                actionLabel: 'View all',
                onAction: onViewAllNeeds,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RecentNeedsList(
                needs: recentNeeds,
                onTapNeed: onOpenRecentNeed,
              ),
            ),
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }
}
