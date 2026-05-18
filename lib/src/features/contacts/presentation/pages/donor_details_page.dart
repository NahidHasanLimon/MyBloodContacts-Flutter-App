import 'package:blood_contacts/src/app/app_theme.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';
import 'package:blood_contacts/src/features/contacts/presentation/widgets/contact_common_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class DonorDetailsPage extends StatelessWidget {
  const DonorDetailsPage({
    super.key,
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  final BloodContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final red = bloodGroupColors[contact.bloodGroup] ?? _bloodRed;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              sliver: SliverList.list(
                children: [
                  _DetailsHeader(
                    onBack: () => Navigator.pop(context),
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
                  const SizedBox(height: 12),
                  _HeroCard(
                    contact: contact,
                    red: red,
                    onCall: () => _openDialer(context),
                    onMessage: () => _openMessenger(context),
                    onWhatsApp: () => _openWhatsApp(context),
                    onShare: () => _shareContact(context),
                    onCopyNumber: () => _copyNumber(context),
                  ),
                  const SizedBox(height: 12),
                  _InfoSectionCard(
                    icon: Icons.person_outline,
                    title: 'Donor Information',
                    child: _DonorInfoCombinedContent(
                      contact: contact,
                      red: red,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PrimaryActionsRow(onEdit: onEdit, onDelete: onDelete),
                  const SizedBox(height: 14),
                  const _PrivacyFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareContact(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final note = contact.note.trim();
    final remarks = note.isEmpty
        ? 'Please contact directly before planning a donation.'
        : note;

    await SharePlus.instance.share(
      ShareParams(
        subject: 'Blood donor contact: ${_valueOrNA(contact.name)}',
        text:
            '''
Blood donor contact

Name: ${_valueOrNA(contact.name)}
Blood group: ${_valueOrNA(contact.bloodGroup)}
Mobile: ${_valueOrNA(contact.phone)}
Email: ${_valueOrNA(contact.email)}
Area: ${_valueOrNA(contact.area)}
Availability: ${contact.isAvailable ? 'Can donate now' : 'Currently unavailable'}
Remarks: $remarks
'''
                .trim(),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  void _copyNumber(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _valueOrNA(contact.phone)));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Phone number copied')));
  }

  Future<void> _openDialer(BuildContext context) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Call contact?',
      message: 'Do you want to call ${contact.phone}?',
      confirmLabel: 'Call',
      destructive: false,
    );
    if (confirmed != true || !context.mounted) return;

    final uri = Uri(scheme: 'tel', path: contact.phone);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open dialer')));
    }
  }

  Future<void> _openMessenger(BuildContext context) async {
    final uri = Uri(scheme: 'smsto', path: contact.phone);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open messages')));
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final phoneForWhatsApp = contact.phone.replaceAll(RegExp(r'\D'), '');
    final directUri = Uri.parse('whatsapp://send?phone=$phoneForWhatsApp');
    var opened = await launchUrl(directUri, mode: LaunchMode.externalApplication);
    if (!opened) {
      final webFallback = Uri.parse('https://wa.me/$phoneForWhatsApp');
      opened = await launchUrl(webFallback, mode: LaunchMode.externalApplication);
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
    }
  }
}

class _DonorInfoCombinedContent extends StatelessWidget {
  const _DonorInfoCombinedContent({required this.contact, required this.red});

  final BloodContact contact;
  final Color red;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DonorInformationGrid(contact: contact, red: red),
        const SizedBox(height: 20),
        const Divider(color: _dividerColor, height: 1),
        const SizedBox(height: 12),
        _AvailabilityTile(contact: contact),
        const SizedBox(height: 20),
        const Divider(color: _dividerColor, height: 1),
        const SizedBox(height: 12),
        _NotesContent(contact: contact),
      ],
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Back',
          onPressed: onBack,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              Text(
                'Contact Details',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.black,
                  fontSize: AppFontSizes.sectionTitle,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'View donor information and details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _mutedText,
                  fontSize: AppFontSizes.bodyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        PopupMenuButton<_DetailsAction>(
          tooltip: 'More options',
          color: Colors.white,
          offset: const Offset(0, 52),
          onSelected: (action) {
            switch (action) {
              case _DetailsAction.edit:
                onEdit();
              case _DetailsAction.delete:
                onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: _DetailsAction.edit, child: Text('Edit')),
            PopupMenuItem(value: _DetailsAction.delete, child: Text('Delete')),
          ],
          child: const _HeaderIconButtonShell(icon: Icons.more_vert),
        ),
      ],
    );
  }
}

enum _DetailsAction { edit, delete }

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: _HeaderIconButtonShell(icon: icon),
      ),
    );
  }
}

