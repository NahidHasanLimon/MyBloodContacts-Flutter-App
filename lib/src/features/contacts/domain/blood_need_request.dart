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
    required this.units,
    required this.urgency,
    required this.status,
    required this.sortRank,
    required this.updatedAt,
  });

  final String id;
  final String patientName;
  final String summary;
  final String bloodGroup;
  final String hospital;
  final String date;
  final String time;
  final String requester;
  final String phone;
  final int units;
  final NeedUrgency urgency;
  final NeedStatus status;
  final int sortRank;
  final DateTime updatedAt;

  BloodNeedRequest copyWith({
    String? patientName,
    String? summary,
    String? bloodGroup,
    String? hospital,
    String? date,
    String? time,
    String? requester,
    String? phone,
    int? units,
    NeedUrgency? urgency,
    NeedStatus? status,
    int? sortRank,
    DateTime? updatedAt,
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
      units: units ?? this.units,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      sortRank: sortRank ?? this.sortRank,
      updatedAt: updatedAt ?? this.updatedAt,
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
      'units': units,
      'urgency': urgency.name,
      'status': status.name,
      'sortRank': sortRank,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BloodNeedRequest.fromJson(Map<String, Object?> json) {
    final sortRank =
        json['sortRank'] as int? ??
        DateTime.tryParse(
          json['updatedAt'] as String? ?? '',
        )?.millisecondsSinceEpoch ??
        0;

    return BloodNeedRequest(
      id: json['id'] as String? ?? 'need-$sortRank',
      patientName: json['patientName'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      bloodGroup: json['bloodGroup'] as String? ?? '',
      hospital: json['hospital'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      requester: json['requester'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
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
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(sortRank),
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
  inProgress('In Progress', Color(0xffff8a00), Color(0xfffff5e6)),
  fulfilled('Fulfilled', Color(0xff1d74e8), Color(0xffedf4ff)),
  cancelled('Cancelled', Color(0xff6f7480), Color(0xfff1f2f4));

  const NeedStatus(this.label, this.color, this.tint);

  final String label;
  final Color color;
  final Color tint;
}
