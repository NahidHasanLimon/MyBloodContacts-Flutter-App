import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:flutter/material.dart';

class ContactAvatar extends StatelessWidget {
  const ContactAvatar({
    super.key,
    required this.contact,
    required this.radius,
    required this.backgroundColor,
    required this.foregroundColor,
    this.border,
    this.textStyle,
  });

  final BloodContact contact;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final BoxBorder? border;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final bytes = contact.photoBytes;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: border,
        image: bytes == null
            ? null
            : DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: bytes == null
          ? Text(
              contact.initials,
              style:
                  textStyle ??
                  TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w900,
                  ),
            )
          : null,
    );
  }
}

class BloodGroupBadge extends StatelessWidget {
  const BloodGroupBadge({super.key, required this.group, required this.color});

  final String group;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        group,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AppDialogOption<T> {
  const AppDialogOption({
    required this.value,
    required this.label,
    this.destructive = false,
    this.filled = false,
  });

  final T value;
  final String label;
  final bool destructive;
  final bool filled;
}

Future<bool?> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: const Color(0x66231616),
    builder: (context) => _AppDialogShell(
      title: title,
      message: message,
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: _dialogOutlineButtonStyle(compact: true),
              child: Text(cancelLabel),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: _dialogFilledButtonStyle(
                destructive: destructive,
                compact: true,
              ),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<T?> showAppOptionsDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  required List<AppDialogOption<T>> options,
  String cancelLabel = 'Cancel',
}) {
  return showDialog<T>(
    context: context,
    barrierColor: const Color(0x66231616),
    builder: (context) => _AppDialogShell(
      title: title,
      message: message,
      actions: [
        for (final option in options) ...[
          SizedBox(
            width: double.infinity,
            child: option.filled
                ? FilledButton(
                    onPressed: () => Navigator.pop(context, option.value),
                    style: _dialogFilledButtonStyle(
                      destructive: option.destructive,
                    ),
                    child: Text(option.label),
                  )
                : OutlinedButton(
                    onPressed: () => Navigator.pop(context, option.value),
                    style: _dialogOutlineButtonStyle(),
                    child: Text(option.label),
                  ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: _dialogOutlineButtonStyle(),
            child: Text(cancelLabel),
          ),
        ),
      ],
    ),
  );
}

ButtonStyle _dialogOutlineButtonStyle({bool compact = false}) {
  return OutlinedButton.styleFrom(
    minimumSize: compact ? const Size(0, 40) : const Size.fromHeight(44),
    padding: compact
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 0)
        : null,
    foregroundColor: const Color(0xff5f6470),
    side: const BorderSide(color: Color(0xffd8dbe3)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
  );
}

ButtonStyle _dialogFilledButtonStyle({
  required bool destructive,
  bool compact = false,
}) {
  return FilledButton.styleFrom(
    minimumSize: compact ? const Size(0, 40) : const Size.fromHeight(44),
    padding: compact
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 0)
        : null,
    backgroundColor: destructive
        ? const Color(0xffe5161d)
        : const Color(0xff16a34a),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
  );
}

class _AppDialogShell extends StatelessWidget {
  const _AppDialogShell({
    required this.title,
    required this.message,
    required this.actions,
  });

  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        decoration: BoxDecoration(
          color: const Color(0xfffffbf8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffffe5de)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1c7a2a1e),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DialogBadgeIcon(),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xff201716),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xff665653),
                fontSize: 14,
                height: 1.28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _DialogBadgeIcon extends StatelessWidget {
  const _DialogBadgeIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffffede9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline, size: 14, color: Color(0xffe5161d)),
            SizedBox(width: 4),
            Text(
              'Confirm',
              style: TextStyle(
                color: Color(0xffc9141a),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
