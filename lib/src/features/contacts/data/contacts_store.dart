import 'dart:convert';

import 'package:blood_contacts/src/features/contacts/domain/app_notification.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_need_request.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class ContactsStore {
  ContactsStore(this._prefs, {sqflite.DatabaseFactory? databaseFactory})
    : _databaseFactory = databaseFactory ?? sqflite.databaseFactory;

  static const _databaseName = 'blood_contacts.db';
  static const _databaseVersion = 3;
  static const _contactsTable = 'contacts';
  static const _needsTable = 'needs';
  static const _notificationsTable = 'notifications';
  static const _legacyContactsKey = 'blood_contacts.contacts';
  static const _legacyContactsMigratedKey =
      'blood_contacts.contacts_sqlite_migrated';
  static const _driveFolderKey = 'blood_contacts.drive_folder';
  static const _driveEmailKey = 'blood_contacts.drive_email';
  static const _syncHistoryKey = 'blood_contacts.sync_history';
  static const _lastSyncStatusKey = 'blood_contacts.last_sync_status';
  static const _autoSyncEnabledKey = 'blood_contacts.auto_sync_enabled';
  static const _lastAutoSyncAttemptAtKey =
      'blood_contacts.last_auto_sync_attempt_at';
  static const _autoSyncEnabledDayKey = 'blood_contacts.auto_sync_enabled_day';
  static const _autoSyncAttemptDayKey = 'blood_contacts.auto_sync_attempt_day';
  static const _autoSyncAttemptCountKey =
      'blood_contacts.auto_sync_attempt_count';
  static const _notifySyncFailedKey = 'blood_contacts.notify_sync_failed';
  static const _notifySyncStaleKey = 'blood_contacts.notify_sync_stale';
  static const _notifySyncEventsKey = 'blood_contacts.notify_sync_events';
  static const _onboardingCompletedKey = 'blood_contacts.onboarding_completed';

  final SharedPreferences _prefs;
  final sqflite.DatabaseFactory _databaseFactory;
  sqflite.Database? _database;

  Future<void> init() async {
    _database = await _openDatabase();
    await _migrateLegacyContacts();
    await _dedupePersistedContacts();
  }

  Future<List<BloodContact>> loadContacts() async {
    final rows = await _db.query(
      _contactsTable,
      where: 'deleted_at IS NULL',
      orderBy: 'LOWER(name) ASC',
    );
    return _dedupeContactsByNormalizedPhone(rows.map(_contactFromRow).toList());
  }

  Future<List<ContactSyncRecord>> exportContactSyncRecords() async {
    final rows = await _db.query(_contactsTable);
    return _dedupeContactRecordsByNormalizedPhone(
      rows.map((row) {
        return ContactSyncRecord(
          contact: _contactFromRow(row),
          deletedAt: DateTime.tryParse(row['deleted_at'] as String? ?? ''),
        );
      }).toList(),
    );
  }

  Future<void> saveContacts(List<BloodContact> contacts) async {
    final dedupedContacts = _dedupeContactsByNormalizedPhone(contacts);
    await _db.transaction((txn) async {
      final existingRows = await txn.query(
        _contactsTable,
        columns: ['id'],
        where: 'deleted_at IS NULL',
      );
      final nextIds = dedupedContacts.map((contact) => contact.id).toSet();

      for (final row in existingRows) {
        final id = row['id'] as String;
        if (!nextIds.contains(id)) {
          await txn.update(
            _contactsTable,
            {
              'deleted_at': DateTime.now().toIso8601String(),
              'sync_status': 'pending_delete',
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }

      for (final contact in dedupedContacts) {
        await txn.insert(
          _contactsTable,
          _contactToRow(contact),
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<BloodNeedRequest>> loadNeeds() async {
    final rows = await _db.query(
      _needsTable,
      where: 'deleted_at IS NULL',
      orderBy: 'sort_rank DESC',
    );

    return rows.map(_needFromRow).toList()
      ..sort((a, b) => b.sortRank.compareTo(a.sortRank));
  }

  Future<List<NeedSyncRecord>> exportNeedSyncRecords() async {
    final rows = await _db.query(_needsTable);
    return rows.map((row) {
      return NeedSyncRecord(
        need: _needFromRow(row),
        deletedAt: DateTime.tryParse(row['deleted_at'] as String? ?? ''),
      );
    }).toList();
  }

  Future<void> saveNeeds(
    List<BloodNeedRequest> needs, {
    bool markSynced = false,
  }) async {
    await _db.transaction((txn) async {
      final existingRows = await txn.query(
        _needsTable,
        columns: ['id'],
        where: 'deleted_at IS NULL',
      );
      final nextIds = needs.map((need) => need.id).toSet();

      for (final row in existingRows) {
        final id = row['id'] as String;
        if (!nextIds.contains(id)) {
          await txn.update(
            _needsTable,
            {
              'deleted_at': DateTime.now().toIso8601String(),
              'sync_status': 'pending_delete',
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }

      for (final need in needs) {
        await txn.insert(
          _needsTable,
          _needToRow(need, markSynced: markSynced),
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> applySyncedSnapshot({
    required List<ContactSyncRecord> contacts,
    required List<NeedSyncRecord> needs,
  }) async {
    final syncedAt = DateTime.now().toIso8601String();
    final dedupedContacts = _dedupeContactRecordsByNormalizedPhone(contacts);
    await _db.transaction((txn) async {
      final syncedContactIds = dedupedContacts
          .map((record) => record.contact.id)
          .toSet();
      final existingContactRows = await txn.query(
        _contactsTable,
        columns: ['id'],
        where: 'deleted_at IS NULL',
      );

      for (final row in existingContactRows) {
        final id = row['id'] as String;
        if (!syncedContactIds.contains(id)) {
          await txn.update(
            _contactsTable,
            {
              'deleted_at': syncedAt,
              'sync_status': 'synced',
              'last_synced_at': syncedAt,
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }

      for (final record in dedupedContacts) {
        final row = _contactToRow(record.contact)
          ..['deleted_at'] = record.deletedAt?.toIso8601String()
          ..['sync_status'] = 'synced'
          ..['last_synced_at'] = syncedAt;
        await txn.insert(
          _contactsTable,
          row,
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }

      for (final record in needs) {
        final row = _needToRow(record.need, markSynced: true)
          ..['deleted_at'] = record.deletedAt?.toIso8601String()
          ..['last_synced_at'] = syncedAt;
        await txn.insert(
          _needsTable,
          row,
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
    });
  }

  String? loadDriveFolder() => _prefs.getString(_driveFolderKey);

  Future<void> saveDriveFolder(String folderName) {
    return _prefs.setString(_driveFolderKey, folderName);
  }

  String? loadDriveEmail() => _prefs.getString(_driveEmailKey);

  Future<void> saveDriveEmail(String email) {
    return _prefs.setString(_driveEmailKey, email);
  }

  Future<void> clearDriveConnection() async {
    await _prefs.remove(_driveFolderKey);
    await _prefs.remove(_driveEmailKey);
    await _prefs.remove(_lastSyncStatusKey);
  }

  String? loadLastSyncStatus() => _prefs.getString(_lastSyncStatusKey);

  Future<void> saveLastSyncStatus(String status) {
    return _prefs.setString(_lastSyncStatusKey, status);
  }

  List<SyncHistoryEntry> loadSyncHistory() {
    final values = _prefs.getStringList(_syncHistoryKey) ?? const [];
    final entries =
        values
            .map(SyncHistoryEntry.tryParse)
            .whereType<SyncHistoryEntry>()
            .toList()
          ..sort((a, b) => b.at.compareTo(a.at));
    return entries;
  }

  Future<void> addSyncHistory(
    DateTime syncedAt, {
    required String status,
    int? contactCount,
    int? needCount,
    String? message,
  }) async {
    final nextHistory = [
      SyncHistoryEntry(
        at: syncedAt,
        status: status,
        contactCount: contactCount,
        needCount: needCount,
        message: message,
      ).serialize(),
      ...loadSyncHistory().map((entry) => entry.serialize()),
    ];
    await _prefs.setStringList(_syncHistoryKey, nextHistory);
  }

  bool loadAutoSyncEnabled() => _prefs.getBool(_autoSyncEnabledKey) ?? false;

  Future<void> saveAutoSyncEnabled(bool enabled) {
    return _prefs.setBool(_autoSyncEnabledKey, enabled);
  }

  Future<void> markAutoSyncEnabledAt(DateTime at) {
    return _prefs.setString(_autoSyncEnabledDayKey, _formatDayKey(at));
  }

  DateTime? loadLastAutoSyncAttemptAt() {
    final raw = _prefs.getString(_lastAutoSyncAttemptAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> saveLastAutoSyncAttemptAt(DateTime at) {
    return _prefs.setString(_lastAutoSyncAttemptAtKey, at.toIso8601String());
  }

  int loadAutoSyncAttemptCountForDay(DateTime day) {
    final storedDay = _prefs.getString(_autoSyncAttemptDayKey);
    final expectedDay = _formatDayKey(day);
    if (storedDay != expectedDay) return 0;
    return _prefs.getInt(_autoSyncAttemptCountKey) ?? 0;
  }

  Future<void> recordAutoSyncAttempt(DateTime at) async {
    final storedDay = _prefs.getString(_autoSyncAttemptDayKey);
    final expectedDay = _formatDayKey(at);
    final currentCount = storedDay == expectedDay
        ? (_prefs.getInt(_autoSyncAttemptCountKey) ?? 0)
        : 0;
    await _prefs.setString(_autoSyncAttemptDayKey, expectedDay);
    await _prefs.setInt(_autoSyncAttemptCountKey, currentCount + 1);
    await saveLastAutoSyncAttemptAt(at);
  }

  Future<void> resetAutoSyncAttemptTracking(DateTime at) async {
    await _prefs.setString(_autoSyncAttemptDayKey, _formatDayKey(at));
    await _prefs.setInt(_autoSyncAttemptCountKey, 0);
  }

  bool canAttemptAutoSyncNow(
    DateTime now, {
    int maxAttemptsPerDay = 3,
    Duration retryInterval = const Duration(minutes: 30),
  }) {
    final enabledDay = _prefs.getString(_autoSyncEnabledDayKey);
    final today = _formatDayKey(now);
    if (enabledDay == today) return false;

    final attemptsToday = loadAutoSyncAttemptCountForDay(now);
    if (attemptsToday >= maxAttemptsPerDay) return false;

    final lastAttempt = loadLastAutoSyncAttemptAt();
    if (lastAttempt == null) return true;

    final lastAttemptDay = _formatDayKey(lastAttempt);
    if (lastAttemptDay != today) return true;

    final status = loadLastSyncStatus() ?? '';
    if (status == 'success') return false;

    return now.difference(lastAttempt) >= retryInterval;
  }

  String _formatDayKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  bool loadNotifySyncFailedEnabled() =>
      _prefs.getBool(_notifySyncFailedKey) ?? true;

  Future<void> saveNotifySyncFailedEnabled(bool enabled) {
    return _prefs.setBool(_notifySyncFailedKey, enabled);
  }

  bool loadNotifySyncStaleEnabled() =>
      _prefs.getBool(_notifySyncStaleKey) ?? true;

  Future<void> saveNotifySyncStaleEnabled(bool enabled) {
    return _prefs.setBool(_notifySyncStaleKey, enabled);
  }

  bool loadNotifySyncEventsEnabled() =>
      _prefs.getBool(_notifySyncEventsKey) ?? true;

  Future<void> saveNotifySyncEventsEnabled(bool enabled) {
    return _prefs.setBool(_notifySyncEventsKey, enabled);
  }

  bool loadOnboardingCompleted() =>
      _prefs.getBool(_onboardingCompletedKey) ?? false;

  Future<void> saveOnboardingCompleted(bool completed) {
    return _prefs.setBool(_onboardingCompletedKey, completed);
  }

  Future<List<AppNotification>> loadNotifications() async {
    final rows = await _db.query(
      _notificationsTable,
      orderBy: 'created_at DESC',
    );
    return rows.map(_notificationFromRow).toList();
  }

  Future<int> unreadNotificationsCount() async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $_notificationsTable WHERE read_at IS NULL',
    );
    return (rows.first['count'] as int?) ?? 0;
  }

  Future<void> upsertNotification({
    required String code,
    required String title,
    required String message,
    DateTime? createdAt,
  }) async {
    final now = createdAt ?? DateTime.now();
    await _db.insert(_notificationsTable, {
      'code': code,
      'title': title,
      'message': message,
      'created_at': now.toIso8601String(),
      'read_at': null,
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  Future<void> deleteNotificationByCode(String code) async {
    await _db.delete(_notificationsTable, where: 'code = ?', whereArgs: [code]);
  }

  Future<void> markAllNotificationsRead() async {
    await _db.update(_notificationsTable, {
      'read_at': DateTime.now().toIso8601String(),
    }, where: 'read_at IS NULL');
  }

  Future<void> markNotificationRead(int id) async {
    await _db.update(
      _notificationsTable,
      {'read_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markNotificationUnread(int id) async {
    await _db.update(
      _notificationsTable,
      {'read_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<sqflite.Database> _openDatabase() async {
    final databasePath = await _databaseFactory.getDatabasesPath();
    return _databaseFactory.openDatabase(
      p.join(databasePath, _databaseName),
      options: sqflite.OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: (db, version) async {
          await _createSchema(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _upgradeNeedsSchemaV2(db);
          }
          if (oldVersion < 3) {
            await _createNotificationsSchemaV3(db);
          }
        },
      ),
    );
  }

  Future<void> _createSchema(sqflite.DatabaseExecutor db) async {
    await db.execute('''
CREATE TABLE $_contactsTable (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT NOT NULL DEFAULT '',
  photo_path TEXT,
  photo_base64 TEXT,
  blood_group TEXT NOT NULL,
  availability TEXT NOT NULL,
  last_donation_date TEXT,
  note TEXT NOT NULL DEFAULT '',
  save_to_phone_contacts INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  sync_status TEXT NOT NULL DEFAULT 'pending_upsert',
  remote_id TEXT,
  last_synced_at TEXT
)
''');
    await db.execute(
      'CREATE INDEX idx_contacts_updated_at ON $_contactsTable(updated_at)',
    );
    await db.execute(
      'CREATE INDEX idx_contacts_sync_status ON $_contactsTable(sync_status)',
    );

    await db.execute('''
CREATE TABLE $_needsTable (
  id TEXT PRIMARY KEY,
  payload_json TEXT NOT NULL,
  patient_name TEXT NOT NULL,
  blood_group TEXT NOT NULL,
  hospital TEXT NOT NULL,
  urgency TEXT NOT NULL,
  status TEXT NOT NULL,
  sort_rank INTEGER NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  sync_status TEXT NOT NULL DEFAULT 'pending_upsert',
  remote_id TEXT,
  last_synced_at TEXT
)
''');
    await db.execute(
      'CREATE INDEX idx_needs_sync_status ON $_needsTable(sync_status)',
    );
    await db.execute(
      'CREATE INDEX idx_needs_sort_rank ON $_needsTable(sort_rank)',
    );
    await _createNotificationsSchemaV3(db);
  }

  Future<void> _upgradeNeedsSchemaV2(sqflite.DatabaseExecutor db) async {
    await db.execute(
      "ALTER TABLE $_needsTable ADD COLUMN patient_name TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      "ALTER TABLE $_needsTable ADD COLUMN blood_group TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      "ALTER TABLE $_needsTable ADD COLUMN hospital TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      "ALTER TABLE $_needsTable ADD COLUMN urgency TEXT NOT NULL DEFAULT 'normal'",
    );
    await db.execute(
      "ALTER TABLE $_needsTable ADD COLUMN status TEXT NOT NULL DEFAULT 'open'",
    );
    await db.execute(
      'ALTER TABLE $_needsTable ADD COLUMN sort_rank INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_needs_sort_rank ON $_needsTable(sort_rank)',
    );
  }

  Future<void> _createNotificationsSchemaV3(sqflite.DatabaseExecutor db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS $_notificationsTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  created_at TEXT NOT NULL,
  read_at TEXT
)
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON $_notificationsTable(created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notifications_read_at ON $_notificationsTable(read_at)',
    );
  }

  Future<void> _migrateLegacyContacts() async {
    if (_prefs.getBool(_legacyContactsMigratedKey) ?? false) return;

    final rawContacts = _prefs.getStringList(_legacyContactsKey) ?? [];
    if (rawContacts.isNotEmpty) {
      final contacts = <BloodContact>[];
      for (final rawContact in rawContacts) {
        try {
          contacts.add(BloodContact.fromJson(jsonDecode(rawContact)));
        } on FormatException {
          continue;
        } on TypeError {
          continue;
        }
      }
      await saveContacts(contacts);
    }

    await _prefs.setBool(_legacyContactsMigratedKey, true);
  }

  Future<void> _dedupePersistedContacts() async {
    final rows = await _db.query(_contactsTable, where: 'deleted_at IS NULL');
    final contacts = rows.map(_contactFromRow).toList();
    final keepIds = _dedupeContactsByNormalizedPhone(
      contacts,
    ).map((contact) => contact.id).toSet();
    if (keepIds.length == contacts.length) return;

    final deletedAt = DateTime.now().toIso8601String();
    await _db.transaction((txn) async {
      for (final contact in contacts) {
        if (keepIds.contains(contact.id)) continue;
        await txn.update(
          _contactsTable,
          {'deleted_at': deletedAt, 'sync_status': 'pending_delete'},
          where: 'id = ?',
          whereArgs: [contact.id],
        );
      }
    });
  }

  sqflite.Database get _db {
    final database = _database;
    if (database == null) {
      throw StateError('ContactsStore.init must be called before use.');
    }
    return database;
  }
}

class SyncHistoryEntry {
  const SyncHistoryEntry({
    required this.at,
    required this.status,
    this.contactCount,
    this.needCount,
    this.message,
  });

  final DateTime at;
  final String status;
  final int? contactCount;
  final int? needCount;
  final String? message;

  String serialize() {
    final contacts = contactCount?.toString() ?? '';
    final needs = needCount?.toString() ?? '';
    final note = message == null || message!.trim().isEmpty
        ? ''
        : Uri.encodeComponent(message!.trim());
    return '${at.toIso8601String()}|$status|$contacts|$needs|$note';
  }

  static SyncHistoryEntry? tryParse(String raw) {
    if (raw.trim().isEmpty) return null;
    final parts = raw.split('|');
    if (parts.length >= 2) {
      final date = DateTime.tryParse(parts[0]);
      if (date == null) return null;
      final contactCount = parts.length >= 3 ? int.tryParse(parts[2]) : null;
      final needCount = parts.length >= 4 ? int.tryParse(parts[3]) : null;
      final message = parts.length >= 5 && parts[4].trim().isNotEmpty
          ? Uri.decodeComponent(parts[4])
          : null;
      return SyncHistoryEntry(
        at: date,
        status: parts[1],
        contactCount: contactCount,
        needCount: needCount,
        message: message,
      );
    }

    final legacyDate = DateTime.tryParse(raw);
    if (legacyDate == null) return null;
    return SyncHistoryEntry(at: legacyDate, status: 'success');
  }
}

class ContactSyncRecord {
  const ContactSyncRecord({required this.contact, this.deletedAt});

  final BloodContact contact;
  final DateTime? deletedAt;

  DateTime get versionTime {
    final deleted = deletedAt;
    if (deleted != null && deleted.isAfter(contact.updatedAt)) return deleted;
    return contact.updatedAt;
  }

  Map<String, Object?> toJson() {
    return {
      'data': contact.toJson(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory ContactSyncRecord.fromJson(Map<String, Object?> json) {
    return ContactSyncRecord(
      contact: BloodContact.fromJson(json['data'] as Map<String, Object?>),
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
    );
  }
}

class NeedSyncRecord {
  const NeedSyncRecord({required this.need, this.deletedAt});

  final BloodNeedRequest need;
  final DateTime? deletedAt;

  DateTime get versionTime {
    final deleted = deletedAt;
    if (deleted != null && deleted.isAfter(need.updatedAt)) return deleted;
    return need.updatedAt;
  }

  Map<String, Object?> toJson() {
    return {'data': need.toJson(), 'deletedAt': deletedAt?.toIso8601String()};
  }

  factory NeedSyncRecord.fromJson(Map<String, Object?> json) {
    return NeedSyncRecord(
      need: BloodNeedRequest.fromJson(json['data'] as Map<String, Object?>),
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
    );
  }
}

Map<String, Object?> _contactToRow(BloodContact contact) {
  final normalizedPhone = normalizedPhoneNumber(contact.phone);
  return {
    'id': contact.id,
    'name': contact.name,
    'phone': normalizedPhone,
    'email': contact.email,
    'photo_path': contact.photoPath,
    'photo_base64': contact.photoBase64,
    'blood_group': contact.bloodGroup,
    'availability': contact.availability.name,
    'last_donation_date': contact.lastDonationDate?.toIso8601String(),
    'note': contact.note,
    'save_to_phone_contacts': contact.saveToPhoneContacts ? 1 : 0,
    'updated_at': contact.updatedAt.toIso8601String(),
    'deleted_at': null,
    'sync_status': 'pending_upsert',
  };
}

BloodContact _contactFromRow(Map<String, Object?> row) {
  final normalizedPhone = normalizedPhoneNumber(row['phone'] as String? ?? '');
  return BloodContact(
    id: row['id'] as String,
    name: row['name'] as String,
    phone: normalizedPhone,
    email: row['email'] as String? ?? '',
    photoPath: row['photo_path'] as String?,
    photoBase64: row['photo_base64'] as String?,
    bloodGroup: row['blood_group'] as String,
    availability: DonorAvailability.values.firstWhere(
      (value) => value.name == row['availability'],
      orElse: () => DonorAvailability.available,
    ),
    lastDonationDate: DateTime.tryParse(
      row['last_donation_date'] as String? ?? '',
    ),
    note: row['note'] as String? ?? '',
    saveToPhoneContacts: (row['save_to_phone_contacts'] as int? ?? 0) == 1,
    updatedAt:
        DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
  );
}

Map<String, Object?> _needToRow(
  BloodNeedRequest need, {
  bool markSynced = false,
}) {
  return {
    'id': need.id,
    'payload_json': jsonEncode(need.toJson()),
    'patient_name': need.patientName,
    'blood_group': need.bloodGroup,
    'hospital': need.hospital,
    'urgency': need.urgency.name,
    'status': need.status.name,
    'sort_rank': need.sortRank,
    'updated_at': need.updatedAt.toIso8601String(),
    'deleted_at': null,
    'sync_status': markSynced ? 'synced' : 'pending_upsert',
  };
}

BloodNeedRequest _needFromRow(Map<String, Object?> row) {
  final payload = jsonDecode(row['payload_json'] as String);
  return BloodNeedRequest.fromJson(payload as Map<String, Object?>);
}

AppNotification _notificationFromRow(Map<String, Object?> row) {
  return AppNotification(
    id: row['id'] as int? ?? 0,
    code: row['code'] as String? ?? '',
    title: row['title'] as String? ?? '',
    message: row['message'] as String? ?? '',
    createdAt:
        DateTime.tryParse(row['created_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    readAt: DateTime.tryParse(row['read_at'] as String? ?? ''),
  );
}

List<BloodContact> _dedupeContactsByNormalizedPhone(
  List<BloodContact> contacts,
) {
  final byPhone = <String, BloodContact>{};
  final contactsWithoutPhone = <BloodContact>[];

  for (final contact in contacts) {
    final phone = normalizedPhoneNumber(contact.phone);
    if (phone.isEmpty) {
      contactsWithoutPhone.add(contact);
      continue;
    }

    final existing = byPhone[phone];
    if (existing == null || contact.updatedAt.isAfter(existing.updatedAt)) {
      byPhone[phone] = contact;
    }
  }

  return [...contactsWithoutPhone, ...byPhone.values]..sort(sortContacts);
}

List<ContactSyncRecord> _dedupeContactRecordsByNormalizedPhone(
  List<ContactSyncRecord> records,
) {
  final byPhone = <String, ContactSyncRecord>{};
  final recordsWithoutPhone = <ContactSyncRecord>[];

  for (final record in records) {
    final phone = normalizedPhoneNumber(record.contact.phone);
    if (phone.isEmpty) {
      recordsWithoutPhone.add(record);
      continue;
    }

    final existing = byPhone[phone];
    if (existing == null || record.versionTime.isAfter(existing.versionTime)) {
      byPhone[phone] = record;
    }
  }

  return [...recordsWithoutPhone, ...byPhone.values];
}
