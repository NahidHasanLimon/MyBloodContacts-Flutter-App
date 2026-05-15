import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';
import 'package:blood_contacts/src/features/contacts/presentation/widgets/contact_common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class AllContactsPage extends StatefulWidget {
  const AllContactsPage({
    super.key,
    required this.contacts,
    required this.totalCount,
    required this.availableCount,
    required this.query,
    required this.selectedGroup,
    required this.selectedSort,
    required this.onQueryChanged,
    required this.onGroupChanged,
    required this.onSortChanged,
    required this.onClearFilters,
    required this.onAdd,
    required this.onBack,
    required this.onOpenDetails,
    required this.onEditContact,
    required this.onDeleteContact,
  });

  final List<BloodContact> contacts;
  final int totalCount;
  final int availableCount;
  final String query;
  final String selectedGroup;
  final ContactsSortOption selectedSort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onGroupChanged;
  final ValueChanged<ContactsSortOption> onSortChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onAdd;
  final VoidCallback onBack;
  final ValueChanged<BloodContact> onOpenDetails;
  final ValueChanged<BloodContact> onEditContact;
  final ValueChanged<BloodContact> onDeleteContact;

  @override
  State<AllContactsPage> createState() => _AllContactsPageState();
}

class _AllContactsPageState extends State<AllContactsPage> {
  static const _chipGroups = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
  bool _filtersExpanded = true;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            ContactsPageHeader(
              onAdd: widget.onAdd,
              onResetFilters: widget.onClearFilters,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: ContactsSearchBar(
                query: widget.query,
                onQueryChanged: widget.onQueryChanged,
                onReset: () => widget.onQueryChanged(''),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSize(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.topCenter,
              curve: Curves.easeOut,
              child: _filtersExpanded
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _FiltersGroupCard(
                        totalCount: widget.totalCount,
                        availableCount: widget.availableCount,
                        selectedGroup: widget.selectedGroup,
                        groups: _chipGroups,
                        selectedSort: widget.selectedSort,
                        onGroupChanged: widget.onGroupChanged,
                        onSortChanged: widget.onSortChanged,
                        onCollapse: () =>
                            setState(() => _filtersExpanded = false),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Stack(
                children: [
                  if (widget.contacts.isEmpty)
                    const EmptyContactsList()
                  else
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 116),
                      itemCount: widget.contacts.length,
                      itemBuilder: (context, index) {
                        final contact = widget.contacts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DetailedContactTile(
                            contact: contact,
                            onDetails: () => widget.onOpenDetails(contact),
                            onEdit: () => widget.onEditContact(contact),
                            onDelete: () => widget.onDeleteContact(contact),
                          ),
                        );
                      },
                    ),
                  if (!_filtersExpanded)
                    Positioned(
                      top: 6,
                      right: 16,
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: IconButton.filled(
                          tooltip: 'Expand filters',
                          onPressed: () => setState(() {
                            _filtersExpanded = true;
                          }),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xffe5161d),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.open_in_full, size: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersGroupCard extends StatelessWidget {
  const _FiltersGroupCard({
    required this.totalCount,
    required this.availableCount,
    required this.selectedGroup,
    required this.groups,
    required this.selectedSort,
    required this.onGroupChanged,
    required this.onSortChanged,
    required this.onCollapse,
  });

  final int totalCount;
  final int availableCount;
  final String selectedGroup;
  final List<String> groups;
  final ContactsSortOption selectedSort;
  final ValueChanged<String> onGroupChanged;
  final ValueChanged<ContactsSortOption> onSortChanged;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffffe6de)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: BloodGroupFilterChip(
                  label: 'All',
                  selected: selectedGroup == 'All Groups',
                  onTap: () => onGroupChanged('All Groups'),
                ),
              ),
              for (final group in groups) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: BloodGroupFilterChip(
                    label: group,
                    selected: selectedGroup == group,
                    onTap: () => onGroupChanged(group),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ContactsStatsRow(
              totalCount: totalCount,
              availableCount: availableCount,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(
              children: [
                const Text(
                  'Sort by',
                  style: TextStyle(
                    color: Color(0xff433532),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SortMenuButton(
                      selectedSort: selectedSort,
                      onSortChanged: onSortChanged,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onCollapse,
                  tooltip: 'Collapse filters',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xffffece7),
                    foregroundColor: const Color(0xff7d3e32),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.close_fullscreen, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContactsPageHeader extends StatelessWidget {
  const ContactsPageHeader({
    super.key,
    required this.onAdd,
    required this.onResetFilters,
  });

  final VoidCallback onAdd;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Contacts',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(
                width: 42,
                height: 42,
                child: IconButton(
                  onPressed: onResetFilters,
                  tooltip: 'Reset filters',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xfffff1f2),
                    foregroundColor: const Color(0xffe5161d),
                  ),
                  icon: const Icon(Icons.restart_alt, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                height: 42,
                child: IconButton.filled(
                  onPressed: onAdd,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xffe5161d),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Find and connect with blood donors.',
            style: TextStyle(color: Color(0xff343741), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class ContactsSearchBar extends StatefulWidget {
  const ContactsSearchBar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.onReset,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onReset;

  @override
  State<ContactsSearchBar> createState() => _ContactsSearchBarState();
}

class _ContactsSearchBarState extends State<ContactsSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_hasFocus == _focusNode.hasFocus) return;
    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _hasFocus ? const Color(0xffe5161d) : const Color(0xfff2c6ca),
          width: _hasFocus ? 1.0 : 0.55,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, color: Color(0xff454854), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: TextEditingController(text: widget.query)
                ..selection = TextSelection.collapsed(
                  offset: widget.query.length,
                ),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              onChanged: widget.onQueryChanged,
              decoration: const InputDecoration(
                hintText: 'Search by name or phone number...',
                hintStyle: TextStyle(color: Color(0xff5d606b), fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onReset,
            tooltip: 'Reset',
            icon: const Icon(
              Icons.restart_alt,
              color: Color(0xffe5161d),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

class ContactsStatsRow extends StatelessWidget {
  const ContactsStatsRow({
    super.key,
    required this.totalCount,
    required this.availableCount,
  });

  final int totalCount;
  final int availableCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ContactStatCard(
            value: totalCount,
            label: 'Total Donors',
            icon: Icons.groups_2_outlined,
            iconColor: const Color(0xffe5161d),
            tint: const Color(0xfffff4f5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ContactStatCard(
            value: availableCount,
            label: 'Available Now',
            icon: Icons.water_drop_outlined,
            iconColor: const Color(0xff16a34a),
            tint: const Color(0xfff6fbf6),
          ),
        ),
      ],
    );
  }
}

class ContactStatCard extends StatelessWidget {
  const ContactStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.tint,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffefeeee)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 16,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff343741),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BloodGroupFilterChip extends StatelessWidget {
  const BloodGroupFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          width: double.infinity,
          height: 38,
          decoration: BoxDecoration(
            color: selected ? const Color(0xffe5161d) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? const Color(0xffe5161d)
                  : const Color(0xffe6e3e8),
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x22e5161d),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SortMenuButton extends StatelessWidget {
  const SortMenuButton({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  final ContactsSortOption selectedSort;
  final ValueChanged<ContactsSortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ContactsSortOption>(
      tooltip: 'Sort contacts',
      onSelected: onSortChanged,
      itemBuilder: (context) => ContactsSortOption.values
          .map(
            (option) => PopupMenuItem(value: option, child: Text(option.label)),
          )
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _sortLabel(selectedSort),
            style: const TextStyle(
              color: Color(0xffe5161d),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Color(0xffe5161d),
          ),
        ],
      ),
    );
  }

  String _sortLabel(ContactsSortOption option) {
    return switch (option) {
      ContactsSortOption.name => 'Name',
      ContactsSortOption.date => 'Recently Added',
      ContactsSortOption.lastDonationDate => 'Last Donation',
    };
  }
}

class DetailedContactTile extends StatelessWidget {
  const DetailedContactTile({
    super.key,
    required this.contact,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final BloodContact contact;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final groupColor =
        bloodGroupColors[contact.bloodGroup] ?? const Color(0xffe5161d);
    final statusColor = contact.isAvailable
        ? const Color(0xff16a34a)
        : const Color(0xff737684);
    return Dismissible(
      key: ValueKey('details-${contact.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        color: Theme.of(context).colorScheme.error,
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDetails,
          onLongPress: () => _showLongPressActions(context),
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffeeeeee)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0a000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 2, 8, 2),
                    child: Row(
                      children: [
                        ContactAvatar(
                          contact: contact,
                          radius: 23,
                          backgroundColor: groupColor.withValues(alpha: 0.12),
                          foregroundColor: groupColor,
                          textStyle: TextStyle(
                            color: groupColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      contact.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  BloodGroupBadge(
                                    group: contact.bloodGroup,
                                    color: groupColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ContactInfoLine(
                                icon: Icons.phone_outlined,
                                text: contact.phone,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(
                width: 64,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ContactQuickActionButton(
                      tooltip: 'Call',
                      icon: Icons.phone_outlined,
                      backgroundColor: const Color(0xffeef9f0),
                      foregroundColor: const Color(0xff16a34a),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 6),
                    ContactQuickActionButton(
                      tooltip: 'Share',
                      icon: Icons.share_outlined,
                      backgroundColor: const Color(0xfffff1f2),
                      foregroundColor: const Color(0xffe5161d),
                      onPressed: () => _shareContact(context, contact),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLongPressActions(BuildContext context) async {
    final action = await showModalBottomSheet<_ContactTileAction>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Details'),
              onTap: () => Navigator.pop(context, _ContactTileAction.details),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context, _ContactTileAction.edit),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, _ContactTileAction.delete),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy number'),
              onTap: () => Navigator.pop(context, _ContactTileAction.copyNumber),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;

    switch (action) {
      case _ContactTileAction.details:
        onDetails();
      case _ContactTileAction.edit:
        onEdit();
      case _ContactTileAction.delete:
        onDelete();
      case _ContactTileAction.copyNumber:
        Clipboard.setData(ClipboardData(text: contact.phone));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number copied')),
        );
      case null:
        break;
    }
  }

  Future<void> _shareContact(BuildContext context, BloodContact contact) async {
    final box = context.findRenderObject() as RenderBox?;
    final note = contact.note.trim();
    final remarks = note.isEmpty
        ? 'Please contact directly before planning a donation.'
        : note;

    await SharePlus.instance.share(
      ShareParams(
        subject: 'Blood donor contact: ${contact.name}',
        text:
            '''
Blood donor contact

Name: ${contact.name}
Blood group: ${contact.bloodGroup}
Mobile: ${contact.phone}
Area: ${contact.area}
Remarks: $remarks
'''
                .trim(),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}

enum _ContactTileAction { details, edit, delete, copyNumber }

class ContactQuickActionButton extends StatelessWidget {
  const ContactQuickActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 30,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon, size: 16),
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
        Icon(icon, size: 16, color: const Color(0xff343741)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xff343741), fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class EmptyContactsList extends StatelessWidget {
  const EmptyContactsList({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 8),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Change filters or add contacts to build your blood network.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
