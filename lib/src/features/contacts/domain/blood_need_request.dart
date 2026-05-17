import 'package:flutter/material.dart';

class BloodNeedRequest {
  const BloodNeedRequest({
    required this.id,
    required this.patientName,
    required this.summary,
    required this.bloodGroup,
    required this.hospital,
    required this.date,
    required this.time,
    required this.requester,
    required this.phone,
    String? contactPersonName,
    String? contactPersonPhone,
    required this.units,
    required this.urgency,
    required this.status,
    required this.sortRank,
    required this.updatedAt,
    this.potentialDonorIds = const [],
  }) : _contactPersonName = contactPersonName,
       _contactPersonPhone = contactPersonPhone;

  final String id;
  final String patientName;
  final String summary;
  final String bloodGroup;
  final String hospital;
  final String date;
  final String time;
  final String requester;
  final String phone;
  final String? _contactPersonName;
  final String? _contactPersonPhone;
  String get contactPersonName => _contactPersonName ?? requester;
  String get contactPersonPhone => _contactPersonPhone ?? phone;
  final int units;
  final NeedUrgency urgency;
  final NeedStatus status;
  final int sortRank;
  final DateTime updatedAt;
  final List<String> potentialDonorIds;

  BloodNeedRequest copyWith({
    String? patientName,
    String? summary,
    String? bloodGroup,
    String? hospital,
    String? date,
    String? time,
    String? requester,
    String? phone,
    String? contactPersonName,
    String? contactPersonPhone,
    int? units,
    NeedUrgency? urgency,
    NeedStatus? status,
    int? sortRank,
    DateTime? updatedAt,
    List<String>? potentialDonorIds,
  }) {
    return BloodNeedRequest(
      id: id,
      patientName: patientName ?? this.patientName,
      summary: summary ?? this.summary,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      hospital: hospital ?? this.hospital,
      date: date ?? this.date,
      time: time ?? this.time,
      requester: requester ?? this.requester,
      phone: phone ?? this.phone,
      contactPersonName: contactPersonName ?? _contactPersonName,
      contactPersonPhone: contactPersonPhone ?? _contactPersonPhone,
      units: units ?? this.units,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      sortRank: sortRank ?? this.sortRank,
      updatedAt: updatedAt ?? this.updatedAt,
      potentialDonorIds: potentialDonorIds ?? this.potentialDonorIds,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'patientName': patientName,
      'summary': summary,
      'bloodGroup': bloodGroup,
      'hospital': hospital,
      'date': date,
      'time': time,
      'requester': requester,
      'phone': phone,
      'contactPersonName': contactPersonName,
      'contactPersonPhone': contactPersonPhone,
      'units': units,
      'urgency': urgency.name,
      'status': status.name,
      'sortRank': sortRank,
      'updatedAt': updatedAt.toIso8601String(),
      'potentialDonorIds': potentialDonorIds,
    };
  }

  factory BloodNeedRequest.fromJson(Map<String, Object?> json) {
    String readString(String key, {String fallback = ''}) {
      final value = json[key];
      if (value == null) return fallback;
      if (value is String) return value;
      return value.toString();
    }

    final sortRank =
        json['sortRank'] as int? ??
        DateTime.tryParse(
          readString('updatedAt'),
        )?.millisecondsSinceEpoch ??
        0;

    return BloodNeedRequest(
      id: readString('id', fallback: 'need-$sortRank'),
      patientName: readString('patientName'),
      summary: readString('summary'),
      bloodGroup: readString('bloodGroup'),
      hospital: readString('hospital'),
      date: readString('date'),
      time: readString('time'),
      requester: readString('requester'),
      phone: readString('phone'),
      contactPersonName: readString(
        'contactPersonName',
        fallback: readString('requester'),
      ),
      contactPersonPhone: readString(
        'contactPersonPhone',
        fallback: readString('phone'),
      ),
      units: json['units'] as int? ?? 1,
      urgency: NeedUrgency.values.firstWhere(
        (value) => value.name == json['urgency'],
        orElse: () => NeedUrgency.normal,
      ),
      status: NeedStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => NeedStatus.open,
      ),
      sortRank: sortRank,
      updatedAt:
          DateTime.tryParse(readString('updatedAt')) ??
          DateTime.fromMillisecondsSinceEpoch(sortRank),
      potentialDonorIds:
          (json['potentialDonorIds'] as List<Object?>? ?? const [])
              .whereType<String>()
              .toList(),
    );
  }
}

enum NeedUrgency {
  urgent('Urgent', Icons.crisis_alert, Color(0xffe5161d)),
  normal('Normal', Icons.schedule, Color(0xffff8a00));

  const NeedUrgency(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

enum NeedStatus {
  open('Open', Color(0xff16a34a), Color(0xffeef9f0)),
  fulfilled('Fulfilled', Color(0xff1d74e8), Color(0xffedf4ff)),
  closed('Closed', Color(0xff4b5563), Color(0xffeef1f5)),
  cancelled('Cancelled', Color(0xff6f7480), Color(0xfff1f2f4));

  const NeedStatus(this.label, this.color, this.tint);

  final String label;
  final Color color;
  final Color tint;
}
