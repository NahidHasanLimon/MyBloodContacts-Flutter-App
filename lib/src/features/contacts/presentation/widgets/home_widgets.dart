import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_stats.dart';
import 'package:blood_contacts/src/features/contacts/presentation/widgets/contact_common_widgets.dart';
import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Menu',
          onPressed: () {},
          icon: const Icon(Icons.menu),
        ),
        const Expanded(
          child: Text(
            'My Blood Contacts',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        IconButton.filled(
          tooltip: 'Add contact',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xff12151b),
            foregroundColor: Colors.white,
          ),
          onPressed: onAdd,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class NeedBloodCard extends StatelessWidget {
  const NeedBloodCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 86,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xffe7171f), Color(0xffdb1d22)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26e5161d),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 76,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
                child: const Icon(
                  Icons.water_drop,
                  size: 44,
                  color: Color(0xffffd9d9),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need blood?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Check your contacts quickly',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 18),
                child: Icon(Icons.arrow_forward, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class BloodGroupGrid extends StatelessWidget {
  const BloodGroupGrid({
    super.key,
    required this.counts,
    required this.selectedGroup,
    required this.onSelected,
  });

  final Map<String, int> counts;
  final String? selectedGroup;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: bloodGroups.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final group = bloodGroups[index];
        return BloodGroupCard(
          group: group,
          count: counts[group] ?? 0,
          selected: group == selectedGroup,
          onTap: () => onSelected(group),
        );
      },
    );
  }
}

class BloodGroupCard extends StatelessWidget {
  const BloodGroupCard({
    super.key,
    required this.group,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String group;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final groupColor = bloodGroupColors[group] ?? const Color(0xffe5161d);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? groupColor : const Color(0xfff0ece8),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                group,
                style: TextStyle(
                  color: groupColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 1),
              const Text('contacts', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class TotalContactsCard extends StatelessWidget {
  const TotalContactsCard({
    super.key,
    required this.count,
    required this.driveFolder,
    required this.onTap,
  });

  final int count;
  final String? driveFolder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffeffaf1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffb9e4c2)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.gpp_good_outlined,
                color: Color(0xff0f7b3f),
                size: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Contacts',
                      style: TextStyle(
                        color: Color(0xff0f7b3f),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      driveFolder == null
                          ? '$count people'
                          : '$count people | Drive: $driveFolder',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xff0f7b3f)),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickFilterBar extends StatelessWidget {
  const QuickFilterBar({
    super.key,
    required this.stats,
    required this.selectedFilter,
    required this.onChanged,
  });

  final ContactStats stats;
  final ContactFilter selectedFilter;
  final ValueChanged<ContactFilter> onChanged;

  int _countFor(ContactFilter filter) {
    return switch (filter) {
      ContactFilter.all => stats.total,
      ContactFilter.available => stats.available,
      ContactFilter.nearby => stats.nearby,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ContactFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = ContactFilter.values[index];
          return FilterPill(
            label: filter.label,
            count: _countFor(filter),
            icon: filter.icon,
            selected: selectedFilter == filter,
            onTap: () => onChanged(filter),
          );
        },
      ),
    );
  }
}

class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xff111111);
    final background = selected ? const Color(0xffe5161d) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? const Color(0xffe5161d)
                  : const Color(0xffe8e3df),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Text('$count', style: TextStyle(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentContactTile extends StatelessWidget {
  const RecentContactTile({
    super.key,
    required this.contact,
    required this.onTap,
    required this.onDelete,
  });

  final BloodContact contact;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final groupColor =
        bloodGroupColors[contact.bloodGroup] ?? const Color(0xffe5161d);

    return Dismissible(
      key: ValueKey(contact.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        color: Theme.of(context).colorScheme.error,
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onTap,
        dense: true,
        minVerticalPadding: 10,
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xffececef),
          foregroundColor: const Color(0xff111111),
          child: Text(contact.initials),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            BloodGroupBadge(group: contact.bloodGroup, color: groupColor),
          ],
        ),
        subtitle: Text(
          '${contact.phone} · ${contact.area}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xfffff7f1),
          child: IconButton(
            tooltip: 'Call',
            onPressed: () {},
            icon: const Icon(Icons.phone_outlined, size: 20),
          ),
        ),
      ),
    );
  }
}

class EmptyRecentContacts extends StatelessWidget {
  const EmptyRecentContacts({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xfff0ece8)),
      ),
      child: const Column(
        children: [
          Icon(Icons.bloodtype, size: 42, color: Color(0xffe5161d)),
          SizedBox(height: 10),
          Text(
            'No contacts found',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text('Add someone to build your blood contact list.'),
        ],
      ),
    );
  }
}
