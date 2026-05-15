import 'dart:async';
import 'dart:convert';

import 'package:blood_contacts/src/features/contacts/data/contacts_store.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;

class GoogleDriveSyncService {
  GoogleDriveSyncService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  static const syncFileName = 'blood_contacts_sync.json';
  static const metadataFileName = 'blood_contacts_sync_meta.json';
  static const backupFolderName = 'NHLMyBloodContactsStores';
  static const photosFolderName = 'contact_photos';
  static const _drivePhotoPathPrefix = 'gdrive://';
  static const _serverClientId =
      '839101368696-lvrqak9r20sdeqljqnl4knigsm6vkvo9.apps.googleusercontent.com';
  static const _scopes = [drive.DriveApi.driveFileScope];
  static Future<void>? _sharedInitializeFuture;

  final GoogleSignIn _googleSignIn;

  static Future<void> initializeGoogleSignIn({GoogleSignIn? googleSignIn}) {
    return _sharedInitializeFuture ??= (googleSignIn ?? GoogleSignIn.instance)
        .initialize(serverClientId: _serverClientId);
  }

  Future<GoogleDriveSyncResult> sync({
    required ContactsStore store,
    bool allowInteractiveAuth = false,
  }) async {
    final context = await _driveApi(allowInteractiveAuth: allowInteractiveAuth);
    final driveApi = context.driveApi;
    final folderId =
        await _findFolder(driveApi, backupFolderName) ??
        await _createFolder(driveApi, backupFolderName);
    final photosFolderId =
        await _findFolder(driveApi, photosFolderName, parentId: folderId) ??
        await _createFolder(driveApi, photosFolderName, parentId: folderId);
    final remoteFile = await _findSyncFile(driveApi, folderId);
    final remoteSnapshot = remoteFile == null
        ? null
        : await _downloadSnapshot(driveApi, remoteFile.id!);

    final localSnapshot = SyncSnapshot(
      contacts: await store.exportContactSyncRecords(),
      needs: await store.exportNeedSyncRecords(),
    );
    final driveLocalSnapshot = await _prepareContactPhotosForDrive(
      driveApi,
      photosFolderId: photosFolderId,
      snapshot: localSnapshot,
    );
    final mergedSnapshot = SyncSnapshot.merge(
      driveLocalSnapshot,
      remoteSnapshot,
    );
    final hydratedSnapshot = await _hydrateContactPhotos(
      driveApi,
      snapshot: mergedSnapshot,
    );

    await store.applySyncedSnapshot(
      contacts: hydratedSnapshot.contacts,
      needs: mergedSnapshot.needs,
    );
    final uploadedFile = await _uploadSnapshot(
      driveApi,
      folderId: folderId,
      fileId: remoteFile?.id,
      snapshot: mergedSnapshot,
    );
    await _uploadMetadata(
      driveApi,
      folderId: folderId,
      contactCount: mergedSnapshot.activeContactCount,
      needCount: mergedSnapshot.activeNeedCount,
      photoCount: mergedSnapshot.drivePhotoCount,
      accountEmail: context.accountEmail,
    );

    return GoogleDriveSyncResult(
      folderId: folderId,
      fileId: uploadedFile.id ?? remoteFile?.id,
      accountEmail: context.accountEmail,
      contactCount: mergedSnapshot.activeContactCount,
      needCount: mergedSnapshot.activeNeedCount,
    );
  }

  Future<GoogleDriveConnection> connect() async {
    final context = await _driveApi(
      allowInteractiveAuth: true,
      forceInteractiveAuth: true,
    );
    final driveApi = context.driveApi;
    final folderId =
        await _findFolder(driveApi, backupFolderName) ??
        await _createFolder(driveApi, backupFolderName);
    await _findFolder(driveApi, photosFolderName, parentId: folderId) ??
        await _createFolder(driveApi, photosFolderName, parentId: folderId);
    return GoogleDriveConnection(
      folderId: folderId,
      accountEmail: context.accountEmail,
    );
  }