class _HeaderIconButtonShell extends StatelessWidget {
  const _HeaderIconButtonShell({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
        boxShadow: _softShadow,
      ),
      child: Icon(icon, color: _bloodRed, size: 18),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.contact,
    required this.red,
    required this.onCall,
    required this.onMessage,
    required this.onWhatsApp,
    required this.onShare,
    required this.onCopyNumber,
  });

  final BloodContact contact;
  final Color red;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onWhatsApp;
  final VoidCallback onShare;
  final VoidCallback onCopyNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(color: const Color(0xfffff0f0)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            const Positioned(right: -18, top: 36, child: _BloodDrops()),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _AvatarWithStatus(contact: contact, red: red),
                      const SizedBox(width: 12),
                      Expanded(child: _HeroDetails(contact: contact)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.call_outlined,
                          tooltip: 'Call',
                          onPressed: onCall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.message_outlined,
                          tooltip: 'Message',
                          onPressed: onMessage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionTile(
                          customIcon: const FaIcon(
                            FontAwesomeIcons.whatsapp,
                            color: Color(0xff25D366),
                            size: 20,
                          ),
                          tooltip: 'WhatsApp',
                          onPressed: onWhatsApp,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.share_outlined,
                          tooltip: 'Share',
                          onPressed: onShare,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.content_copy_outlined,
                          tooltip: 'Copy number',
                          onPressed: onCopyNumber,
                        ),
                      ),
                    ],
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

class _AvatarWithStatus extends StatelessWidget {
  const _AvatarWithStatus({required this.contact, required this.red});

