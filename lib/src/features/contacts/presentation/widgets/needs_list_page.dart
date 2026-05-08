import 'package:blood_contacts/src/features/contacts/domain/blood_need_request.dart';
import 'package:flutter/material.dart';

enum NeedUrgencyFilter { all, urgent, normal }

enum NeedStatusFilter { all, open, inProgress, fulfilled, cancelled }

enum NeedSortOption { newest, oldest, unitsHigh }

class NeedsListPage extends StatefulWidget {
  const NeedsListPage({super.key, required this.needs});

  final List<BloodNeedRequest> needs;

  @override
  State<NeedsListPage> createState() => _NeedsListPageState();
}

class _NeedsListPageState extends State<NeedsListPage> {
  bool _filtersVisible = false;
  String _query = '';
  String _selectedGroup = 'All';
  NeedUrgencyFilter _selectedUrgency = NeedUrgencyFilter.all;
  NeedStatusFilter _selectedStatus = NeedStatusFilter.all;
  NeedSortOption _selectedSort = NeedSortOption.newest;

  List<BloodNeedRequest> get _filteredNeeds {
    final query = _query.trim().toLowerCase();
    final filtered = widget.needs.where((need) {
      final matchesQuery =
          query.isEmpty ||
          '${need.patientName} ${need.hospital}'.toLowerCase().contains(query);
      final matchesGroup =
          _selectedGroup == 'All' || need.bloodGroup == _selectedGroup;
      final matchesUrgency = switch (_selectedUrgency) {
        NeedUrgencyFilter.all => true,
        NeedUrgencyFilter.urgent => need.urgency == NeedUrgency.urgent,
        NeedUrgencyFilter.normal => need.urgency == NeedUrgency.normal,
      };
      final matchesStatus = switch (_selectedStatus) {
        NeedStatusFilter.all => true,
        NeedStatusFilter.open => need.status == NeedStatus.open,
        NeedStatusFilter.inProgress => need.status == NeedStatus.inProgress,
        NeedStatusFilter.fulfilled => need.status == NeedStatus.fulfilled,
        NeedStatusFilter.cancelled => need.status == NeedStatus.cancelled,
      };

      return matchesQuery && matchesGroup && matchesUrgency && matchesStatus;
    }).toList();

    return filtered..sort((a, b) {
      return switch (_selectedSort) {
        NeedSortOption.newest => b.sortRank.compareTo(a.sortRank),
        NeedSortOption.oldest => a.sortRank.compareTo(b.sortRank),
        NeedSortOption.unitsHigh => b.units.compareTo(a.units),
      };
    });
  }

  void _resetFilters() {
    setState(() {
      _query = '';
      _selectedGroup = 'All';
      _selectedUrgency = NeedUrgencyFilter.all;
      _selectedStatus = NeedStatusFilter.all;
      _selectedSort = NeedSortOption.newest;
      _filtersVisible = false;
    });
  }

  Future<void> _showFiltersPopup() async {
    setState(() => _filtersVisible = true);

    var selectedGroup = _selectedGroup;
    var selectedUrgency = _selectedUrgency;
    var selectedStatus = _selectedStatus;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (context) {
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: EdgeInsets.fromLTRB(
            18,
            MediaQuery.paddingOf(context).top + 144,
            18,
            18,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: StatefulBuilder(
            builder: (context, setPopupState) {
              return _FilterPopupContent(
                selectedGroup: selectedGroup,
                selectedUrgency: selectedUrgency,
                selectedStatus: selectedStatus,
                onGroupChanged: (value) {
                  setPopupState(() => selectedGroup = value);
                  setState(() => _selectedGroup = value);
                },
                onUrgencyChanged: (value) {
                  setPopupState(() => selectedUrgency = value);
                  setState(() => _selectedUrgency = value);
                },
                onStatusChanged: (value) {
                  setPopupState(() => selectedStatus = value);
                  setState(() => _selectedStatus = value);
                },
              );
            },
          ),
        );
      },
    );