  Future<_DriveApiContext> _driveApi({
    required bool allowInteractiveAuth,
    bool forceInteractiveAuth = false,
  }) async {
    await _ensureInitialized();
    GoogleSignInAccount? account;
    GoogleSignInClientAuthorization? authorization;

    if (forceInteractiveAuth) {
      await _googleSignIn.signOut();
      account = await _authenticate(allowInteractiveAuth: true);
      if (account == null) {
        throw StateError('Google Drive connection was not completed.');
      }
      authorization =
          await account.authorizationClient.authorizationForScopes(_scopes) ??
          await account.authorizationClient.authorizeScopes(_scopes);
    } else {
      account = await _authenticate(allowInteractiveAuth: false);
      authorization =
          await account?.authorizationClient.authorizationForScopes(_scopes) ??
          await _googleSignIn.authorizationClient.authorizationForScopes(
            _scopes,
          );
    }

    if (authorization == null && allowInteractiveAuth) {
      account = await _authenticate(allowInteractiveAuth: true);
      if (account == null) {
        throw StateError('Google Drive needs reconnect before syncing.');
      }
      authorization =
          await account.authorizationClient.authorizationForScopes(_scopes) ??
          await account.authorizationClient.authorizeScopes(_scopes);
    }

    if (authorization == null) {
      throw StateError('Google Drive needs reconnect before syncing.');
    }
    final auth.AuthClient client = authorization.authClient(scopes: _scopes);
    return _DriveApiContext(
      driveApi: drive.DriveApi(client),
      accountEmail: account?.email,
    );
  }

  Future<void> _ensureInitialized() {
    return initializeGoogleSignIn(googleSignIn: _googleSignIn);
  }

  Future<void> deleteBackup({bool allowInteractiveAuth = false}) async {
    final context = await _driveApi(allowInteractiveAuth: allowInteractiveAuth);
    final driveApi = context.driveApi;
    final folderId = await _findFolder(driveApi, backupFolderName);
    if (folderId == null) return;
    final backupFile = await _findSyncFile(driveApi, folderId);
    final metadataFile = await _findMetadataFile(driveApi, folderId);
    final photosFolder = await _findFolder(
      driveApi,
      photosFolderName,
      parentId: folderId,
    );
    for (final fileId in [
      backupFile?.id,
      metadataFile?.id,
      photosFolder,
    ].whereType<String>()) {
      await driveApi.files.delete(fileId);
    }
  }

  Future<GoogleSignInAccount?> _authenticate({
    required bool allowInteractiveAuth,
  }) async {
    final lightweight = _googleSignIn.attemptLightweightAuthentication();
    final existing = lightweight == null ? null : await lightweight;
    if (existing != null) return existing;
    if (!allowInteractiveAuth) {
      return null;
    }
    return _googleSignIn.authenticate(scopeHint: _scopes);
  }

  Future<String?> _findFolder(
    drive.DriveApi driveApi,
    String folderName, {
    String? parentId,
  }) async {
    final trimmed = folderName.trim().isEmpty
        ? 'Blood Contacts Backup'
        : folderName.trim();
    final escapedName = _escapeDriveQueryString(trimmed);
    final parentClause = parentId == null ? '' : " and '$parentId' in parents";
    final folders = await driveApi.files.list(
      q: "name = '$escapedName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false$parentClause",
      spaces: 'drive',
      pageSize: 1,
      $fields: 'files(id,name)',
    );
    final existing = folders.files?.firstOrNull;
    return existing?.id;
  }

  Future<String> _createFolder(
    drive.DriveApi driveApi,
    String folderName, {
    String? parentId,
  }) async {
    final trimmed = folderName.trim().isEmpty
        ? 'Blood Contacts Backup'
        : folderName.trim();
    final folder = drive.File()
      ..name = trimmed
      ..mimeType = 'application/vnd.google-apps.folder';
    if (parentId != null) {
      folder.parents = [parentId];
    }
    final created = await driveApi.files.create(folder, $fields: 'id,name');
    if (created.id == null) {
      throw StateError('Google Drive did not return a folder id.');
    }
    return created.id!;
  }

