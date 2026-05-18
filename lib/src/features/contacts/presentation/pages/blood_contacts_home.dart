import 'dart:async';

import 'package:blood_contacts/src/features/contacts/data/contacts_store.dart';
import 'package:blood_contacts/src/features/contacts/data/google_drive_sync_service.dart';
import 'package:blood_contacts/src/features/contacts/data/background_sync_worker.dart';
import 'package:blood_contacts/src/features/contacts/domain/app_notification.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_need_request.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_stats.dart';
import 'package:blood_contacts/src/features/contacts/presentation/pages/donor_details_page.dart';
import 'package:blood_contacts/src/features/contacts/presentation/pages/need_details_page.dart';
import 'package:blood_contacts/src/features/contacts/presentation/pages/new_need_page.dart';
import 'package:blood_contacts/src/features/contacts/presentation/pages/notification_preferences_page.dart';
import 'package:blood_contacts/src/features/contacts/presentation/pages/notifications_page.dart';
import 'package:blood_contacts/src/features/contacts/presentation/widgets/contact_common_widgets.dart';
import 'package:blood_contacts/src/features/contacts/presentation/widgets/contact_widgets.dart';
import 'package:blood_contacts/src/features/contacts/presentation/widgets/profile_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:workmanager/workmanager.dart';

class BloodContactsHome extends StatefulWidget {
  const BloodContactsHome({super.key, this.databaseFactory});

  final sqflite.DatabaseFactory? databaseFactory;

  @override
  State<BloodContactsHome> createState() => _BloodContactsHomeState();
}

