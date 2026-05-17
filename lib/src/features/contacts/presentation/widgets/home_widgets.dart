import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_need_request.dart';
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
                        fontSize: 16,
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

class HomeHeroHeader extends StatelessWidget {
  const HomeHeroHeader({
    super.key,
    required this.onNeed,
    required this.onNotifications,
    required this.notificationCount,
  });

  final VoidCallback onNeed;
  final VoidCallback onNotifications;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
      decoration: const BoxDecoration(
        color: Color(0xffd90416),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good evening',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Together we can save lives.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: onNotifications,
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      right: 6,
                      top: 4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xffff3e50),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Transform.translate(
            offset: const Offset(0, 28),
            child: UrgentNeedCard(onTap: onNeed),
          ),
        ],
      ),
    );
  }
}

class UrgentNeedCard extends StatelessWidget {
  const UrgentNeedCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardRadius = BorderRadius.circular(22);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 370;
        final content = compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _NeedIcon(size: 58),
                      const SizedBox(width: 14),
                      Expanded(child: _NeedCardCopy(compact: compact)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _NewNeedButton(onTap: onTap, fullWidth: true),
                ],
              )
            : Row(
                children: [
                  const _NeedIcon(size: 66),
                  const SizedBox(width: 15),
                  const Expanded(child: _NeedCardCopy(compact: false)),
                  const SizedBox(width: 12),
                  _NewNeedButton(onTap: onTap),
                ],
              );

        return Material(
          color: Colors.transparent,
          borderRadius: cardRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: cardRadius,
            child: Ink(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: cardRadius,
                border: Border.all(color: const Color(0xfff3ece8), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1f000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

class _NeedIcon extends StatelessWidget {
  const _NeedIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xffd90416),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.bloodtype, color: Colors.white, size: size * 0.55),
    );
  }
}

class _NeedCardCopy extends StatelessWidget {
  const _NeedCardCopy({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Someone needs blood urgently?',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xff101010),
            fontSize: 16,
            height: 1.12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Create a need so you can follow up with donors quickly.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Color(0xff555560), fontSize: 14, height: 1.3),
        ),
      ],
    );
  }
}

class _NewNeedButton extends StatelessWidget {
  const _NewNeedButton({required this.onTap, this.fullWidth = false});

  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 22),
      label: const Text(
        'New Need',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xffd90416),
        foregroundColor: Colors.white,
        fixedSize: fullWidth ? null : const Size(124, 50),
        minimumSize: fullWidth ? const Size.fromHeight(50) : null,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: compact ? 1 : null,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: compact ? EdgeInsets.zero : null,
              minimumSize: compact ? Size.zero : null,
              tapTargetSize: compact
                  ? MaterialTapTargetSize.shrinkWrap
                  : null,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: Color(0xffd90416),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class OverviewStatsGrid extends StatelessWidget {
  const OverviewStatsGrid({
    super.key,
    required this.stats,
    required this.openNeedsCount,
    required this.completedNeedsCount,
    required this.onTotalDonors,
    required this.onAvailable,
    required this.onOpenNeeds,
    required this.onCompletedHelps,
  });

  final ContactStats stats;
  final int openNeedsCount;
  final int completedNeedsCount;
  final VoidCallback onTotalDonors;
  final VoidCallback onAvailable;
  final VoidCallback onOpenNeeds;
  final VoidCallback onCompletedHelps;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 7,
          crossAxisSpacing: 7,
          childAspectRatio: 0.86,
          children: [
            OverviewStatCard(
              icon: Icons.groups_2_outlined,
              value: stats.total,
              title: 'Total Donors',
              color: const Color(0xffdf3348),
              background: const Color(0xfffff8f8),
              onTap: onTotalDonors,
            ),
            OverviewStatCard(
              icon: Icons.check_circle_outline,
              value: stats.available,
              title: 'Available Now',
              color: const Color(0xff129c4b),
              background: const Color(0xfff5fffa),
              onTap: onAvailable,
            ),
            OverviewStatCard(
              icon: Icons.assignment_outlined,
              value: openNeedsCount,
              title: 'Open Needs',
              color: const Color(0xffff9718),
              background: const Color(0xfffffbf4),
              onTap: onOpenNeeds,
            ),
            OverviewStatCard(
              icon: Icons.volunteer_activism_outlined,
              value: completedNeedsCount,
              title: 'Completed Helps',
              color: const Color(0xff7754c7),
              background: const Color(0xfffbf8ff),
              onTap: onCompletedHelps,
            ),
          ],
        );
      },
    );
  }
}

