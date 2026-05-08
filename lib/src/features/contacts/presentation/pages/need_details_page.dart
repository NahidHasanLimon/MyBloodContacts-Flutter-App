import 'package:blood_contacts/src/app/app_theme.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_need_request.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class NeedDetailsPage extends StatefulWidget {
  const NeedDetailsPage({
    super.key,
    required this.need,
    required this.contacts,
    required this.onChanged,
  });

  final BloodNeedRequest need;
  final List<BloodContact> contacts;
  final ValueChanged<BloodNeedRequest> onChanged;

  @override
  State<NeedDetailsPage> createState() => _NeedDetailsPageState();
}

class _NeedDetailsPageState extends State<NeedDetailsPage> {
  late BloodNeedRequest _need;

  @override
  void initState() {
    super.initState();
    _need = widget.need;
  }

  @override
  Widget build(BuildContext context) {
    final red = _need.urgency.color;

    return Scaffold(
      backgroundColor: const Color(0xfffbfaf8),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              sliver: SliverList.list(
                children: [
                  _NeedDetailsHeader(
                    onBack: () => Navigator.pop(context),
                    onShare: () => _shareNeed(context),
                    onClose: () => _closeRequest(context),
                  ),
                  const SizedBox(height: 18),
                  _UrgencyBanner(need: _need),
                  const SizedBox(height: 16),
                  _NeedSummaryCard(need: _need, red: red),
                  const SizedBox(height: 14),
                  _InfoCard(
                    icon: Icons.business_outlined,
                    title: 'Hospital',
                    child: _HospitalContent(need: _need),
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Status',
                    child: _StatusContent(need: _need),
                  ),
                  const SizedBox(height: 14),
                  _PotentialDonorsCard(
                    count: 0,
                    onViewAll: () => _showPotentialDonors(context),
                  ),
                  const SizedBox(height: 14),
                  _ActionsCard(
                    canMarkFulfilled: _need.status != NeedStatus.fulfilled,
                    canClose: _need.status != NeedStatus.cancelled,
                    onFulfilled: () => _markFulfilled(context),
                    onClose: () => _closeRequest(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showComingSoon(context, 'Save request'),
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Save'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(
                      fontSize: AppFontSizes.buttonText,
                      fontWeight: FontWeight.w900,
                    ),
                    side: const BorderSide(color: Color(0xffd8dbe3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      _showComingSoon(context, 'Call contact person'),
                  icon: const Icon(Icons.call),
                  label: const Text('Call Now'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: const Color(0xffe5161d),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: AppFontSizes.buttonText,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareNeed(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Blood need: ${_need.bloodGroup}',
        text:
            '''
Blood need request

Patient: ${_need.patientName}
Blood group: ${_need.bloodGroup}
Units needed: ${_need.units}
Hospital: ${_need.hospital}
Needed on: ${_need.date}, ${_need.time}
Requested by: ${_need.requester}
Contact: ${_need.phone}
Description: ${_need.summary}
'''
                .trim(),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  void _showPotentialDonors(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Potential Donors',
              style: TextStyle(
                color: Colors.black,
                fontSize: AppFontSizes.sectionTitle,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No contacted donors have been added for this need yet.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: AppFontSizes.bodyText,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markFulfilled(BuildContext context) async {
    final donor = await showModalBottomSheet<BloodContact?>(
      context: context,
      showDragHandle: true,
      builder: (context) => _DonorSelectionSheet(contacts: widget.contacts),
    );
    if (!context.mounted) return;

    final updated = _need.copyWith(
      status: NeedStatus.fulfilled,
      updatedAt: DateTime.now(),
    );
    setState(() => _need = updated);
    widget.onChanged(updated);

    final donorText = donor == null ? '' : ' Donor: ${donor.name}.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request marked fulfilled.$donorText')),
    );
  }

  Future<void> _closeRequest(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close request?'),
        content: const Text('This need will be marked as cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close Request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final updated = _need.copyWith(
      status: NeedStatus.cancelled,
      updatedAt: DateTime.now(),
    );
    setState(() => _need = updated);
    widget.onChanged(updated);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request closed.')));
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label will be connected soon.')));
  }
}

class _NeedDetailsHeader extends StatelessWidget {
  const _NeedDetailsHeader({
    required this.onBack,
    required this.onShare,
    required this.onClose,
  });

  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Need Details',
            style: TextStyle(
              color: Colors.black,
              fontSize: AppFontSizes.sectionTitle,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Share request',
          onPressed: onShare,
          icon: const Icon(Icons.share_outlined, color: Color(0xff252a3a)),
        ),
        PopupMenuButton<_NeedAction>(
          icon: const Icon(Icons.more_vert, color: Color(0xff252a3a)),
          onSelected: (action) {
            switch (action) {
              case _NeedAction.close:
                onClose();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _NeedAction.close,
              child: Text('Close Request'),
            ),
          ],
        ),
      ],
    );
  }
}

enum _NeedAction { close }

class _UrgencyBanner extends StatelessWidget {
  const _UrgencyBanner({required this.need});

  final BloodNeedRequest need;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: _cardDecoration(color: const Color(0xfffff0f1)),
      child: Row(
        children: [
          Icon(Icons.water_drop_outlined, color: need.urgency.color, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${need.urgency.label} Need',
                  style: TextStyle(
                    color: need.urgency.color,
                    fontSize: AppFontSizes.cardTitle,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Request ID: ${_requestCode(need)}',
                  style: const TextStyle(
                    color: Color(0xff4b5262),
                    fontSize: AppFontSizes.smallMetadata,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _UrgencyChip(need: need),
          const SizedBox(width: 10),
          Icon(Icons.notifications_none, color: need.urgency.color),
        ],
      ),
    );
  }
}

class _NeedSummaryCard extends StatelessWidget {
  const _NeedSummaryCard({required this.need, required this.red});

  final BloodNeedRequest need;
  final Color red;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 86,
                height: 86,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.water_drop, color: red, size: 86),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        need.bloodGroup,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Blood Group',
                      style: TextStyle(
                        color: Color(0xff4b5262),
                        fontSize: AppFontSizes.bodyText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      need.bloodGroup,
                      style: TextStyle(
                        color: red,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _UnitsPill(units: need.units),
            ],
          ),
          const _SectionDivider(),
          _DetailRow(
            icon: Icons.groups_outlined,
            label: 'Patient',
            title: need.patientName,
            subtitle: need.summary,
          ),
          const _SectionDivider(),
          _DetailRow(
            icon: Icons.person_outline,
            label: 'Contact Person',
            title: need.requester,
            subtitle: need.phone,
          ),
          const _SectionDivider(),
          Row(
            children: [
              Expanded(
                child: _InlineDateInfo(
                  icon: Icons.calendar_today_outlined,
                  label: 'Needed On',
                  value: need.date,
                ),
              ),
              Container(width: 1, height: 58, color: const Color(0xffeeeef3)),
              Expanded(
                child: _InlineDateInfo(
                  icon: Icons.schedule,
                  label: need.time == 'Any time' ? 'Any Time' : 'Needed Time',
                  value: need.time == 'Any time' ? 'Time Flexible' : need.time,
                ),
              ),
            ],
          ),
          const _SectionDivider(),
          _DetailRow(
            icon: Icons.person_outline,
            label: 'Requested By',
            title: need.requester,
            trailing: const _VerifiedChip(),
            subtitle: 'Requested date: ${_formatRequestedDate(need.updatedAt)}',
          ),
          const _SectionDivider(),
          _DetailRow(
            icon: Icons.description_outlined,
            label: 'Description',
            title: need.summary,
          ),
          const _SectionDivider(),
          _Requirements(need: need),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xff343741), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: AppFontSizes.cardTitle,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _HospitalContent extends StatelessWidget {
  const _HospitalContent({required this.need});

  final BloodNeedRequest need;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.location_on_outlined,
          color: Color(0xff343741),
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            need.hospital,
            style: const TextStyle(
              color: Color(0xff252a3a),
              fontSize: AppFontSizes.bodyText,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusContent extends StatelessWidget {
  const _StatusContent({required this.need});

  final BloodNeedRequest need;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusChip(status: need.status),
        const SizedBox(height: 12),
        Text(
          _statusDescription(need.status),
          style: const TextStyle(
            color: Color(0xff343741),
            fontSize: AppFontSizes.bodyText,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PotentialDonorsCard extends StatelessWidget {
  const _PotentialDonorsCard({required this.count, required this.onViewAll});

  final int count;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_ind_outlined,
                color: Color(0xff343741),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Potential Donors ($count)',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: AppFontSizes.cardTitle,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onViewAll,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right, size: 20),
                label: const Text('See'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xffe5161d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Contacted donors for this need will appear here.',
            style: TextStyle(
              color: Color(0xff4b5262),
              fontSize: AppFontSizes.bodyText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonorSelectionSheet extends StatelessWidget {
  const _DonorSelectionSheet({required this.contacts});

  final List<BloodContact> contacts;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Donor',
              style: TextStyle(
                color: Colors.black,
                fontSize: AppFontSizes.sectionTitle,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Optional. Choose who donated for this need.',
              style: TextStyle(
                color: Color(0xff4b5262),
                fontSize: AppFontSizes.bodyText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: const Color(0xff343741),
              ),
              child: const Text('Skip donor selection'),
            ),
            const SizedBox(height: 12),
            if (contacts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'No app contacts available yet.',
                  style: TextStyle(
                    color: Color(0xff4b5262),
                    fontSize: AppFontSizes.bodyText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: contacts.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xffffe3e5),
                        child: Text(
                          contact.initials,
                          style: const TextStyle(
                            color: Color(0xffe5161d),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      title: Text(
                        contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${contact.bloodGroup}  •  ${contact.phone}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.pop(context, contact),
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

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.canMarkFulfilled,
    required this.canClose,
    required this.onFulfilled,
    required this.onClose,
  });

  final bool canMarkFulfilled;
  final bool canClose;
  final VoidCallback onFulfilled;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.task_outlined,
      title: 'Actions',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _ActionButton(
            icon: Icons.check_circle_outline,
            label: 'Mark Fulfilled',
            color: const Color(0xff1d74e8),
            onTap: canMarkFulfilled ? onFulfilled : null,
          ),
          _ActionButton(
            icon: Icons.cancel_outlined,
            label: 'Close Request',
            onTap: canClose ? onClose : null,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xff343741),
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 94,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: const BorderSide(color: Color(0xffe6e8ef)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppFontSizes.smallMetadata,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xff343741), size: 23),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xff4b5262),
                  fontSize: AppFontSizes.smallMetadata,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: AppFontSizes.cardTitle,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 10),
                    trailing!,
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xff343741),
                    fontSize: AppFontSizes.bodyText,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineDateInfo extends StatelessWidget {
  const _InlineDateInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff343741), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xff4b5262),
                    fontSize: AppFontSizes.smallMetadata,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: AppFontSizes.bodyText,
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

class _Requirements extends StatelessWidget {
  const _Requirements({required this.need});

  final BloodNeedRequest need;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.assignment_outlined, color: Color(0xff343741), size: 22),
            SizedBox(width: 12),
            Text(
              'Requirements',
              style: TextStyle(
                color: Colors.black,
                fontSize: AppFontSizes.cardTitle,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _RequirementLine(label: 'Blood Group:', value: need.bloodGroup),
        _RequirementLine(
          label: 'Units Needed:',
          value: '${need.units} ${need.units == 1 ? 'Unit' : 'Units'}',
        ),
        const _RequirementLine(label: 'Type:', value: 'Whole Blood'),
        _RequirementLine(label: 'Urgency:', value: need.urgency.label),
        const _RequirementLine(label: 'Age Group:', value: '18 - 60 years'),
        const _RequirementLine(
          label: 'Health Condition:',
          value: 'Good health preferred',
        ),
      ],
    );
  }
}

class _RequirementLine extends StatelessWidget {
  const _RequirementLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xffe5161d), size: 14),
          const SizedBox(width: 12),
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff343741),
                fontSize: AppFontSizes.smallMetadata,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: AppFontSizes.smallMetadata,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgencyChip extends StatelessWidget {
  const _UrgencyChip({required this.need});

  final BloodNeedRequest need;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffffd5d8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(need.urgency.icon, color: need.urgency.color, size: 15),
          const SizedBox(width: 6),
          Text(
            need.urgency.label,
            style: TextStyle(
              color: need.urgency.color,
              fontSize: AppFontSizes.smallMetadata,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitsPill extends StatelessWidget {
  const _UnitsPill({required this.units});

  final int units;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffffeef0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$units ${units == 1 ? 'Unit' : 'Units'}',
            style: const TextStyle(
              color: Color(0xffe5161d),
              fontSize: AppFontSizes.cardTitle,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Units Needed',
            style: TextStyle(
              color: Color(0xff343741),
              fontSize: AppFontSizes.smallMetadata,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final NeedStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: status.tint,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: AppFontSizes.smallMetadata,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffeaf8ed),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Verified',
        style: TextStyle(
          color: Color(0xff119048),
          fontSize: AppFontSizes.smallMetadata,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Divider(height: 1, color: Color(0xffeeeef3)),
    );
  }
}

BoxDecoration _cardDecoration({Color color = Colors.white}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xffececf1)),
    boxShadow: const [
      BoxShadow(color: Color(0x08000000), blurRadius: 14, offset: Offset(0, 6)),
    ],
  );
}

String _requestCode(BloodNeedRequest need) {
  final compactId = need.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  final suffix = compactId.length <= 8
      ? compactId
      : compactId.substring(compactId.length - 8);
  return '#REQ-$suffix';
}

String _formatRequestedDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute $suffix';
}

String _statusDescription(NeedStatus status) {
  return switch (status) {
    NeedStatus.open => 'This request is open and looking for donors.',
    NeedStatus.inProgress => 'This request is currently being coordinated.',
    NeedStatus.fulfilled => 'This request has been fulfilled.',
    NeedStatus.cancelled => 'This request has been cancelled.',
  };
}