class _BloodContactsHomeState extends State<BloodContactsHome>
    with WidgetsBindingObserver {
  static const int _maxAutoSyncAttemptsPerDay = 3;
  static const Duration _autoSyncRetryInterval = Duration(minutes: 30);

  final _driveSyncService = GoogleDriveSyncService();

  ContactsStore? _store;
  List<BloodContact> _contacts = [];
  ContactFilter _selectedFilter = ContactFilter.all;
  String? _selectedBloodGroup;
  AppTab _selectedTab = AppTab.home;
  String _contactsQuery = '';
  String _contactsGroupFilter = 'All Groups';
  bool _contactsAvailableOnly = false;
  bool _contactsNearbyOnly = false;
  ContactsSortOption _contactsSortOption = ContactsSortOption.name;
  String _needsGroupFilter = 'All';
  NeedUrgencyFilter _needsUrgencyFilter = NeedUrgencyFilter.all;
  NeedStatusFilter _needsStatusFilter = NeedStatusFilter.all;
  String _needsQuery = '';
  NeedSortOption _needsSortOption = NeedSortOption.newest;
  List<BloodNeedRequest> _needs = [];
  String? _driveFolder;
  String? _driveEmail;
  String? _lastSyncStatus;
  List<SyncHistoryEntry> _syncHistory = [];
  bool _autoSyncEnabled = false;
  List<AppNotification> _notifications = [];
  int _notificationCount = 0;
  bool _notifySyncEvents = true;
  bool _notifySyncFailed = true;
  bool _notifySyncStale = true;
  bool _loading = true;
  bool _syncing = false;
  bool _syncActionInFlight = false;
  bool _connectingDrive = false;
  bool _showContinueChoice = false;
  bool _showRestoreProgress = false;
  bool _restoreReadyToContinue = false;
  bool _restoreFailed = false;
  bool _onboardingRestoreInProgress = false;
  int _restoreSyncedContacts = 0;
  int _restoreSyncedNeeds = 0;
  DateTime? _restoreSyncedAt;
  DateTime? _lastBackPressedAt;
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runAutoSyncIfDue();
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final store = ContactsStore(
        prefs,
        databaseFactory: widget.databaseFactory,
      );
      await store.init();
      final contacts = await store.loadContacts();
      final needs = await store.loadNeeds();
      await _refreshNotifications(store: store, shouldSetState: false);
      final notifications = await store.loadNotifications();
      final notificationCount = await store.unreadNotificationsCount();
      final autoSyncEnabled = store.loadAutoSyncEnabled();
      final notifySyncEvents = store.loadNotifySyncEventsEnabled();
      final notifySyncFailed = store.loadNotifySyncFailedEnabled();
      final notifySyncStale = store.loadNotifySyncStaleEnabled();

      if (!mounted) return;
      final savedDriveFolder = store.loadDriveFolder();
      final normalizedDriveFolder = savedDriveFolder?.trim().isNotEmpty == true
          ? GoogleDriveSyncService.backupFolderName
          : null;
      if (normalizedDriveFolder != null &&
          savedDriveFolder != normalizedDriveFolder) {
        await store.saveDriveFolder(normalizedDriveFolder);
      }
      setState(() {
        _store = store;
        _contacts = contacts;
        _needs = needs;
        _driveFolder = normalizedDriveFolder;
        _driveEmail = store.loadDriveEmail();
        _lastSyncStatus = store.loadLastSyncStatus();
        _syncHistory = store.loadSyncHistory();
        _autoSyncEnabled = autoSyncEnabled;
        _notifications = notifications;
        _notificationCount = notificationCount;
        _notifySyncEvents = notifySyncEvents;
        _notifySyncFailed = notifySyncFailed;
        _notifySyncStale = notifySyncStale;
        _showContinueChoice = !store.loadOnboardingCompleted();
        _loading = false;
      });
      _scheduleDailyAutoSync();
      await _syncBackgroundAutoSyncSchedule();
      _runAutoSyncIfDue();
    } catch (error, stackTrace) {
      debugPrint('Failed to load contacts store: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveContacts(List<BloodContact> contacts) async {
    await _store?.saveContacts(contacts);
    setState(() {
      _contacts = [...contacts]..sort(sortContacts);
    });
  }

  List<BloodContact> get _visibleContacts {
    return _contacts.where((contact) {
      final matchesBlood =
          _selectedBloodGroup == null ||
          contact.bloodGroup == _selectedBloodGroup;
      final matchesFilter = switch (_selectedFilter) {
        ContactFilter.all => true,
        ContactFilter.available => contact.isAvailable,
        ContactFilter.nearby => contact.isNearby,
      };
      return matchesBlood && matchesFilter;
    }).toList();
  }

  List<BloodContact> get _filteredContacts {
    final query = _contactsQuery.toLowerCase().trim();

    final filtered = _contacts.where((contact) {
      final matchesSearch =
          query.isEmpty ||
          '${contact.name} ${contact.phone} ${contact.area} ${contact.bloodGroup}'
              .toLowerCase()
              .contains(query);
      final matchesGroup =
          _contactsGroupFilter == 'All Groups' ||
          contact.bloodGroup == _contactsGroupFilter;
      final matchesAvailability =
          !_contactsAvailableOnly || contact.isAvailable;
      final matchesNearby = !_contactsNearbyOnly || contact.isNearby;

      return matchesSearch &&
          matchesGroup &&
          matchesAvailability &&
          matchesNearby;
    }).toList();

    return filtered..sort(_sortContactsForContactsPage);
  }

  int _sortContactsForContactsPage(BloodContact a, BloodContact b) {
    return switch (_contactsSortOption) {
      ContactsSortOption.name => sortContacts(a, b),
      ContactsSortOption.date => b.updatedAt.compareTo(a.updatedAt),
      ContactsSortOption.lastDonationDate => b.updatedAt.compareTo(a.updatedAt),
    };
  }

  ContactStats get _stats => ContactStats.fromContacts(_contacts);

  Future<void> _openContactForm([BloodContact? contact]) async {
    final result = await showModalBottomSheet<BloodContact>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBloodContactBottomSheet(
        contact: contact,
        existingContacts: _contacts,
      ),
    );

    if (result == null) return;

    final resultPhone = normalizedPhoneNumber(result.phone);
    final duplicateContact = resultPhone.isEmpty
        ? null
        : _contacts.where((existing) {
            return existing.id != result.id &&
                normalizedPhoneNumber(existing.phone) == resultPhone;
          }).firstOrNull;

    if (duplicateContact != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This phone number already exists for ${duplicateContact.name}.',
            ),
          ),
        );
      }
      return;
    }

    final nextContacts = [..._contacts];
    final index = nextContacts.indexWhere(
      (existing) => existing.id == result.id,
    );

    if (index == -1) {
      nextContacts.add(result);
    } else {
      nextContacts[index] = result;
    }

    await _saveContacts(nextContacts);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blood contact saved successfully.')),
      );
    }
  }

  Future<void> _deleteContact(BloodContact contact) async {
    await _saveContacts(
      _contacts.where((existing) => existing.id != contact.id).toList(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blood contact deleted successfully.')),
      );
    }
  }

  Future<bool> _confirmDeleteContact(
    BloodContact contact, {
    BuildContext? dialogContext,
  }) async {
    final confirmed = await showAppConfirmationDialog(
      context: dialogContext ?? context,
      title: 'Delete contact?',
      message: 'This blood contact will be removed from your saved donor list.',
      confirmLabel: 'Delete',
    );

    if (confirmed == true) {
      await _deleteContact(contact);
      return true;
    }

    return false;
  }

  Future<void> _openContactDetails(BloodContact contact) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (detailsContext) => DonorDetailsPage(
          contact: contact,
          onEdit: () async {
            Navigator.pop(detailsContext);
            await _openContactForm(contact);
          },
          onDelete: () async {
            final deleted = await _confirmDeleteContact(
              contact,
              dialogContext: detailsContext,
            );
            if (deleted && detailsContext.mounted) {
              Navigator.pop(detailsContext);
            }
          },
        ),
      ),
    );
  }

  Future<bool> _connectGoogleDrive() async {
    if (_syncing || _connectingDrive) return false;
    final store = _store;
    if (store == null) return false;
    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) {
      if (mounted) {
        _showOneSnackBar(
          const Text('No internet connection. Please try again online.'),
        );
      }
      return false;
    }

    setState(() => _connectingDrive = true);
    try {
      final connection = await _driveSyncService.connect();
      final accountEmail = connection.accountEmail?.trim();
      await store.saveDriveFolder(GoogleDriveSyncService.backupFolderName);
      if (accountEmail != null && accountEmail.isNotEmpty) {
        await store.saveDriveEmail(accountEmail);
      }
      if (!mounted) return false;
      setState(() {
        _driveFolder = GoogleDriveSyncService.backupFolderName;
        if (accountEmail != null && accountEmail.isNotEmpty) {
          _driveEmail = accountEmail;
        }
      });
      _showDriveSnackBar(
        title: 'Google Drive connected',
        message: 'Backup is ready. Tap Sync Now when you want to upload.',
        icon: Icons.check_circle,
        color: const Color(0xff119048),
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      final message = _syncUserMessage(_friendlyErrorMessage(error));
      _showDriveSnackBar(
        title: 'Connection failed',
        message: message,
        icon: Icons.error_outline,
        color: const Color(0xffd90416),
      );
      return false;
    } finally {
      if (mounted) setState(() => _connectingDrive = false);
    }
  }

  Future<void> _completeOnboardingAsNew() async {
    final store = _store;
    if (store == null) return;
    await store.saveOnboardingCompleted(true);
    if (!mounted) return;
    setState(() => _showContinueChoice = false);
  }

  Future<void> _completeOnboardingAndRestore() async {
    final store = _store;
    if (store == null || _syncing || _connectingDrive) return;

    final alreadyConnected = _driveFolder?.trim().isNotEmpty ?? false;
    var connected = alreadyConnected;
    if (!alreadyConnected) {
      connected = await _connectGoogleDrive();
    }
    if (!connected || !mounted) {
      return;
    }
    setState(() {
      _showContinueChoice = false;
      _showRestoreProgress = true;
      _restoreReadyToContinue = false;
      _restoreFailed = false;
      _onboardingRestoreInProgress = true;
      _restoreSyncedContacts = 0;
      _restoreSyncedNeeds = 0;
      _restoreSyncedAt = null;
    });
    await _syncData(allowInteractiveAuth: true, showFeedback: false);
    if (!mounted) return;
    setState(() {
      _restoreFailed = _lastSyncStatus != 'success';
      _restoreReadyToContinue = true;
    });
  }

  Future<void> _finishRestoreFlow() async {
    final store = _store;
    if (store != null) {
      await store.saveOnboardingCompleted(true);
    }
    if (!mounted) return;
    setState(() {
      _showRestoreProgress = false;
      _restoreReadyToContinue = false;
      _restoreFailed = false;
      _onboardingRestoreInProgress = false;
      _restoreSyncedContacts = 0;
      _restoreSyncedNeeds = 0;
      _restoreSyncedAt = null;
    });
  }

  Future<void> _openNewNeed() async {
    final need = await Navigator.of(context).push<BloodNeedRequest>(
      MaterialPageRoute(builder: (context) => const NewNeedPage()),
    );
    if (need == null) return;

    setState(() {
      _needs = [need, ..._needs];
      _selectedTab = AppTab.needs;
    });
    await _store?.saveNeeds(_needs);
  }

  Future<void> _openNotifications() async {
    final store = _store;
    if (store == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => NotificationsPage(
          notifications: _notifications,
          onOpenPreferences: _openNotificationPreferences,
          onMarkAllRead: () async {
            await store.markAllNotificationsRead();
          },
          onToggleSeen: (item, markSeen) async {
            if (markSeen) await store.markNotificationRead(item.id);
          },
        ),
      ),
    );
    await _refreshNotifications();
  }

  Future<void> _openNotificationPreferences() async {
    final store = _store;
    if (store == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => NotificationPreferencesPage(
          syncEventsEnabled: _notifySyncEvents,
          syncFailedEnabled: _notifySyncFailed,
          syncStaleEnabled: _notifySyncStale,
          onSyncEventsChanged: (value) async {
            await store.saveNotifySyncEventsEnabled(value);
            if (!mounted) return;
            setState(() => _notifySyncEvents = value);
          },
          onSyncFailedChanged: (value) async {
            await store.saveNotifySyncFailedEnabled(value);
            if (!mounted) return;
            setState(() => _notifySyncFailed = value);
            await _refreshNotifications();
          },
          onSyncStaleChanged: (value) async {
            await store.saveNotifySyncStaleEnabled(value);
            if (!mounted) return;
            setState(() => _notifySyncStale = value);
            await _refreshNotifications();
          },
        ),
      ),
    );
  }

  Future<void> _openNeedDetails(BloodNeedRequest need) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => NeedDetailsPage(
          need: need,
          contacts: _contacts,
          onChanged: _updateNeed,
        ),
      ),
    );
  }

  Future<void> _updateNeed(BloodNeedRequest need) async {
    setState(() {
      final index = _needs.indexWhere((existing) => existing.id == need.id);
      if (index == -1) return;
      _needs = [..._needs]..[index] = need;
    });
    await _store?.saveNeeds(_needs);
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label will be connected in a later step.')),
    );
  }

  Future<void> _openThemePreference() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              _ThemeChoiceTile(
                icon: Icons.tune,
                title: 'Default',
                subtitle: 'Use the app default theme',
                selected: true,
                onTap: () => Navigator.pop(context),
              ),
              _ThemeChoiceTile(
                icon: Icons.light_mode_outlined,
                title: 'Light',
                subtitle: 'Keep the current light theme',
                selected: false,
                onTap: () => Navigator.pop(context),
              ),
              const _ThemeChoiceTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark',
                subtitle: 'Coming later',
                selected: false,
                enabled: false,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSyncHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfileSyncHistoryPage(
          syncHistory: _syncHistory,
          driveConnected: _driveFolder?.trim().isNotEmpty ?? false,
        ),
      ),
    );
  }

  Future<void> _openPermissionsPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ProfilePermissionsPage(),
      ),
    );
  }

  Future<void> _openAboutPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const ProfileAboutPage()),
    );
  }

  Future<void> _openPrivacyDataPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfilePrivacyDataPage(
          driveConnected: _driveFolder?.trim().isNotEmpty ?? false,
        ),
      ),
    );
  }

  Future<void> _showDriveUnlinkOptions() async {
    final folder = _driveFolder?.trim();
    if (folder == null || folder.isEmpty) return;

    final action = await showAppOptionsDialog<_DriveUnlinkAction>(
      context: context,
      title: 'Unlink Google Drive?',
      message: 'Choose how you want to disconnect this account.',
      options: const [
        AppDialogOption(
          value: _DriveUnlinkAction.localOnly,
          label: 'Unlink only',
        ),
        AppDialogOption(
          value: _DriveUnlinkAction.removeCloudBackup,
          label: 'Unlink and delete backup',
          destructive: true,
          filled: true,
        ),
      ],
    );

    if (action == null) return;
    if (!mounted) return;

    if (action == _DriveUnlinkAction.removeCloudBackup) {
      final confirmed = await showAppConfirmationDialog(
        context: context,
        title: 'Delete cloud backup?',
        message:
            'This will permanently delete your Blood Contacts backup from Google Drive.',
        confirmLabel: 'Delete backup',
      );
      if (confirmed != true) return;

      setState(() => _syncing = true);
      try {
        await _driveSyncService.deleteBackup(allowInteractiveAuth: true);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove Drive backup: $error')),
        );
        setState(() => _syncing = false);
        return;
      }
    }

    await _unlinkDriveLocally();
    if (mounted) {
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Drive unlinked from this app.')),
      );
    }
  }

  Future<void> _unlinkDriveLocally() async {
    await _store?.clearDriveConnection();
    if (!mounted) return;
    setState(() {
      _driveFolder = null;
      _driveEmail = null;
      _autoSyncEnabled = false;
    });
    await _store?.saveAutoSyncEnabled(false);
    _autoSyncTimer?.cancel();
    await _syncBackgroundAutoSyncSchedule();
  }

  Future<void> _syncData({
    bool allowInteractiveAuth = false,
    bool showFeedback = true,
    bool isAutoSync = false,
  }) async {
    if (_syncing || _syncActionInFlight) return;
    _syncActionInFlight = true;
    try {
      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) {
        final store = _store;
        if (store != null) {
          final now = DateTime.now();
          await store.addSyncHistory(
            now,
            status: 'failed',
            message: 'No internet connection.',
          );
          await store.saveLastSyncStatus('failed');
          if (isAutoSync) {
            await _notifyAutoSyncFailure(store, now, 'No internet connection.');
          }
          await _refreshNotifications();
          if (mounted) {
            setState(() {
              _syncHistory = store.loadSyncHistory();
              _lastSyncStatus = store.loadLastSyncStatus();
            });
          }
        }
        if (mounted && showFeedback) {
          _showOneSnackBar(
            const Text('No internet connection. Please try again online.'),
          );
        }
        return;
      }

      final folder = _driveFolder?.trim();
      if (folder == null || folder.isEmpty) {
        final store = _store;
        if (store != null) {
          final now = DateTime.now();
          await store.saveLastSyncStatus('cancelled');
          await store.addSyncHistory(
            now,
            status: 'cancelled',
            message: 'Google Drive not connected.',
          );
          if (isAutoSync) {
            await _notifyAutoSyncFailure(
              store,
              now,
              'Google Drive not connected.',
              cancelled: true,
            );
          }
          await _refreshNotifications();
          if (mounted) {
            setState(() {
              _syncHistory = store.loadSyncHistory();
              _lastSyncStatus = store.loadLastSyncStatus();
            });
          }
        }
        if (!mounted) return;
        if (showFeedback) {
          _showOneSnackBar(const Text('Connect Google Drive before syncing.'));
        }
        return;
      }

      final store = _store;
      if (store == null) return;

      setState(() => _syncing = true);
      try {
        final result = await _driveSyncService.sync(
          store: store,
          allowInteractiveAuth: allowInteractiveAuth,
        );
        final contacts = await store.loadContacts();
        final needs = await store.loadNeeds();
        final syncedAt = DateTime.now();
        await store.addSyncHistory(
          syncedAt,
          status: 'success',
          contactCount: result.contactCount,
          needCount: result.needCount,
        );
        await store.saveLastSyncStatus('success');
        if (isAutoSync) {
          await store.resetAutoSyncAttemptTracking(syncedAt);
        }
        final accountEmail = result.accountEmail?.trim();
        if (accountEmail != null && accountEmail.isNotEmpty) {
          await store.saveDriveEmail(accountEmail);
        }
        if (!mounted) return;
        setState(() {
          _contacts = contacts;
          _needs = needs;
          if (accountEmail != null && accountEmail.isNotEmpty) {
            _driveEmail = accountEmail;
          }
          if (_showRestoreProgress) {
            _restoreSyncedContacts = result.contactCount;
            _restoreSyncedNeeds = result.needCount;
            _restoreSyncedAt = syncedAt;
          }
          _syncHistory = store.loadSyncHistory();
          _lastSyncStatus = store.loadLastSyncStatus();
        });
        await _refreshNotifications();
        if (!mounted) return;
        if (showFeedback) {
          _showOneSnackBar(
            Text(
              'Synced ${result.contactCount} contacts and ${result.needCount} needs.',
            ),
          );
        }
        await _addSyncEventNotification(
          store: store,
          status: 'success',
          title: 'Sync successful',
          message:
              'Synced ${result.contactCount} contacts and ${result.needCount} needs.',
        );
        await _refreshNotifications();
      } catch (error) {
        final errorMessage = _friendlyErrorMessage(error);
        final notificationMessage = _syncUserMessage(errorMessage);
        final lower = errorMessage.toLowerCase();
        final cancelled =
            lower.contains('cancel') ||
            lower.contains('canceled') ||
            lower.contains('aborted');
        final terminated =
            lower.contains('terminate') ||
            lower.contains('terminated') ||
            lower.contains('timeout') ||
            lower.contains('timed out');
        final status = cancelled
            ? 'cancelled'
            : terminated
            ? 'terminated'
            : 'failed';
        final failedAt = DateTime.now();
        await store.addSyncHistory(
          failedAt,
          status: status,
          message: notificationMessage,
        );
        await store.saveLastSyncStatus(status);
        if (isAutoSync) {
          await _notifyAutoSyncFailure(
            store,
            failedAt,
            notificationMessage,
            cancelled: cancelled,
            terminated: terminated,
          );
        }
        await _addSyncEventNotification(
          store: store,
          status: status,
          title: cancelled
              ? 'Sync cancelled'
              : terminated
              ? 'Sync terminated'
              : 'Sync failed',
          message: notificationMessage,
        );
        await _refreshNotifications();
        if (!mounted) return;
        setState(() {
          _syncHistory = store.loadSyncHistory();
          _lastSyncStatus = store.loadLastSyncStatus();
        });
        if (showFeedback) {
          _showDriveSnackBar(
            title: cancelled
                ? 'Sync cancelled'
                : terminated
                ? 'Sync terminated'
                : 'Sync failed',
            message: notificationMessage,
            icon: cancelled
                ? Icons.cloud_off_outlined
                : Icons.cloud_off_outlined,
            color: cancelled
                ? const Color(0xfff59e0b)
                : terminated
                ? const Color(0xff7d5a50)
                : const Color(0xffd90416),
          );
        }
      } finally {
        if (mounted) setState(() => _syncing = false);
      }
    } finally {
      _syncActionInFlight = false;
    }
  }

  void _showOneSnackBar(Widget content) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: content));
  }

  Future<void> _addSyncEventNotification({
    required ContactsStore store,
    required String status,
    required String title,
    required String message,
  }) async {
    if (_onboardingRestoreInProgress) return;
    if (!_notifySyncEvents) return;
    final now = DateTime.now();
    await store.upsertNotification(
      code: 'sync_${status}_${now.microsecondsSinceEpoch}',
      title: title,
      message: message,
      createdAt: now,
    );
  }

  Future<void> _notifyAutoSyncFailure(
    ContactsStore store,
    DateTime at,
    String reason, {
    bool cancelled = false,
    bool terminated = false,
  }) async {
    await store.upsertNotification(
      code: 'auto_sync_failed_${at.microsecondsSinceEpoch}',
      title: cancelled
          ? 'Auto-sync cancelled'
          : terminated
          ? 'Auto-sync terminated'
          : 'Auto-sync failed',
      message: reason,
      createdAt: at,
    );
  }

  void _scheduleDailyAutoSync() {
    _autoSyncTimer?.cancel();
    if (!_autoSyncEnabled) return;
    _autoSyncTimer = Timer.periodic(_autoSyncRetryInterval, (_) async {
      await _runAutoSyncIfDue();
    });
  }

  Future<void> _syncBackgroundAutoSyncSchedule() async {
    await Workmanager().cancelByUniqueName(dailyAutoSyncTask);
    if (!_autoSyncEnabled) return;
    await Workmanager().registerPeriodicTask(
      dailyAutoSyncTask,
      dailyAutoSyncTask,
      frequency: _autoSyncRetryInterval,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  Future<void> _runAutoSyncIfDue() async {
    final store = _store;
    if (store == null || !_autoSyncEnabled || _syncing) return;

    final now = DateTime.now();
    if (!store.canAttemptAutoSyncNow(
      now,
      maxAttemptsPerDay: _maxAutoSyncAttemptsPerDay,
      retryInterval: _autoSyncRetryInterval,
    )) {
      return;
    }

    await store.recordAutoSyncAttempt(now);
    await _syncData(showFeedback: false, isAutoSync: true);
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return !results.contains(ConnectivityResult.none);
    } catch (error, stackTrace) {
      debugPrint('Connectivity check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  void _showDriveSnackBar({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          duration: const Duration(seconds: 4),
          content: _DriveSnackBarContent(
            title: title,
            message: message,
            icon: icon,
            color: color,
          ),
        ),
      );
  }

  String _friendlyErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.startsWith('StateError: ')) {
      return message.replaceFirst('StateError: ', '');
    }
    return message;
  }

  String _syncUserMessage(String rawMessage) {
    final lower = rawMessage.toLowerCase();
    if (lower.contains('internet') ||
        lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('host lookup')) {
      return 'No internet connection. Please try again online.';
    }
    if (lower.contains('auth') ||
        lower.contains('sign in') ||
        lower.contains('unauthorized') ||
        lower.contains('permission')) {
      return 'Google Drive authorization failed. Please reconnect and try again.';
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Sync timed out. Please try again.';
    }
    if (lower.contains('cancel') ||
        lower.contains('canceled') ||
        lower.contains('aborted')) {
      return 'Sync was cancelled.';
    }
    return 'Sync could not complete. Please try again.';
  }

  void _resetNeedsFilters({NeedStatusFilter status = NeedStatusFilter.all}) {
    _needsGroupFilter = 'All';
    _needsUrgencyFilter = NeedUrgencyFilter.all;
    _needsStatusFilter = status;
    _needsQuery = '';
    _needsSortOption = NeedSortOption.newest;
  }

  void _selectTab(AppTab tab) {
    setState(() {
      if (tab == AppTab.needs && _selectedTab != AppTab.needs) {
        _resetNeedsFilters();
      }
      _selectedTab = tab;
    });
  }

  void _openContactsForBloodGroup(String group) {
    setState(() {
      _selectedTab = AppTab.contacts;
      _selectedBloodGroup = group;
      _selectedFilter = ContactFilter.all;
      _contactsQuery = '';
      _contactsGroupFilter = group;
      _contactsAvailableOnly = false;
      _contactsNearbyOnly = false;
    });
  }

  void _openAllContacts() {
    setState(() {
      _selectedTab = AppTab.contacts;
      _selectedBloodGroup = null;
      _selectedFilter = ContactFilter.all;
      _contactsQuery = '';
      _contactsGroupFilter = 'All Groups';
      _contactsAvailableOnly = false;
      _contactsNearbyOnly = false;
    });
  }

  void _openAvailableContacts() {
    setState(() {
      _selectedTab = AppTab.contacts;
      _selectedBloodGroup = null;
      _selectedFilter = ContactFilter.available;
      _contactsQuery = '';
      _contactsGroupFilter = 'All Groups';
      _contactsAvailableOnly = true;
      _contactsNearbyOnly = false;
    });
  }

  void _openNeedsWithStatus(NeedStatusFilter status) {
    setState(() {
      _selectedTab = AppTab.needs;
      _resetNeedsFilters(status: status);
    });
  }

  void _openNeedsTab() {
    setState(() {
      _selectedTab = AppTab.needs;
      _resetNeedsFilters();
    });
  }

  Future<bool> _shouldExitOnBack() async {
    if (_selectedTab != AppTab.home) {
      setState(() => _selectedTab = AppTab.home);
      return false;
    }

    final now = DateTime.now();
    final pressedRecently =
        _lastBackPressedAt != null &&
        now.difference(_lastBackPressedAt!) <= const Duration(seconds: 2);

    if (pressedRecently) {
      return true;
    }

    _lastBackPressedAt = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Press back again to exit app'),
        duration: Duration(seconds: 2),
      ),
    );
    return false;
  }

  Future<void> _handleBackAttempt() async {
    final shouldExit = await _shouldExitOnBack();
    if (!shouldExit) return;
    await SystemNavigator.pop();
  }

  Future<void> _refreshNotifications({
    ContactsStore? store,
    bool shouldSetState = true,
  }) async {
    final currentStore = store ?? _store;
    if (currentStore == null) return;

    final lastSyncStatus = currentStore.loadLastSyncStatus();
    final syncHistory = currentStore.loadSyncHistory();
    final now = DateTime.now();
    final suppressSyncNotifications = _onboardingRestoreInProgress;

    if (!suppressSyncNotifications &&
        _notifySyncFailed &&
        !_notifySyncEvents &&
        lastSyncStatus == 'failed') {
      await currentStore.upsertNotification(
        code: 'sync_failed',
        title: 'Your last sync failed',
        message:
            'Please sync your contacts again to keep your blood network safe.',
      );
    } else if (!suppressSyncNotifications) {
      await currentStore.deleteNotificationByCode('sync_failed');
    }

    final lastSyncedAt = syncHistory.isEmpty ? null : syncHistory.first.at;
    if (!suppressSyncNotifications && lastSyncedAt != null) {
      final days = now.difference(lastSyncedAt).inDays;
      if (_notifySyncStale && days >= 1) {
        await currentStore.upsertNotification(
          code: 'sync_stale',
          title: '$days day${days > 1 ? 's' : ''} without sync',
          message:
              'It has been $days day${days > 1 ? 's' : ''} since last sync. Sync now to avoid losing blood contacts.',
        );
      } else {
        await currentStore.deleteNotificationByCode('sync_stale');
      }
    } else if (!suppressSyncNotifications) {
      await currentStore.deleteNotificationByCode('sync_stale');
    }

    final notifications = await currentStore.loadNotifications();
    final count = await currentStore.unreadNotificationsCount();
    if (!mounted || !shouldSetState) return;
    setState(() {
      _notifications = notifications;
      _notificationCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showContinueChoice) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, _) => _handleBackAttempt(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
              child: _ContinueSetupPage(
                loading: _syncing || _connectingDrive,
                onRestore: _completeOnboardingAndRestore,
                onStartNew: _completeOnboardingAsNew,
              ),
            ),
          ),
        ),
      );
    }
    if (_showRestoreProgress) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, _) => _handleBackAttempt(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
              child: _RestoreSyncProgressPage(
                syncing: _syncing,
                readyToContinue: _restoreReadyToContinue,
                failed: _restoreFailed,
                syncedContacts: _restoreSyncedContacts,
                syncedNeeds: _restoreSyncedNeeds,
                syncedAt: _restoreSyncedAt,
                onContinue: _finishRestoreFlow,
              ),
            ),
          ),
        ),
      );
    }

    final stats = _stats;
    final visibleContacts = _visibleContacts.take(4).toList();
    final openNeedsCount = _needs
        .where((need) => need.status == NeedStatus.open)
        .length;
    final completedNeedsCount = _needs
        .where((need) => need.status == NeedStatus.fulfilled)
        .length;
    final recentNeeds = _needs.take(3).toList();
    final filteredContacts = _filteredContacts;
    final filteredAvailableCount = filteredContacts
        .where((contact) => contact.isAvailable)
        .length;
    final body = switch (_selectedTab) {
      AppTab.home => HomeOverviewPage(
        stats: stats,
        visibleContacts: visibleContacts,
        hasMoreContacts: visibleContacts.length < _visibleContacts.length,
        selectedBloodGroup: _selectedBloodGroup,
        selectedFilter: _selectedFilter,
        openNeedsCount: openNeedsCount,
        completedNeedsCount: completedNeedsCount,
        driveFolder: _driveFolder,
        onAdd: () => _openContactForm(),
        onNeed: _openNewNeed,
        onDriveFolder: _connectGoogleDrive,
        onBloodGroupSelected: _openContactsForBloodGroup,
        onFilterChanged: (filter) {
          setState(() {
            _selectedFilter = filter;
            if (filter == ContactFilter.all) {
              _selectedBloodGroup = null;
            }
          });
        },
        onViewAll: _openAllContacts,
        onAvailableContacts: _openAvailableContacts,
        onOpenNeeds: () => _openNeedsWithStatus(NeedStatusFilter.open),
        onCompletedNeeds: () =>
            _openNeedsWithStatus(NeedStatusFilter.fulfilled),
        recentNeeds: recentNeeds,
        onOpenRecentNeed: _openNeedDetails,
        onViewAllNeeds: _openNeedsTab,
        onNotifications: _openNotifications,
        notificationCount: _notificationCount,
        onEditContact: _openContactDetails,
        onDeleteContact: _confirmDeleteContact,
      ),
      AppTab.contacts => AllContactsPage(
        contacts: filteredContacts,
        totalCount: filteredContacts.length,
        availableCount: filteredAvailableCount,
        query: _contactsQuery,
        selectedGroup: _contactsGroupFilter,
        selectedSort: _contactsSortOption,
        onQueryChanged: (value) => setState(() => _contactsQuery = value),
        onGroupChanged: (value) => setState(() => _contactsGroupFilter = value),
        onSortChanged: (value) => setState(() => _contactsSortOption = value),
        onClearFilters: () {
          setState(() {
            _contactsQuery = '';
            _contactsGroupFilter = 'All Groups';
            _contactsSortOption = ContactsSortOption.name;
          });
        },
        onAdd: () => _openContactForm(),
        onBack: () => _selectTab(AppTab.home),
        onOpenDetails: _openContactDetails,
        onEditContact: _openContactForm,
        onDeleteContact: _confirmDeleteContact,
      ),
      AppTab.needs => NeedsListPage(
        needs: _needs,
        initialGroup: _needsGroupFilter,
        initialUrgency: _needsUrgencyFilter,
        initialStatus: _needsStatusFilter,
        initialQuery: _needsQuery,
        initialSort: _needsSortOption,
        onQueryChanged: (value) => setState(() => _needsQuery = value),
        onGroupChanged: (value) => setState(() => _needsGroupFilter = value),
        onUrgencyChanged: (value) =>
            setState(() => _needsUrgencyFilter = value),
        onStatusChanged: (value) => setState(() => _needsStatusFilter = value),
        onSortChanged: (value) => setState(() => _needsSortOption = value),
        onOpenDetails: _openNeedDetails,
        onAddNeed: _openNewNeed,
      ),
      AppTab.profile => ProfilePage(
        driveFolder: _driveFolder,
        driveEmail: _driveEmail,
        syncing: _syncing,
        connectingDrive: _connectingDrive,
        autoSyncEnabled: _autoSyncEnabled,
        syncHistory: _syncHistory,
        lastSyncStatus: _lastSyncStatus,
        onConnectDrive: _connectGoogleDrive,
        onSyncData: _syncData,
        onDisconnectDrive: _showDriveUnlinkOptions,
        onAutoSyncChanged: (value) async {
          await _store?.saveAutoSyncEnabled(value);
          if (value) {
            await _store?.markAutoSyncEnabledAt(DateTime.now());
          }
          if (!mounted) return;
          setState(() => _autoSyncEnabled = value);
          _scheduleDailyAutoSync();
          await _syncBackgroundAutoSyncSchedule();
          if (value) {
            await _runAutoSyncIfDue();
          }
        },
        onBackupHistory: _openSyncHistory,
        onAppearance: _openThemePreference,
        onNotificationList: _openNotifications,
        onNotificationPreferences: _openNotificationPreferences,
        notificationCount: _notificationCount,
        onPrivacy: _openPrivacyDataPage,
        onPermissions: _openPermissionsPage,
        onAbout: _openAboutPage,
        onRate: () => _showComingSoon('Rate us'),
      ),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _handleBackAttempt(),
      child: Scaffold(
        body: body,
        bottomNavigationBar: BloodBottomNavigation(
          selectedTab: _selectedTab,
          onHome: () => _selectTab(AppTab.home),
          onContacts: _openAllContacts,
          onNeeds: () => _selectTab(AppTab.needs),
          onProfile: () => _selectTab(AppTab.profile),
        ),
      ),
    );
  }
}