    if (mounted) {
      setState(() => _filtersVisible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.needs.length;
    final urgent = widget.needs
        .where((need) => need.urgency == NeedUrgency.urgent)
        .length;
    final open = widget.needs
        .where((need) => need.status == NeedStatus.open)
        .length;
    final needs = _filteredNeeds;

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _NeedsHeader(onReset: _resetFilters)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 0),
              sliver: SliverToBoxAdapter(
                child: _NeedsSearchAndFilters(
                  query: _query,
                  filtersVisible: _filtersVisible,
                  onQueryChanged: (value) => setState(() => _query = value),
                  onOpenFilters: _showFiltersPopup,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              sliver: SliverToBoxAdapter(
                child: _NeedStatsRow(total: total, urgent: urgent, open: open),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              sliver: SliverToBoxAdapter(
                child: _NeedSortButton(
                  selectedSort: _selectedSort,
                  onSortChanged: (value) {
                    setState(() => _selectedSort = value);
                  },
                ),
              ),
            ),
            if (needs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No needs match',
                    style: TextStyle(
                      color: Color(0xff343741),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 116),
                sliver: SliverList.builder(
                  itemCount: needs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NeedRequestCard(need: needs[index]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NeedsHeader extends StatelessWidget {
  const _NeedsHeader({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Needs',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Browse blood requests and help save lives.',
                  style: TextStyle(color: Color(0xff343741), fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onReset,
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh, color: Color(0xffe5161d), size: 24),
          ),
        ],
      ),
    );
  }
}

class _NeedsSearchAndFilters extends StatelessWidget {
  const _NeedsSearchAndFilters({
    required this.query,
    required this.filtersVisible,
    required this.onQueryChanged,
    required this.onOpenFilters,
  });

  final String query;
  final bool filtersVisible;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffdddfe6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, color: Color(0xff151722), size: 25),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: query)
                ..selection = TextSelection.collapsed(offset: query.length),
              onChanged: onQueryChanged,
              style: const TextStyle(
                color: Color(0xff262936),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Search by patient, hospital or location...',
                hintStyle: TextStyle(color: Color(0xff4d5060), fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xffe8e8ee)),
          IconButton(
            onPressed: onOpenFilters,
            tooltip: 'Filter',
            icon: Icon(
              Icons.tune,
              color: filtersVisible
                  ? const Color(0xffb90009)
                  : const Color(0xffe5161d),
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _FilterPopupContent extends StatelessWidget {
  const _FilterPopupContent({
    required this.selectedGroup,
    required this.selectedUrgency,
    required this.selectedStatus,
    required this.onGroupChanged,
    required this.onUrgencyChanged,
    required this.onStatusChanged,
  });

  final String selectedGroup;
  final NeedUrgencyFilter selectedUrgency;
  final NeedStatusFilter selectedStatus;
  final ValueChanged<String> onGroupChanged;
  final ValueChanged<NeedUrgencyFilter> onUrgencyChanged;
  final ValueChanged<NeedStatusFilter> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 380),
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffdddfe6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTight = constraints.maxWidth < 520;
              final sections = [
                Expanded(
                  flex: 5,
                  child: _FilterSection(
                    title: 'Blood Group',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: [
                        _FilterChipButton(
                          label: 'All',
                          selected: selectedGroup == 'All',
                          onTap: () => onGroupChanged('All'),
                        ),
                        for (final group in const [
                          'O+',
                          'O-',
                          'A+',
                          'A-',
                          'B+',
                          'B-',
                          'AB+',
                          'AB-',
                        ])
                          _FilterChipButton(
                            label: group,
                            selected: selectedGroup == group,
                            onTap: () => onGroupChanged(group),
                          ),
                      ],
                    ),
                  ),
                ),
                _FilterDivider(vertical: !isTight),
                Expanded(
                  flex: 3,
                  child: _FilterSection(
                    title: 'Urgency',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: [
                        _FilterChipButton(
                          label: 'All',
                          selected: selectedUrgency == NeedUrgencyFilter.all,
                          onTap: () => onUrgencyChanged(NeedUrgencyFilter.all),
                        ),
                        _FilterChipButton(
                          label: 'Urgent',
                          icon: Icons.crisis_alert,
                          selected: selectedUrgency == NeedUrgencyFilter.urgent,
                          onTap: () =>
                              onUrgencyChanged(NeedUrgencyFilter.urgent),
                        ),
                        _FilterChipButton(
                          label: 'Normal',
                          icon: Icons.schedule,
                          selected: selectedUrgency == NeedUrgencyFilter.normal,
                          onTap: () =>
                              onUrgencyChanged(NeedUrgencyFilter.normal),
                        ),
                      ],
                    ),
                  ),
                ),
                _FilterDivider(vertical: !isTight),
                Expanded(
                  flex: 5,
                  child: _FilterSection(
                    title: 'Status',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: [
                        _FilterChipButton(
                          label: 'All',
                          selected: selectedStatus == NeedStatusFilter.all,
                          onTap: () => onStatusChanged(NeedStatusFilter.all),
                        ),
                        _FilterChipButton(
                          label: 'Open',
                          dotColor: const Color(0xff21b14b),
                          selected: selectedStatus == NeedStatusFilter.open,
                          onTap: () => onStatusChanged(NeedStatusFilter.open),
                        ),
                        _FilterChipButton(
                          label: 'In Progress',
                          dotColor: const Color(0xffff8a00),
                          selected:
                              selectedStatus == NeedStatusFilter.inProgress,
                          onTap: () =>
                              onStatusChanged(NeedStatusFilter.inProgress),
                        ),
                        _FilterChipButton(
                          label: 'Fulfilled',
                          dotColor: const Color(0xff1d74e8),
                          selected:
                              selectedStatus == NeedStatusFilter.fulfilled,
                          onTap: () =>
                              onStatusChanged(NeedStatusFilter.fulfilled),
                        ),
                        _FilterChipButton(
                          label: 'Cancelled',
                          dotColor: const Color(0xff838895),
                          selected:
                              selectedStatus == NeedStatusFilter.cancelled,
                          onTap: () =>
                              onStatusChanged(NeedStatusFilter.cancelled),
                        ),
                      ],
                    ),
                  ),
                ),
              ];

              if (!isTight) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections,
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final section in sections)
                    if (section is Expanded) ...[
                      section.child,
                      const SizedBox(height: 16),
                    ] else
                      section,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _FilterDivider extends StatelessWidget {
  const _FilterDivider({required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    if (!vertical) {
      return Container(
        height: 1,
        margin: const EdgeInsets.only(bottom: 16),
        color: const Color(0xffe2e3ea),
      );
    }

    return Container(
      width: 1,
      height: 116,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xffe2e3ea),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xff151722);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xffe5161d) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xffe5161d)
                  : const Color(0xffdfe2ea),
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x24e5161d),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeedStatsRow extends StatelessWidget {
  const _NeedStatsRow({
    required this.total,
    required this.urgent,
    required this.open,
  });

  final int total;
  final int urgent;
  final int open;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _NeedStatCard(
            value: total,
            label: 'Total Requests',
            icon: Icons.assignment_outlined,
            color: const Color(0xffe5161d),
            tint: const Color(0xfffff2f4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _NeedStatCard(
            value: urgent,
            label: 'Urgent Requests',
            icon: Icons.crisis_alert,
            color: const Color(0xffff9700),
            tint: const Color(0xfffff8ec),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _NeedStatCard(
            value: open,
            label: 'Open Requests',
            icon: Icons.groups_2_outlined,
            color: const Color(0xff16a34a),
            tint: const Color(0xfff1f9f3),
          ),
        ),
      ],
    );
  }
}

