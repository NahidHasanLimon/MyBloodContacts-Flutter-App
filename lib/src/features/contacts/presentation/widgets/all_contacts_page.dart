import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_stats.dart';
import 'package:blood_contacts/src/features/contacts/presentation/widgets/contact_common_widgets.dart';
import 'package:flutter/material.dart';

class AllContactsPage extends StatelessWidget {
  const AllContactsPage({
    super.key,
    required this.stats,
    required this.contacts,
    required this.query,
    required this.selectedGroup,
    required this.selectedAvailability,
    required this.selectedArea,
    required this.nearbyOnly,
    required this.areaOptions,
    required this.onQueryChanged,
    required this.onGroupChanged,
    required this.onAvailabilityChanged,
    required this.onAreaChanged,
    required this.onNearbyChanged,
    required this.onClearFilters,
    required this.onAdd,
    required this.onBack,
    required this.onEditContact,
    required this.onDeleteContact,
  });

  final ContactStats stats;
  final List<BloodContact> contacts;
  final String query;
  final String selectedGroup;
  final AvailabilityFilter selectedAvailability;
  final String selectedArea;
  final bool nearbyOnly;
  final List<String> areaOptions;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onGroupChanged;
  final ValueChanged<AvailabilityFilter> onAvailabilityChanged;
  final ValueChanged<String> onAreaChanged;
  final ValueChanged<bool> onNearbyChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onAdd;
  final VoidCallback onBack;
  final ValueChanged<BloodContact> onEditContact;
  final ValueChanged<BloodContact> onDeleteContact;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ContactsPageHeader(
                query: query,
                onQueryChanged: onQueryChanged,
                onBack: onBack,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: ContactsFilterBar(
                  selectedGroup: selectedGroup,
                  selectedAvailability: selectedAvailability,
                  selectedArea: selectedArea,
                  nearbyOnly: nearbyOnly,
                  areaOptions: areaOptions,
                  onGroupChanged: onGroupChanged,
                  onAvailabilityChanged: onAvailabilityChanged,
                  onAreaChanged: onAreaChanged,
                  onNearbyChanged: onNearbyChanged,
                  onClearFilters: onClearFilters,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: ContactsSummaryCards(stats: stats),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              sliver: SliverToBoxAdapter(
                child: ContactsListToolbar(foundCount: contacts.length),
              ),
            ),
            if (contacts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyContactsList(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                sliver: SliverList.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DetailedContactTile(
                        contact: contact,
                        onTap: () => onEditContact(contact),
                        onDelete: () => onDeleteContact(contact),
                      ),
                    );
                  },
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 96, 116),
              sliver: SliverToBoxAdapter(
                child: DataSafeCard(onTap: onClearFilters),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactsPageHeader extends StatelessWidget {
  const ContactsPageHeader({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.onBack,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffb90f16), Color(0xffe5161d)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back to overview',
                onPressed: onBack,
                icon: const Icon(Icons.menu, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contacts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'All your important contacts',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Search contacts',
                onPressed: () {},
                icon: const Icon(Icons.search, color: Colors.white, size: 34),
              ),
              IconButton(
                tooltip: 'More',
                onPressed: () {},
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          TextField(
            controller: TextEditingController(text: query)
              ..selection = TextSelection.collapsed(offset: query.length),
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Search by name or phone number',
              prefixIcon: const Icon(Icons.search, size: 28),
              suffixIcon: const Icon(Icons.filter_alt_outlined),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactsSummaryCards extends StatelessWidget {
  const ContactsSummaryCards({super.key, required this.stats});

  final ContactStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff0ecec)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SummaryMetricCard(
              label: 'Total contacts',
              value: stats.total,
              icon: Icons.groups_outlined,
              color: const Color(0xffe5161d),
            ),
          ),
          const VerticalDivider(width: 18),
          Expanded(
            child: SummaryMetricCard(
              label: 'O+ contacts',
              value: stats.groupCounts['O+'] ?? 0,
              icon: Icons.water_drop,
              color: const Color(0xffe5161d),
            ),
          ),
          const VerticalDivider(width: 18),
          Expanded(
            child: SummaryMetricCard(
              label: 'Available',
              value: stats.available,
              icon: Icons.circle,
              color: const Color(0xff16a34a),
            ),
          ),
          const VerticalDivider(width: 18),
          Expanded(
            child: SummaryMetricCard(
              label: 'Nearby',
              value: stats.nearby,
              icon: Icons.location_on_outlined,
              color: const Color(0xffe5161d),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryMetricCard extends StatelessWidget {
  const SummaryMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  color: Color(0xff121212),
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xff555560), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ContactsFilterBar extends StatelessWidget {
  const ContactsFilterBar({
    super.key,
    required this.selectedGroup,
    required this.selectedAvailability,
    required this.selectedArea,
    required this.nearbyOnly,
    required this.areaOptions,
    required this.onGroupChanged,
    required this.onAvailabilityChanged,
    required this.onAreaChanged,
    required this.onNearbyChanged,
    required this.onClearFilters,
  });

  final String selectedGroup;
  final AvailabilityFilter selectedAvailability;
  final String selectedArea;
  final bool nearbyOnly;
  final List<String> areaOptions;
  final ValueChanged<String> onGroupChanged;
  final ValueChanged<AvailabilityFilter> onAvailabilityChanged;
  final ValueChanged<String> onAreaChanged;
  final ValueChanged<bool> onNearbyChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff0ecec)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterActionPill(
            label: 'All',
            icon: Icons.groups_outlined,
            selected:
                selectedGroup == 'All Groups' &&
                selectedAvailability == AvailabilityFilter.all &&
                selectedArea == 'All Areas',
            onTap: onClearFilters,
          ),
          const SizedBox(width: 10),
          FilterDropdownPill<String>(
            label: selectedGroup == 'All Groups'
                ? 'Blood group'
                : selectedGroup,
            icon: Icons.water_drop,
            values: const ['All Groups', ...bloodGroups],
            labelBuilder: (value) => value,
            onSelected: onGroupChanged,
            selected: selectedGroup != 'All Groups',
          ),
          const SizedBox(width: 10),
          FilterDropdownPill<AvailabilityFilter>(
            label: selectedAvailability == AvailabilityFilter.all
                ? 'Status'
                : selectedAvailability.label,
            icon: Icons.circle,
            values: AvailabilityFilter.values,
            labelBuilder: (value) => value.label,
            onSelected: onAvailabilityChanged,
            selected: selectedAvailability != AvailabilityFilter.all,
          ),
          const SizedBox(width: 10),
          FilterActionPill(
            label: 'Nearby',
            icon: Icons.location_on_outlined,
            selected: nearbyOnly,
            onTap: () => onNearbyChanged(!nearbyOnly),
          ),
          const SizedBox(width: 10),
          FilterDropdownPill<String>(
            label: selectedArea == 'All Areas' ? 'Area' : selectedArea,
            icon: Icons.map_outlined,
            values: areaOptions,
            labelBuilder: (value) => value,
            onSelected: onAreaChanged,
            selected: selectedArea != 'All Areas',
          ),
          const SizedBox(width: 12),
          TextButton(onPressed: onClearFilters, child: const Text('Clear all')),
        ],
      ),
    );
  }
}

class FilterActionPill extends StatelessWidget {
  const FilterActionPill({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: selected ? const Color(0xffd91522) : Colors.white,
        foregroundColor: selected ? Colors.white : const Color(0xffd91522),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}

class FilterDropdownPill<T> extends StatelessWidget {
  const FilterDropdownPill({
    super.key,
    required this.label,
    required this.icon,
    required this.values,
    required this.labelBuilder,
    required this.onSelected,
    required this.selected,
  });

  final String label;
  final IconData icon;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      itemBuilder: (context) => values
          .map(
            (value) => PopupMenuItem<T>(
              value: value,
              child: Text(labelBuilder(value)),
            ),
          )
          .toList(),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xfffff3f3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xffffd8d8) : const Color(0xffe8e2e2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? const Color(0xffd91522)
                  : const Color(0xff5f626b),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xffc81521)
                    : const Color(0xff343741),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected ? Icons.close : Icons.keyboard_arrow_down,
              size: 18,
              color: selected
                  ? const Color(0xffc81521)
                  : const Color(0xff5f626b),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactsListToolbar extends StatelessWidget {
  const ContactsListToolbar({super.key, required this.foundCount});

  final int foundCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Color(0xff2d2d35),
                    fontSize: 17,
                  ),
                  children: [
                    TextSpan(
                      text: '$foundCount',
                      style: const TextStyle(
                        color: Color(0xff8e6c6c),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const TextSpan(text: ' contacts found'),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Filter options',
              onPressed: () {},
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        Row(
          children: const [
            Text('Sorted by: ', style: TextStyle(color: Color(0xff555560))),
            Text(
              'Recently added',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ],
    );
  }
}

class DetailedContactTile extends StatelessWidget {
  const DetailedContactTile({
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
    final statusColor = contact.isAvailable
        ? const Color(0xff16a34a)
        : const Color(0xffd91522);
    final statusText = contact.isAvailable ? 'Available' : 'Not available';
    final statusNote = contact.isAvailable
        ? 'Can donate now'
        : 'Currently unavailable';
    final distance = _distanceFor(contact);

    return Dismissible(
      key: ValueKey('details-${contact.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        color: Theme.of(context).colorScheme.error,
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xffefeeee)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: groupColor.withValues(alpha: 0.14),
                  foregroundColor: groupColor,
                  child: Text(
                    contact.initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contact.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          BloodGroupBadge(
                            group: contact.bloodGroup,
                            color: const Color(0xffe5161d),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      ContactInfoLine(icon: Icons.phone, text: contact.phone),
                      const SizedBox(height: 7),
                      ContactInfoLine(
                        icon: Icons.location_on_outlined,
                        text: '${contact.area}  •  $distance km',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: statusColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              statusText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        statusNote,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xff565660)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xffd91522),
                      child: IconButton(
                        tooltip: 'Call',
                        onPressed: () {},
                        icon: const Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xffe2e2e2)),
                        ),
                        child: IconButton(
                          tooltip: 'Message',
                          onPressed: () {},
                          icon: const Icon(
                            Icons.chat_bubble_outline,
                            color: Color(0xffd91522),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContactInfoLine extends StatelessWidget {
  const ContactInfoLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xff5d606b)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xff4d4f5a), fontSize: 15),
          ),
        ),
      ],
    );
  }
}

String _distanceFor(BloodContact contact) {
  final value = contact.id.codeUnits.fold<int>(0, (sum, code) => sum + code);
  return (1 + (value % 24) / 10).toStringAsFixed(1);
}

class DataSafeCard extends StatelessWidget {
  const DataSafeCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xfffff1f1),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xffffd6d6)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.gpp_good_outlined,
                color: Color(0xffd91522),
                size: 38,
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your data is safe',
                      style: TextStyle(
                        color: Color(0xffb90f16),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'All your contacts are stored locally on this device.',
                      style: TextStyle(color: Color(0xff42424a), fontSize: 15),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xffb90f16)),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyContactsList extends StatelessWidget {
  const EmptyContactsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.manage_search,
            size: 54,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No contacts match',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Change filters or add contacts to build your blood network.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