class _ContinueSetupPage extends StatelessWidget {
  const _ContinueSetupPage({
    required this.loading,
    required this.onRestore,
    required this.onStartNew,
  });

  final bool loading;
  final Future<void> Function() onRestore;
  final Future<void> Function() onStartNew;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              children: [
                const SizedBox(height: 6),
                const _WelcomeIllustration(),
                const SizedBox(height: 18),
                const Text(
                  'Welcome to',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xff111111),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Blood Contacts',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xffdf0b1d),
                    fontSize: 24,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Never lose important blood contacts again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xff5b5b67),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _ContinueOptionCard(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Start as a new',
                  subtitle: 'Start with a fresh contact list',
                  iconColor: const Color(0xffdf0b1d),
                  iconBackground: const Color(0xfffff2f3),
                  cardBackground: const Color(0xfffff6f7),
                  borderColor: const Color(0xffffe2e5),
                  titleColor: const Color(0xff43201f),
                  onTap: loading ? null : onStartNew,
                ),
                const SizedBox(height: 12),
                _ContinueOptionCard(
                  icon: FontAwesomeIcons.googleDrive,
                  title: 'Connect Google Drive',
                  subtitle:
                      'Find your saved contacts and continue where you left off',
                  iconColor: const Color(0xff1f8d3f),
                  iconBackground: const Color(0xffecf7ef),
                  cardBackground: const Color(0xfff3fbf5),
                  borderColor: const Color(0xffdbeede),
                  titleColor: const Color(0xff177235),
                  onTap: loading ? null : onRestore,
                ),
                if (loading) ...[
                  const SizedBox(height: 14),
                  const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ],
                const Spacer(),
                const _WelcomeFooterNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueOptionCard extends StatelessWidget {
  const _ContinueOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBackground,
    required this.cardBackground,
    required this.borderColor,
    required this.titleColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBackground;
  final Color cardBackground;
  final Color borderColor;
  final Color titleColor;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!.call(),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xff665653),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xff8d8f98),
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestoreSyncProgressPage extends StatelessWidget {
  const _RestoreSyncProgressPage({
    required this.syncing,
    required this.readyToContinue,
    required this.failed,
    required this.syncedContacts,
    required this.syncedNeeds,
    required this.syncedAt,
    required this.onContinue,
  });

  final bool syncing;
  final bool readyToContinue;
  final bool failed;
  final int syncedContacts;
  final int syncedNeeds;
  final DateTime? syncedAt;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    final searchingDone = readyToContinue;
    final preparingDone = readyToContinue;
    final searchingActive = syncing;

    return Column(
      children: [
        const SizedBox(height: 34),
        Container(
          width: 156,
          height: 156,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xffd9ece0), width: 8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (syncing)
                const SizedBox(
                  width: 142,
                  height: 142,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation(Color(0xff19a34a)),
                  ),
                ),
              const FaIcon(
                FontAwesomeIcons.googleDrive,
                size: 46,
                color: Color(0xff649e6a),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          failed
              ? 'Could not restore backup'
              : readyToContinue
              ? 'Sync Completed'
              : 'Searching for your backup...',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xff111111),
            fontSize: 38 / 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          failed
              ? 'Please check internet and try again.'
              : readyToContinue
              ? 'Review completed. You can continue now.'
              : 'Please wait a moment',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xff666674),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 26),
        if (readyToContinue && !failed) ...[
          _RestoreSummaryCard(
            contacts: syncedContacts,
            needs: syncedNeeds,
            syncedAt: syncedAt,
          ),
          const SizedBox(height: 18),
        ],
        _RestoreStepRow(
          label: 'Connecting to Google Drive',
          state: _RestoreStepState.done,
        ),
        const SizedBox(height: 14),
        _RestoreStepRow(
          label: 'Searching for Blood Contacts backup',
          state: searchingDone
              ? _RestoreStepState.done
              : searchingActive
              ? _RestoreStepState.active
              : _RestoreStepState.pending,
        ),
        const SizedBox(height: 14),
        _RestoreStepRow(
          label: 'Preparing your data',
          state: preparingDone
              ? failed
                    ? _RestoreStepState.pending
                    : _RestoreStepState.done
              : _RestoreStepState.pending,
        ),
        const SizedBox(height: 26),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xfff0faf2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffd8ecdd)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xff1f8d3f), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tip\nMake sure you are connected to the internet.',
                  style: TextStyle(
                    color: Color(0xff2f4a36),
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: readyToContinue ? onContinue : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffdf0b1d),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Text(readyToContinue ? 'Continue' : 'Please wait...'),
          ),
        ),
      ],
    );
  }
}

