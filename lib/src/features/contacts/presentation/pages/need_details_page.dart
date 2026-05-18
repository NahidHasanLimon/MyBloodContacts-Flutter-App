import 'package:blood_contacts/src/app/app_theme.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_need_request.dart';
import 'package:blood_contacts/src/features/contacts/presentation/pages/new_need_page.dart';
import 'package:blood_contacts/src/features/contacts/presentation/widgets/contact_common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final actionsLocked =
        _need.status == NeedStatus.fulfilled ||
        _need.status == NeedStatus.closed ||
        _need.status == NeedStatus.cancelled;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 20),
              sliver: SliverList.list(
                children: [
                  _NeedDetailsHeader(
                    onBack: () => Navigator.pop(context),
                    onShare: () => _shareNeed(context),
                    onEdit: () => _editNeed(context),
                    onClose: actionsLocked
                        ? null
                        : () => _closeRequest(context),
                    onCancel: actionsLocked
                        ? null
                        : () => _cancelRequest(context),
                  ),
                  const SizedBox(height: 12),
                  _NeedSummaryCard(need: _need, red: red),
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.business_outlined,
                    title: 'Hospital',
                    child: _HospitalContent(need: _need),
                  ),
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Status',
                    child: _StatusContent(need: _need),
                  ),
                  const SizedBox(height: 10),
                  _PotentialDonorsCard(
                    count: _need.potentialDonorIds.length,
                    onViewAll: () => _showPotentialDonors(context),
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
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _need.status.tint,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'Current: ${_need.status.label}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _need.status.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: actionsLocked
                          ? null
                          : () => _cancelRequest(context),
                      icon: const Icon(Icons.block_outlined),
                      label: Text(
                        _need.status == NeedStatus.cancelled
                            ? 'Cancelled'
                            : 'Cancel',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: const Color(0xff6f7480),
                        disabledForegroundColor:
                            _need.status == NeedStatus.cancelled
                            ? const Color(0xff6f7480)
                            : null,
                        backgroundColor: _need.status == NeedStatus.cancelled
                            ? const Color(0xfff1f2f4)
                            : Colors.white,
                        disabledBackgroundColor:
                            _need.status == NeedStatus.cancelled
                            ? const Color(0xfff1f2f4)
                            : null,
                        iconColor: const Color(0xffd97706),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                        side: const BorderSide(color: Color(0xffd8dbe3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: actionsLocked
                          ? null
                          : () => _closeRequest(context),
                      icon: const Icon(Icons.cancel_outlined),
                      label: Text(
                        _need.status == NeedStatus.closed ? 'Closed' : 'Close',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: _need.status == NeedStatus.closed
                            ? const Color(0xff374151)
                            : Colors.black,
                        disabledForegroundColor:
                            _need.status == NeedStatus.closed
                            ? const Color(0xff374151)
                            : null,
                        backgroundColor: _need.status == NeedStatus.closed
                            ? const Color(0xffeef1f5)
                            : Colors.white,
                        disabledBackgroundColor:
                            _need.status == NeedStatus.closed
                            ? const Color(0xffeef1f5)
                            : null,
                        iconColor: const Color(0xffe5161d),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                        side: const BorderSide(color: Color(0xffd8dbe3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: actionsLocked
                          ? null
                          : () => _markFulfilled(context),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        _need.status == NeedStatus.fulfilled
                            ? 'Fulfilled'
                            : 'Fulfilled',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: _need.status == NeedStatus.fulfilled
                            ? const Color(0xff16a34a)
                            : Colors.white,
                        disabledBackgroundColor:
                            _need.status == NeedStatus.fulfilled
                            ? const Color(0xff16a34a)
                            : null,
                        foregroundColor: _need.status == NeedStatus.fulfilled
                            ? Colors.white
                            : const Color(0xff16a34a),
                        disabledForegroundColor:
                            _need.status == NeedStatus.fulfilled
                            ? Colors.white
                            : null,
                        iconColor: _need.status == NeedStatus.fulfilled
                            ? const Color(0xffeafff2)
                            : const Color(0xff16a34a),
                        side: const BorderSide(color: Color(0xffb9dfc7)),
                        textStyle: const TextStyle(
                          fontSize: 12,
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
Contact: ${_need.contactPersonPhone}
Description: ${_need.summary}
'''
                .trim(),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _showPotentialDonors(BuildContext context) async {
    final matchingContacts =
        widget.contacts
            .where((contact) => contact.bloodGroup == _need.bloodGroup)
            .toList()
          ..sort(sortContacts);

    final selectedDonorIds = await showModalBottomSheet<Set<String>?>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PotentialDonorSelectionSheet(
        contacts: matchingContacts,
        selectedDonorIds: _need.potentialDonorIds.toSet(),
      ),
    );

    if (selectedDonorIds == null || !context.mounted) return;
    if (_isSameSelection(_need.potentialDonorIds, selectedDonorIds)) return;

    final updated = _need.copyWith(
      potentialDonorIds: selectedDonorIds.toList(),
      updatedAt: DateTime.now(),
    );
    setState(() => _need = updated);
    widget.onChanged(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Potential donor list updated')),
    );
  }

  bool _isSameSelection(List<String> existingIds, Set<String> nextIds) {
    if (existingIds.length != nextIds.length) return false;
    return existingIds.toSet().containsAll(nextIds);
  }

  Future<void> _markFulfilled(BuildContext context) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Mark fulfilled?',
      message: 'Are you sure you want to mark this need as fulfilled?',
      confirmLabel: 'Yes, Mark Fulfilled',
    );
    if (confirmed != true || !context.mounted) return;

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
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Close request?',
      message: 'This need will be marked as closed.',
      confirmLabel: 'Close Request',
    );
    if (confirmed != true || !context.mounted) return;

    final updated = _need.copyWith(
      status: NeedStatus.closed,
      updatedAt: DateTime.now(),
    );
    setState(() => _need = updated);
    widget.onChanged(updated);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request closed.')));
  }

  Future<void> _cancelRequest(BuildContext context) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Cancel request?',
      message: 'This need will be marked as cancelled.',
      confirmLabel: 'Cancel Request',
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
    ).showSnackBar(const SnackBar(content: Text('Request cancelled.')));
  }

  Future<void> _editNeed(BuildContext context) async {
    final updated = await Navigator.of(context).push<BloodNeedRequest>(
      MaterialPageRoute(builder: (context) => NewNeedPage(initialNeed: _need)),
    );
    if (updated == null || !context.mounted) return;
    setState(() => _need = updated);
    widget.onChanged(updated);
  }
}

class _NeedDetailsHeader extends StatelessWidget {
  const _NeedDetailsHeader({
    required this.onBack,
    required this.onShare,
    required this.onEdit,
    required this.onClose,
    required this.onCancel,
  });

  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onClose;
  final VoidCallback? onCancel;

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
              case _NeedAction.edit:
                onEdit?.call();
                break;
              case _NeedAction.close:
                onClose?.call();
                break;
              case _NeedAction.cancel:
                onCancel?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _NeedAction.edit,
              enabled: onEdit != null,
              child: const Text('Edit Request'),
            ),
            PopupMenuItem(
              value: _NeedAction.cancel,
              enabled: onCancel != null,
              child: const Text('Cancel Request'),
            ),
            PopupMenuItem(
              value: _NeedAction.close,
              enabled: onClose != null,
              child: const Text('Close Request'),
            ),
          ],
        ),
      ],
    );
  }
}

enum _NeedAction { edit, close, cancel }

class _NeedSummaryCard extends StatelessWidget {
  const _NeedSummaryCard({required this.need, required this.red});

  final BloodNeedRequest need;
  final Color red;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${need.urgency.label} Need',
                style: TextStyle(
                  color: need.urgency.color,
                  fontSize: AppFontSizes.cardTitle,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                _requestCode(need),
                style: const TextStyle(
                  color: Color(0xff4b5262),
                  fontSize: AppFontSizes.smallMetadata,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xffeeeef3)),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.water_drop, color: red, size: 68),
                    Padding(
                      padding: const EdgeInsets.only(top: 9),
                      child: Text(
                        need.bloodGroup,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                    Row(
                      children: [
                        Text(
                          need.bloodGroup,
                          style: TextStyle(
                            color: red,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(status: need.status),
                      ],
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
            title: need.contactPersonName,
            trailing: _PhoneTrailing(
              phone: need.contactPersonPhone,
              showNumber: false,
            ),
            subtitle: need.contactPersonPhone,
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
            labelTrailing: _MetadataValue(
              value: _formatRequestedDate(need.updatedAt),
            ),
            trailing: _PhoneTrailing(phone: need.phone, showNumber: false),
            subtitle: need.phone,
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

class _PhoneTrailing extends StatelessWidget {
  const _PhoneTrailing({required this.phone, this.showNumber = true});

  final String phone;
  final bool showNumber;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showNumber) ...[
          Text(
            phone,
            style: const TextStyle(
              color: Color(0xff343741),
              fontSize: AppFontSizes.bodyText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
        ],
        SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            tooltip: 'Call contact',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: () => _confirmCall(context, phone),
            icon: const Icon(Icons.call, size: 16, color: Color(0xff16a34a)),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            tooltip: 'Copy contact',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phone));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Contact copied')));
            },
            icon: const Icon(
              Icons.content_copy,
              size: 16,
              color: Color(0xff5f6470),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmCall(BuildContext context, String phone) async {
  final confirmed = await showAppConfirmationDialog(
    context: context,
    title: 'Call contact?',
    message: 'Do you want to call $phone?',
    confirmLabel: 'Call',
    destructive: false,
  );
  if (confirmed != true || !context.mounted) return;
  final uri = Uri(scheme: 'tel', path: phone);
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open dialer')));
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
      padding: const EdgeInsets.all(14),
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
          const SizedBox(height: 10),
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
    return Row(
      children: [
        _StatusChip(status: need.status),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _statusDescription(need.status),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff343741),
              fontSize: AppFontSizes.bodyText,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
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
      padding: const EdgeInsets.all(14),
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
                label: const Text('See Available'),
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

class _PotentialDonorSelectionSheet extends StatefulWidget {
  const _PotentialDonorSelectionSheet({
    required this.contacts,
    required this.selectedDonorIds,
  });

  final List<BloodContact> contacts;
  final Set<String> selectedDonorIds;

  @override
  State<_PotentialDonorSelectionSheet> createState() =>
      _PotentialDonorSelectionSheetState();
}

class _PotentialDonorSelectionSheetState
    extends State<_PotentialDonorSelectionSheet> {
  String _query = '';
  late final Set<String> _selectedDonorIds;

  @override
  void initState() {
    super.initState();
    _selectedDonorIds = {...widget.selectedDonorIds};
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filteredContacts = widget.contacts.where((contact) {
      if (query.isEmpty) return true;
      return contact.name.toLowerCase().contains(query) ||
          contact.phone.toLowerCase().contains(query);
    }).toList();
    final sheetHeight = MediaQuery.of(context).size.height * 0.72;

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available Donors',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: AppFontSizes.sectionTitle,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap a donor to select or unselect.',
                style: TextStyle(
                  color: Color(0xff4b5262),
                  fontSize: AppFontSizes.bodyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search by name or phone',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xfff8f8fb),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xffe3e6ee)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xffe3e6ee)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xff9aa4b2)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (widget.contacts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'No donors available for this blood group yet.',
                    style: TextStyle(
                      color: Color(0xff4b5262),
                      fontSize: AppFontSizes.bodyText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (filteredContacts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'No donor matches your search.',
                    style: TextStyle(
                      color: Color(0xff4b5262),
                      fontSize: AppFontSizes.bodyText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredContacts.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
                      final selected = _selectedDonorIds.contains(contact.id);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: selected
                              ? const Color(0xffecedf2)
                              : const Color(0xffffe3e5),
                          child: Text(
                            contact.initials,
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xff757b8a)
                                  : const Color(0xffe5161d),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        title: Text(
                          contact.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? const Color(0xff757b8a)
                                : const Color(0xff151722),
                          ),
                        ),
                        subtitle: Text(
                          '${contact.bloodGroup}  •  ${contact.phone}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: selected
                            ? const _SelectedPill()
                            : const Icon(Icons.add, size: 20),
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedDonorIds.remove(contact.id);
                            } else {
                              _selectedDonorIds.add(contact.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selectedDonorIds),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedPill extends StatelessWidget {
  const _SelectedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xffeef1f5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Selected',
        style: TextStyle(
          color: Color(0xff4b5262),
          fontSize: 11,
          fontWeight: FontWeight.w800,
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
    this.labelTrailing,
  });

  final IconData icon;
  final String label;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? labelTrailing;

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xff4b5262),
                        fontSize: AppFontSizes.smallMetadata,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (labelTrailing != null) ...[
                    const SizedBox(width: 12),
                    labelTrailing!,
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: AppFontSizes.cardTitle,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 14),
                    trailing!,
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
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

class _MetadataValue extends StatelessWidget {
  const _MetadataValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xff4b5262),
        fontSize: AppFontSizes.smallMetadata,
        fontWeight: FontWeight.w700,
      ),
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
        _RequirementLine(label: 'Urgency:', value: need.urgency.label),
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

class _UnitsPill extends StatelessWidget {
  const _UnitsPill({required this.units});

  final int units;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffffeef0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$units ${units == 1 ? 'Unit' : 'Units'}',
        style: const TextStyle(
          color: Color(0xffe5161d),
          fontSize: AppFontSizes.bodyText,
          fontWeight: FontWeight.w900,
        ),
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

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
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
    NeedStatus.fulfilled => 'This request has been fulfilled.',
    NeedStatus.closed => 'This request has been closed.',
    NeedStatus.cancelled => 'This request has been cancelled.',
  };
}