class _NeedStatCard extends StatelessWidget {
  const _NeedStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.tint,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 10),
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
                    color: color,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff343741),
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
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

class _NeedSortButton extends StatelessWidget {
  const _NeedSortButton({
    required this.selectedSort,
    required this.onSortChanged,
  });

  final NeedSortOption selectedSort;
  final ValueChanged<NeedSortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<NeedSortOption>(
      tooltip: 'Sort needs',
      onSelected: onSortChanged,
      itemBuilder: (context) => NeedSortOption.values
          .map(
            (option) =>
                PopupMenuItem(value: option, child: Text(_sortLabel(option))),
          )
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sort by: ',
            style: TextStyle(
              color: Color(0xff343741),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            _sortLabel(selectedSort),
            style: const TextStyle(
              color: Color(0xffe5161d),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Color(0xffe5161d),
          ),
        ],
      ),
    );
  }

  String _sortLabel(NeedSortOption option) {
    return switch (option) {
      NeedSortOption.newest => 'Newest First',
      NeedSortOption.oldest => 'Oldest First',
      NeedSortOption.unitsHigh => 'Units High',
    };
  }
}

class NeedRequestCard extends StatelessWidget {
  const NeedRequestCard({super.key, required this.need});

  final BloodNeedRequest need;

  @override
  Widget build(BuildContext context) {
    final urgencyColor = need.urgency.color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffececf1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: urgencyColor),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BloodDropBadge(need: need),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                need.patientName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xff101225),
                                  fontSize: 16,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                need.summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xff343741),
                                  fontSize: 14,
                                  height: 1.2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _NeedInfoLine(
                                icon: Icons.business_outlined,
                                text: need.hospital,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 14,
                                runSpacing: 8,
                                children: [
                                  _NeedInfoItem(
                                    icon: Icons.calendar_today_outlined,
                                    text: need.date,
                                  ),
                                  _NeedInfoItem(
                                    icon: Icons.schedule,
                                    text: need.time,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _UnitsBadge(units: need.units),
                            const SizedBox(height: 12),
                            _StatusBadge(status: need.status),
                            const SizedBox(height: 6),
                            const Icon(
                              Icons.more_vert,
                              color: Color(0xff24283a),
                              size: 24,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: const Color(0xffeeeef3)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: Color(0xff343741),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            need.requester,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xff343741),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(
                            color: Color(0xff343741),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Icon(
                          Icons.phone_outlined,
                          color: Color(0xff343741),
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            need.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xff343741),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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

class _BloodDropBadge extends StatelessWidget {
  const _BloodDropBadge({required this.need});

  final BloodNeedRequest need;

  @override
  Widget build(BuildContext context) {
    final color = need.urgency.color;

    return SizedBox(
      width: 78,
      child: Column(
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.water_drop, color: color, size: 68),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    need.bloodGroup,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(need.urgency.icon, color: color, size: 14),
                const SizedBox(width: 4),
                Text(
                  need.urgency.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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

class _NeedInfoLine extends StatelessWidget {
  const _NeedInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xff343741), size: 17),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff343741),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _NeedInfoItem extends StatelessWidget {
  const _NeedInfoItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff343741), size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff343741),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitsBadge extends StatelessWidget {
  const _UnitsBadge({required this.units});

  final int units;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xfffff0f2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$units ${units == 1 ? 'Unit' : 'Units'}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xffe5161d),
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final NeedStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: status.tint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