  Future<drive.File?> _findSyncFile(
    drive.DriveApi driveApi,
    String folderId,
  ) async {
    return _findFileByName(
      driveApi,
      folderId: folderId,
      fileName: syncFileName,
    );
  }

  Future<drive.File?> _findMetadataFile(
    drive.DriveApi driveApi,
    String folderId,
  ) async {
    return _findFileByName(
      driveApi,
      folderId: folderId,
      fileName: metadataFileName,
    );
  }

  Future<drive.File?> _findPhotoFile(
    drive.DriveApi driveApi, {
    required String photosFolderId,
    required String contactId,
  }) {
    return _findFileByName(
      driveApi,
      folderId: photosFolderId,
      fileName: _contactPhotoFileName(contactId),
    );
  }

  Future<drive.File?> _findFileByName(
    drive.DriveApi driveApi, {
    required String folderId,
    required String fileName,
  }) async {
    final escapedFileName = _escapeDriveQueryString(fileName);
    final files = await driveApi.files.list(
      q: "name = '$escapedFileName' and '$folderId' in parents and trashed = false",
      spaces: 'drive',
      pageSize: 1,
      $fields: 'files(id,name,modifiedTime)',
    );
    return files.files?.firstOrNull;
  }

  Future<SyncSnapshot> _downloadSnapshot(
    drive.DriveApi driveApi,
    String fileId,
  ) async {
    final bytes = await _downloadFileBytes(driveApi, fileId);
    final jsonText = utf8.decode(bytes);
    final json = jsonDecode(jsonText) as Map<String, Object?>;
    return SyncSnapshot.fromJson(json);
  }

  Future<drive.File> _uploadSnapshot(
    drive.DriveApi driveApi, {
    required String folderId,
    required String? fileId,
    required SyncSnapshot snapshot,
  }) {
    final jsonBytes = utf8.encode(jsonEncode(snapshot.toJson()));
    final media = commons.Media(
      Stream<List<int>>.value(jsonBytes),
      jsonBytes.length,
      contentType: 'application/json',
    );
    final metadata = drive.File()
      ..name = syncFileName
      ..mimeType = 'application/json';

    if (fileId == null) {
      metadata.parents = [folderId];
      return driveApi.files.create(
        metadata,
        uploadMedia: media,
        $fields: 'id,name,modifiedTime',
      );
    }

    return driveApi.files.update(
      metadata,
      fileId,
      uploadMedia: media,
      $fields: 'id,name,modifiedTime',
    );
  }

  Future<SyncSnapshot> _prepareContactPhotosForDrive(
    drive.DriveApi driveApi, {
    required String photosFolderId,
    required SyncSnapshot snapshot,
  }) async {
    final contacts = <ContactSyncRecord>[];

    for (final record in snapshot.contacts) {
      final contact = record.contact;
      if (record.deletedAt != null) {
        final existingPhoto = await _findPhotoFile(
          driveApi,
          photosFolderId: photosFolderId,
          contactId: contact.id,
        );
        final fileId = existingPhoto?.id;
        if (fileId != null) {
          await driveApi.files.delete(fileId);
        }
        contacts.add(
          ContactSyncRecord(
            contact: _copyContactPhoto(contact, photoPath: null),
            deletedAt: record.deletedAt,
          ),
        );
        continue;
      }

      final photoBytes = contact.photoBytes;
      if (photoBytes == null || photoBytes.isEmpty) {
        contacts.add(
          ContactSyncRecord(
            contact: _copyContactPhoto(
              contact,
              photoPath: _isDrivePhotoPath(contact.photoPath)
                  ? contact.photoPath
                  : null,
            ),
            deletedAt: record.deletedAt,
          ),
        );
        continue;
      }

      final uploadedPhoto = await _uploadContactPhoto(
        driveApi,
        photosFolderId: photosFolderId,
        contactId: contact.id,
        bytes: photoBytes,
      );
      contacts.add(
        ContactSyncRecord(
          contact: _copyContactPhoto(
            contact,
            photoPath: _drivePhotoPath(
              uploadedPhoto.id!,
              _contactPhotoFileName(contact.id),
            ),
          ),
          deletedAt: record.deletedAt,
        ),
      );
    }

    return SyncSnapshot(contacts: contacts, needs: snapshot.needs);
  }

