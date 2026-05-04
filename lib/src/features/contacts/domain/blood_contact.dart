class BloodContact {
  const BloodContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.bloodGroup,
    this.note = '',
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String bloodGroup;
  final String note;
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
    return !note.toLowerCase().contains('unavailable');
  }

  bool get isNearby {
    final normalizedNote = note.toLowerCase();
    return normalizedNote.contains('nearby') ||
        normalizedNote.contains('mirpur') ||
        normalizedNote.contains('dhaka');
  }

  BloodContact copyWith({
    String? name,
    String? phone,
    String? bloodGroup,
    String? note,
  }) {
    return BloodContact(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      note: note ?? this.note,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'note': note,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BloodContact.fromJson(Map<String, Object?> json) {
    return BloodContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      bloodGroup: json['bloodGroup'] as String,
      note: json['note'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

int sortContacts(BloodContact a, BloodContact b) {
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