enum _RestoreStepState { done, active, pending }

class _RestoreStepRow extends StatelessWidget {
  const _RestoreStepRow({required this.label, required this.state});

  final String label;
  final _RestoreStepState state;

  @override
  Widget build(BuildContext context) {
    Widget leading;
    if (state == _RestoreStepState.done) {
      leading = const Icon(
        Icons.check_circle,
        color: Color(0xff19a34a),
        size: 22,
      );
    } else if (state == _RestoreStepState.active) {
      leading = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.3,
          valueColor: AlwaysStoppedAnimation(Color(0xffdf0b1d)),
        ),
      );
    } else {
      leading = const Icon(
        Icons.circle_outlined,
        color: Color(0xffadb0bb),
        size: 22,
      );
    }

    return Row(
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xff32323d),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RestoreSummaryCard extends StatelessWidget {
  const _RestoreSummaryCard({
    required this.contacts,
    required this.needs,
    required this.syncedAt,
  });

  final int contacts;
  final int needs;
  final DateTime? syncedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xfff2faf4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffd8ebdc)),
      ),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.groups_2_outlined,
            text: '$contacts contacts synced',
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.volunteer_activism_outlined,
            text: '$needs needs synced',
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.schedule_outlined,
            text: syncedAt == null
                ? 'Last synced: just now'
                : 'Last synced: ${_formatRestoreSyncedAt(syncedAt!)}',
          ),
          const SizedBox(height: 10),
          const _SummaryRow(
            icon: Icons.cloud_done_outlined,
            text: 'Synced from: Google Drive',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xff1f8d3f)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xff1d2b22),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatRestoreSyncedAt(DateTime date) {
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
  final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.day} ${months[date.month - 1]} ${date.year}, $hour12:$minute $suffix';
}

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      child: Image.asset(
        'assets/onboarding/fresh_welcome_illustration.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _WelcomeFooterNote extends StatelessWidget {
  const _WelcomeFooterNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 4),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, size: 24, color: Color(0xff22222a)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your data stays in your Google Drive.\nWe never share your information.',
              style: TextStyle(
                color: Color(0xff3d3d46),
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _DriveUnlinkAction { localOnly, removeCloudBackup }

class _DriveSnackBarContent extends StatelessWidget {
  const _DriveSnackBarContent({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xff201716),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff675854),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
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

class _ThemeChoiceTile extends StatelessWidget {
  const _ThemeChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? const Color(0xff201716) : const Color(0xffaaa0a0);

    return ListTile(
      enabled: enabled,
      onTap: onTap,
      leading: Icon(icon, color: enabled ? const Color(0xffe5161d) : color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xffe5161d))
          : null,
    );
  }
}