class OverviewStatCard extends StatelessWidget {
  const OverviewStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.title,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final int value;
  final String title;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.12)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0f000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 5),
              Text(
                '$value',
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 9.5,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          itemCount: bloodGroups.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: 1,
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
    final cardColor = selected
        ? groupColor.withValues(alpha: 0.12)
        : Colors.white;
    final countColor = selected ? groupColor : const Color(0xff1f2330);
    final groupTextColor = selected ? groupColor : const Color(0xff4f5565);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? groupColor : const Color(0xfff0ece8),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.water_drop, color: groupColor, size: 18),
              const SizedBox(height: 2),
              Text(
                group,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: groupTextColor,
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: countColor,
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActionsScroller extends StatelessWidget {
  const QuickActionsScroller({
    super.key,
    required this.onAdd,
    required this.onNeed,
    required this.onFindDonors,
  });

  final VoidCallback onAdd;
  final VoidCallback onNeed;
  final VoidCallback onFindDonors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          QuickActionCard(
            icon: Icons.person_add_alt_1_outlined,
            title: 'Add Contact',
            subtitle: 'Add a new blood donor to your list',
            onTap: onAdd,
          ),
          const SizedBox(width: 12),
          QuickActionCard(
            icon: Icons.bloodtype_outlined,
            title: 'New Need',
            subtitle: 'Create a new blood need and find help',
            onTap: onNeed,
          ),
          const SizedBox(width: 12),
          QuickActionCard(
            icon: Icons.groups_2_outlined,
            title: 'See All Donors',
            subtitle: 'Open contacts and browse every donor',
            onTap: onFindDonors,
          ),
        ],
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width * 0.76)
          .clamp(260.0, 330.0)
          .toDouble(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xfffff5f5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffffd7d7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xffd90416),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff60616a),
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xffffb8bf)),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Color(0xff555560),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecentNeedsList extends StatelessWidget {
  const RecentNeedsList({
    super.key,
    required this.needs,
    required this.onTapNeed,
  });

  final List<BloodNeedRequest> needs;
  final ValueChanged<BloodNeedRequest> onTapNeed;

  @override
  Widget build(BuildContext context) {
    if (needs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xfffaf9f8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffefeeee)),
        ),
        child: const Text(
          'No recent needs yet.',
          style: TextStyle(
            color: Color(0xff6a5e5c),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < needs.length; i++) ...[
          RecentNeedTile(
            group: needs[i].bloodGroup,
            title: '${needs[i].bloodGroup} Blood Needed',
            location: needs[i].hospital,
            date: 'Needed by ${needs[i].date}',
            requestStatus: needs[i].status.label,
            requestStatusColor: needs[i].status.color,
            requestStatusTint: needs[i].status.tint,
            tint: needs[i].status.tint,
            onTap: () => onTapNeed(needs[i]),
          ),
          if (i != needs.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class RecentNeedTile extends StatelessWidget {
  const RecentNeedTile({
    super.key,
    required this.group,
    required this.title,
    required this.location,
    required this.date,
    required this.requestStatus,
    required this.requestStatusColor,
    required this.requestStatusTint,
    required this.tint,
    required this.onTap,
  });

  final String group;
  final String title;
  final String location;
  final String date;
  final String requestStatus;
  final Color requestStatusColor;
  final Color requestStatusTint;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffefeeee)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0f000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Icon(
                  Icons.water_drop,
                  color: requestStatusColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _NeedMetaLine(
                      icon: Icons.location_on_outlined,
                      text: location,
                    ),
                    const SizedBox(height: 5),
                    _NeedMetaLine(
                      icon: Icons.calendar_today_outlined,
                      text: date,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: requestStatusTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  requestStatus,
                  style: TextStyle(
                    color: requestStatusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xff555560)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeedMetaLine extends StatelessWidget {
  const _NeedMetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xff555560), size: 15),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xff555560), fontSize: 12),
          ),
        ),
      ],
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
                          : '$count people | Drive connected',
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
    required this.selectedBloodGroup,
    required this.selectedFilter,
    required this.onChanged,
  });

  final ContactStats stats;
  final String? selectedBloodGroup;
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
            selected:
                selectedFilter == filter &&
                (filter != ContactFilter.all || selectedBloodGroup == null),
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
        leading: ContactAvatar(
          contact: contact,
          radius: 22,
          backgroundColor: const Color(0xffececef),
          foregroundColor: const Color(0xff111111),
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
