import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';
import 'package:flutter/material.dart';

class BloodBottomNavigation extends StatelessWidget {
  const BloodBottomNavigation({
    super.key,
    required this.selectedTab,
    required this.onHome,
    required this.onContacts,
    required this.onNeeds,
    required this.onProfile,
  });

  final AppTab selectedTab;
  final VoidCallback onHome;
  final VoidCallback onContacts;
  final VoidCallback onNeeds;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 82,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          NavItem(
            icon: Icons.home,
            label: 'Home',
            selected: selectedTab == AppTab.home,
            onTap: onHome,
          ),
          NavItem(
            icon: Icons.people_outline,
            label: 'Contacts',
            selected: selectedTab == AppTab.contacts,
            onTap: onContacts,
          ),
          NavItem(
            icon: Icons.water_drop_outlined,
            label: 'Needs',
            selected: selectedTab == AppTab.needs,
            onTap: onNeeds,
          ),
          NavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            selected: selectedTab == AppTab.profile,
            onTap: onProfile,
          ),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xffe5161d) : const Color(0xff232323);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
