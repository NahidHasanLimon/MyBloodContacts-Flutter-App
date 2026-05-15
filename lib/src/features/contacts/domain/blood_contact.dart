import 'dart:convert';
import 'dart:typed_data';

import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';

class BloodContact {
  const BloodContact({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.photoPath,
    this.photoBase64,
    required this.bloodGroup,
    this.availability = DonorAvailability.available,
    this.lastDonationDate,
    this.note = '',
    this.saveToPhoneContacts = false,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String? photoPath;
  final String? photoBase64;
  final String bloodGroup;
  final DonorAvailability availability;
  final DateTime? lastDonationDate;
  final String note;
  final bool saveToPhoneContacts;
  final DateTime updatedAt;

  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  String get area {
    final parts = note.split(',');
    return parts.first.trim().isEmpty ? 'Local contact' : parts.first.trim();
  }

  bool get isAvailable {
    return availability == DonorAvailability.available &&
        !note.toLowerCase().contains('unavailable');
  }

  bool get isNearby {
    final normalizedNote = note.toLowerCase();
    return normalizedNote.contains('nearby') ||
        normalizedNote.contains('mirpur') ||
        normalizedNote.contains('dhaka');
  }

  Uint8List? get photoBytes {
    final encoded = photoBase64;
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  }

  BloodContact copyWith({
    String? name,
    String? phone,
    String? email,
    String? photoPath,
    String? photoBase64,
    String? bloodGroup,
    DonorAvailability? availability,
    DateTime? lastDonationDate,
    String? note,
    bool? saveToPhoneContacts,
  }) {
    return BloodContact(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
      photoBase64: photoBase64 ?? this.photoBase64,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      availability: availability ?? this.availability,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      note: note ?? this.note,
      saveToPhoneContacts: saveToPhoneContacts ?? this.saveToPhoneContacts,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'photoPath': photoPath,
      'photoBase64': photoBase64,
      'bloodGroup': bloodGroup,
      'availability': availability.name,
      'lastDonationDate': lastDonationDate?.toIso8601String(),
      'note': note,
      'saveToPhoneContacts': saveToPhoneContacts,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BloodContact.fromJson(Map<String, Object?> json) {
    return BloodContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String? ?? '',
      photoPath: json['photoPath'] as String?,
      photoBase64: json['photoBase64'] as String?,
      bloodGroup: json['bloodGroup'] as String,
      availability: DonorAvailability.values.firstWhere(
        (value) => value.name == json['availability'],
        orElse: () => DonorAvailability.available,
      ),
      lastDonationDate: DateTime.tryParse(
        json['lastDonationDate'] as String? ?? '',
      ),
      note: json['note'] as String? ?? '',
      saveToPhoneContacts: json['saveToPhoneContacts'] as bool? ?? false,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

int sortContacts(BloodContact a, BloodContact b) {
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

String normalizedPhoneNumber(String phone) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  }
  // Normalize Bangladesh mobile formats so +8801XXXXXXXXX, 8801XXXXXXXXX,
  // and 01XXXXXXXXX are treated as the same number.
  if (digits.startsWith('880') && digits.length >= 13) {
    digits = '0${digits.substring(3)}';
  } else if (digits.startsWith('1') && digits.length == 10) {
    digits = '0$digits';
  }
  return digits;
}