  Future<drive.File> _uploadContactPhoto(
    drive.DriveApi driveApi, {
    required String photosFolderId,
    required String contactId,
    required Uint8List bytes,
  }) async {
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 512,
      minHeight: 512,
      quality: 76,
      format: CompressFormat.jpeg,
    );
    final fileName = _contactPhotoFileName(contactId);
    final existingFile = await _findPhotoFile(
      driveApi,
      photosFolderId: photosFolderId,
      contactId: contactId,
    );
    final media = commons.Media(
      Stream<List<int>>.value(compressed),
      compressed.length,
      contentType: 'image/jpeg',
    );
    final metadata = drive.File()
      ..name = fileName
      ..mimeType = 'image/jpeg';
    final fileId = existingFile?.id;

    if (fileId == null) {
      metadata.parents = [photosFolderId];
      return driveApi.files.create(
        metadata,
        uploadMedia: media,
        $fields: 'id,name,modifiedTime',
      );
    }

    return driveApi.files.update(
      metadata,
      fileId,
      uploadMedia: media,
      $fields: 'id,name,modifiedTime',
    );
  }

  Future<SyncSnapshot> _hydrateContactPhotos(
    drive.DriveApi driveApi, {
    required SyncSnapshot snapshot,
  }) async {
    final contacts = <ContactSyncRecord>[];

    for (final record in snapshot.contacts) {
      final photoPath = record.contact.photoPath;
      final fileId = _drivePhotoFileId(photoPath);
      if (record.deletedAt != null || fileId == null) {
        contacts.add(record);
        continue;
      }

      try {
        final bytes = await _downloadFileBytes(driveApi, fileId);
        contacts.add(
          ContactSyncRecord(
            contact: _copyContactPhoto(
              record.contact,
              photoPath: photoPath,
              photoBase64: base64Encode(bytes),
            ),
            deletedAt: record.deletedAt,
          ),
        );
      } catch (_) {
        contacts.add(record);
      }
    }

    return SyncSnapshot(contacts: contacts, needs: snapshot.needs);
  }

  Future<List<int>> _downloadFileBytes(
    drive.DriveApi driveApi,
    String fileId,
  ) async {
    final media =
        await driveApi.files.get(
              fileId,
              downloadOptions: commons.DownloadOptions.fullMedia,
            )
            as commons.Media;
    return media.stream.expand((chunk) => chunk).toList();
  }

  Future<void> _uploadMetadata(
    drive.DriveApi driveApi, {
    required String folderId,
    required int contactCount,
    required int needCount,
    required int photoCount,
    required String? accountEmail,
  }) async {
    final existingFile = await _findMetadataFile(driveApi, folderId);
    final deviceMetadata = await _deviceMetadata();
    final payload = {
      'folderName': backupFolderName,
      'syncFileName': syncFileName,
      'syncedAt': DateTime.now().toUtc().toIso8601String(),
      'accountEmail': accountEmail,
      'device': deviceMetadata,
      'counts': {'contacts': contactCount, 'needs': needCount},
      'media': {'photosFolderName': photosFolderName, 'photoCount': photoCount},
    };
    final jsonBytes = utf8.encode(jsonEncode(payload));
    final media = commons.Media(
      Stream<List<int>>.value(jsonBytes),
      jsonBytes.length,
      contentType: 'application/json',
    );
    final metadata = drive.File()
      ..name = metadataFileName
      ..mimeType = 'application/json';

    final fileId = existingFile?.id;
    if (fileId == null) {
      metadata.parents = [folderId];
      await driveApi.files.create(
        metadata,
        uploadMedia: media,
        $fields: 'id,name,modifiedTime',
      );
      return;
    }

    await driveApi.files.update(
      metadata,
      fileId,
      uploadMedia: media,
      $fields: 'id,name,modifiedTime',
    );
  }

  String _escapeDriveQueryString(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  }

  Future<Map<String, Object?>> _deviceMetadata() async {
    final plugin = DeviceInfoPlugin();
    final base = <String, Object?>{
      'platform': defaultTargetPlatform.name,
      'isWeb': kIsWeb,
    };

    try {
      if (kIsWeb) {
        final info = await plugin.webBrowserInfo;
        return {
          ...base,
          'browserName': info.browserName.name,
          'appName': info.appName,
          'appVersion': info.appVersion,
          'platformName': info.platform,
          'userAgent': info.userAgent,
          'vendor': info.vendor,
          'language': info.language,
        };
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await plugin.androidInfo;
          return {
            ...base,
            'manufacturer': info.manufacturer,
            'brand': info.brand,
            'model': info.model,
            'device': info.device,
            'product': info.product,
            'hardware': info.hardware,
            'id': info.id,
            'isPhysicalDevice': info.isPhysicalDevice,
            'supportedAbis': info.supportedAbis,
            'android': {
              'release': info.version.release,
              'sdkInt': info.version.sdkInt,
              'incremental': info.version.incremental,
              'baseOS': info.version.baseOS,
              'securityPatch': info.version.securityPatch,
            },
          };
        case TargetPlatform.iOS:
          final info = await plugin.iosInfo;
          return {
            ...base,
            'name': info.name,
            'model': info.model,
            'localizedModel': info.localizedModel,
            'systemName': info.systemName,
            'systemVersion': info.systemVersion,
            'identifierForVendor': info.identifierForVendor,
            'isPhysicalDevice': info.isPhysicalDevice,
            'utsname': {
              'machine': info.utsname.machine,
              'release': info.utsname.release,
              'sysname': info.utsname.sysname,
              'version': info.utsname.version,
            },
          };
        case TargetPlatform.macOS:
          final info = await plugin.macOsInfo;
          return {
            ...base,
            'computerName': info.computerName,
            'hostName': info.hostName,
            'model': info.model,
            'kernelVersion': info.kernelVersion,
            'osRelease': info.osRelease,
            'activeCPUs': info.activeCPUs,
            'memorySize': info.memorySize,
          };
        case TargetPlatform.windows:
          final info = await plugin.windowsInfo;
          return {
            ...base,
            'computerName': info.computerName,
            'numberOfCores': info.numberOfCores,
            'systemMemoryInMegabytes': info.systemMemoryInMegabytes,
            'userName': info.userName,
            'majorVersion': info.majorVersion,
            'minorVersion': info.minorVersion,
            'buildNumber': info.buildNumber,
          };
        case TargetPlatform.linux:
          final info = await plugin.linuxInfo;
          return {
            ...base,
            'name': info.name,
            'version': info.version,
            'id': info.id,
            'idLike': info.idLike,
            'prettyName': info.prettyName,
            'machineId': info.machineId,
          };
        case TargetPlatform.fuchsia:
          return base;
      }
    } catch (error) {
      return {...base, 'metadataError': error.toString()};
    }
  }

  String _contactPhotoFileName(String contactId) {
    return 'contact_$contactId.jpg';
  }

  String _drivePhotoPath(String fileId, String fileName) {
    return '$_drivePhotoPathPrefix$fileId/$fileName';
  }

  bool _isDrivePhotoPath(String? value) {
    return value?.startsWith(_drivePhotoPathPrefix) ?? false;
  }

  String? _drivePhotoFileId(String? value) {
    if (!_isDrivePhotoPath(value)) return null;
    final withoutPrefix = value!.substring(_drivePhotoPathPrefix.length);
    return withoutPrefix.split('/').firstOrNull;
  }

  BloodContact _copyContactPhoto(
    BloodContact contact, {
    required String? photoPath,
    String? photoBase64,
  }) {
    return BloodContact(
      id: contact.id,
      name: contact.name,
      phone: contact.phone,
      email: contact.email,
      photoPath: photoPath,
      photoBase64: photoBase64,
      bloodGroup: contact.bloodGroup,
      availability: contact.availability,
      lastDonationDate: contact.lastDonationDate,
      note: contact.note,
      saveToPhoneContacts: contact.saveToPhoneContacts,
      updatedAt: contact.updatedAt,
    );
  }
}

