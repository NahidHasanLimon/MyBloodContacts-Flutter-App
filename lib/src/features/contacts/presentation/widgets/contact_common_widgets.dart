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