  final BloodContact contact;
  final Color red;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ContactAvatar(
          contact: contact,
          radius: 42,
          backgroundColor: const Color(0xffffdada),
          foregroundColor: red,
          border: Border.all(color: Colors.white, width: 5),
          textStyle: TextStyle(
            color: red,
            fontSize: AppFontSizes.pageTitle - 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        Positioned(
          right: 5,
          bottom: 5,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: _softShadow,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: contact.isAvailable ? _successGreen : _bloodRed,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroDetails extends StatelessWidget {
  const _HeroDetails({required this.contact});

  final BloodContact contact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _valueOrNA(contact.name),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontSize: AppFontSizes.sectionTitle,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusPill(
              icon: Icons.water_drop_outlined,
              label: contact.bloodGroup,
              foreground: _bloodRed,
              border: const Color(0xffffbfc1),
              background: Colors.white.withValues(alpha: 0.72),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _HeroMeta(icon: Icons.phone_outlined, text: _valueOrNA(contact.phone)),
        const SizedBox(height: 8),
        _HeroMeta(
          icon: Icons.location_on_outlined,
          text: _valueOrNA(contact.area),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.border,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color border;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 16),
          const SizedBox(width: 6),
          Text(
            _valueOrNA(label),
            style: TextStyle(
              color: foreground,
              fontSize: AppFontSizes.smallMetadata,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _mutedText, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: AppFontSizes.bodyText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    this.icon,
    this.customIcon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData? icon;
  final Widget? customIcon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _cardBorder),
              boxShadow: const [
                BoxShadow(color: Color(0x05000000), blurRadius: 8),
              ],
            ),
            alignment: Alignment.center,
            child:
                customIcon ??
                Icon(icon ?? Icons.circle_outlined, color: _bloodRed, size: 18),
          ),
        ),
      ),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  const _InfoSectionCard({
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
              Icon(icon, color: _bloodRed, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: AppFontSizes.sectionTitle,
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

class _DonorInformationGrid extends StatelessWidget {
  const _DonorInformationGrid({required this.contact, required this.red});

  final BloodContact contact;
  final Color red;

  @override
  Widget build(BuildContext context) {
    final items = [
      _DetailItemData(
        icon: Icons.person_outline,
        label: 'Full Name',
        value: _valueOrNA(contact.name),
      ),
      _DetailItemData(
        icon: Icons.water_drop_outlined,
        iconColor: red,
        label: 'Blood Group',
        value: _valueOrNA(contact.bloodGroup),
      ),
      _DetailItemData(
        icon: Icons.phone_outlined,
        label: 'Phone',
        value: _valueOrNA(contact.phone),
      ),
      if (contact.email.trim().isNotEmpty)
        _DetailItemData(
          icon: Icons.email_outlined,
          label: 'Email',
          value: contact.email.trim(),
        ),
      if (contact.lastDonationDate != null)
        _DetailItemData(
          icon: Icons.calendar_today_outlined,
          label: 'Last Donation',
          value: _formatFullDate(contact.lastDonationDate),
        ),
      _DetailItemData(
        icon: Icons.update_outlined,
        label: 'Updated',
        value: _formatFullDate(contact.updatedAt),
      ),
      _DetailItemData(
        icon: Icons.contact_phone_outlined,
        label: 'Saved to Phone',
        value: contact.saveToPhoneContacts ? 'Yes' : 'No',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        if (isNarrow) {
          return Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _DetailItem(data: items[index]),
                if (index != items.length - 1) const _RowDivider(),
              ],
            ],
          );
        }

        return Column(children: _desktopRows(items));
      },
    );
  }

  List<Widget> _desktopRows(List<_DetailItemData> items) {
    final rows = <Widget>[];
    for (var index = 0; index < items.length; index += 2) {
      final hasPair = index + 1 < items.length;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _DetailItem(data: items[index])),
            if (hasPair) ...[
              const SizedBox(width: 14),
              Container(width: 1, height: 48, color: _dividerColor),
              const SizedBox(width: 14),
              Expanded(child: _DetailItem(data: items[index + 1])),
            ] else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
      if (index + 2 < items.length) rows.add(const _RowDivider());
    }
    return rows;
  }
}

class _DetailItemData {
  const _DetailItemData({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = _mutedText,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.data});

  final _DetailItemData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(data.icon, color: data.iconColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: const TextStyle(
                  color: _mutedText,
                  fontSize: AppFontSizes.smallMetadata,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: AppFontSizes.bodyText,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(color: _dividerColor, height: 1),
    );
  }
}

class _AvailabilityTile extends StatelessWidget {
  const _AvailabilityTile({required this.contact});

  final BloodContact contact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xfffaf8f6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            contact.isAvailable
                ? Icons.check_circle_outline
                : Icons.block_outlined,
            size: 16,
            color: contact.isAvailable ? _successGreen : _bloodRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.isAvailable ? 'Available' : 'Unavailable',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: AppFontSizes.cardTitle,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  contact.availability.statusText,
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: AppFontSizes.smallMetadata,
                    fontWeight: FontWeight.w500,
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

class _NotesContent extends StatelessWidget {
  const _NotesContent({required this.contact});

  final BloodContact contact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MetadataLabel('Notes'),
        const SizedBox(height: 6),
        Text(
          _valueOrNA(contact.note),
          style: const TextStyle(
            color: Colors.black,
            fontSize: AppFontSizes.cardTitle,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _MetadataLabel extends StatelessWidget {
  const _MetadataLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _mutedText,
        fontSize: AppFontSizes.smallMetadata,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PrimaryActionsRow extends StatelessWidget {
  const _PrimaryActionsRow({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: const Color(0xff343741),
              textStyle: const TextStyle(
                fontSize: AppFontSizes.buttonText,
                fontWeight: FontWeight.w900,
              ),
              side: const BorderSide(color: Color(0xffd8dbe3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: _bloodRed,
              textStyle: const TextStyle(
                fontSize: AppFontSizes.buttonText,
                fontWeight: FontWeight.w900,
              ),
              side: const BorderSide(color: Color(0xffffbfc1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xfffff7f7),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrivacyFooter extends StatelessWidget {
  const _PrivacyFooter();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, color: _mutedText, size: 18),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Information is private and only visible to you',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _mutedText,
              fontSize: AppFontSizes.smallMetadata,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _BloodDrops extends StatelessWidget {
  const _BloodDrops();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.22,
      child: SizedBox(
        width: 126,
        height: 202,
        child: Stack(
          children: [
            Positioned(
              right: 34,
              top: 12,
              child: Icon(Icons.water_drop, color: _bloodRed, size: 74),
            ),
            Positioned(
              right: 0,
              top: 74,
              child: Icon(Icons.water_drop, color: _bloodRed, size: 124),
            ),
            Positioned(
              right: 70,
              top: 70,
              child: Icon(Icons.water_drop, color: _bloodRed, size: 96),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({Color color = Colors.white}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _cardBorder),
    boxShadow: _softShadow,
  );
}

String _valueOrNA(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? 'n/a' : trimmed;
}

String _formatFullDate(DateTime? date) {
  if (date == null) return 'n/a';
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

const _bloodRed = Color(0xffe5161d);
const _successGreen = Color(0xff0e9f3f);
const _mutedText = Color(0xff3f4254);
const _pageBackground = Colors.white;
const _cardBorder = Color(0xffffdedf);
const _dividerColor = Color(0xffffe5e5);

const _softShadow = [
  BoxShadow(color: Color(0x08000000), blurRadius: 18, offset: Offset(0, 8)),
];