class GoogleDriveConnection {
  const GoogleDriveConnection({
    required this.folderId,
    required this.accountEmail,
  });

  final String folderId;
  final String? accountEmail;
}

class SyncSnapshot {
  const SyncSnapshot({required this.contacts, required this.needs});

  static const schemaVersion = 1;

  final List<ContactSyncRecord> contacts;
  final List<NeedSyncRecord> needs;

  int get activeContactCount =>
      contacts.where((record) => record.deletedAt == null).length;
  int get activeNeedCount =>
      needs.where((record) => record.deletedAt == null).length;
  int get drivePhotoCount => contacts
      .where(
        (record) =>
            record.deletedAt == null &&
            (record.contact.photoPath?.startsWith(
                  GoogleDriveSyncService._drivePhotoPathPrefix,
                ) ??
                false),
      )
      .length;

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'contacts': contacts.map((record) => record.toJson()).toList(),
      'needs': needs.map((record) => record.toJson()).toList(),
    };
  }

  factory SyncSnapshot.fromJson(Map<String, Object?> json) {
    final contactItems = json['contacts'] as List<Object?>? ?? const [];
    final needItems = json['needs'] as List<Object?>? ?? const [];
    return SyncSnapshot(
      contacts: contactItems
          .map(
            (item) => ContactSyncRecord.fromJson(item as Map<String, Object?>),
          )
          .toList(),
      needs: needItems
          .map((item) => NeedSyncRecord.fromJson(item as Map<String, Object?>))
          .toList(),
    );
  }

  static SyncSnapshot merge(SyncSnapshot local, SyncSnapshot? remote) {
    if (remote == null) return local;
    return SyncSnapshot(
      contacts: _mergeContactRecordsByNormalizedPhone(
        _mergeById<ContactSyncRecord>(
          local.contacts,
          remote.contacts,
          idOf: (record) => record.contact.id,
          versionOf: (record) => record.versionTime,
        ),
      ),
      needs: _mergeById<NeedSyncRecord>(
        local.needs,
        remote.needs,
        idOf: (record) => record.need.id,
        versionOf: (record) => record.versionTime,
      ),
    );
  }

  static List<T> _mergeById<T>(
    List<T> local,
    List<T> remote, {
    required String Function(T record) idOf,
    required DateTime Function(T record) versionOf,
  }) {
    final merged = <String, T>{};
    for (final record in [...remote, ...local]) {
      final id = idOf(record);
      final existing = merged[id];
      if (existing == null || versionOf(record).isAfter(versionOf(existing))) {
        merged[id] = record;
      }
    }
    return merged.values.toList();
  }

  static List<ContactSyncRecord> _mergeContactRecordsByNormalizedPhone(
    List<ContactSyncRecord> records,
  ) {
    final merged = <String, ContactSyncRecord>{};
    final recordsWithoutPhone = <ContactSyncRecord>[];

    for (final record in records) {
      final phone = normalizedPhoneNumber(record.contact.phone);
      if (phone.isEmpty) {
        recordsWithoutPhone.add(record);
        continue;
      }

      final existing = merged[phone];
      if (existing == null ||
          record.versionTime.isAfter(existing.versionTime)) {
        merged[phone] = record;
      }
    }

    return [...recordsWithoutPhone, ...merged.values];
  }
}

class GoogleDriveSyncResult {
  const GoogleDriveSyncResult({
    required this.folderId,
    required this.fileId,
    required this.accountEmail,
    required this.contactCount,
    required this.needCount,
  });

  final String folderId;
  final String? fileId;
  final String? accountEmail;
  final int contactCount;
  final int needCount;
}

class _DriveApiContext {
  const _DriveApiContext({required this.driveApi, required this.accountEmail});

  final drive.DriveApi driveApi;
  final String? accountEmail;
}
