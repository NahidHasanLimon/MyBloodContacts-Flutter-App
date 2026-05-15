import 'package:blood_contacts/src/features/contacts/data/contacts_store.dart';
import 'package:blood_contacts/src/features/contacts/data/google_drive_sync_service.dart';
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
import 'package:blood_contacts/src/features/contacts/presentation/widgets/contact_widgets.dart';
import 'package:blood_contacts/src/features/contacts/presentation/widgets/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class BloodContactsHome extends StatefulWidget {
  const BloodContactsHome({super.key, this.databaseFactory});

  final sqflite.DatabaseFactory? databaseFactory;

  @override
  State<BloodContactsHome> createState() => _BloodContactsHomeState();
}

class _BloodContactsHomeState extends State<BloodContactsHome> {
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
  List<BloodNeedRequest> _needs = [];
  String? _driveFolder;
  String? _driveEmail;
  String? _lastSyncStatus;
  List<DateTime> _syncHistory = [];
  bool _autoSyncEnabled = false;
  List<AppNotification> _notifications = [];
  int _notificationCount = 0;
  bool _notifySyncFailed = true;
  bool _notifySyncStale = true;
  bool _loading = true;
  bool _syncing = false;
  bool _connectingDrive = false;
  bool _showContinueChoice = false;

  @override
  void initState() {
    super.initState();
    _load();
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
        _notifications = notifications;
        _notificationCount = notificationCount;
        _notifySyncFailed = notifySyncFailed;
        _notifySyncStale = notifySyncStale;
        _showContinueChoice = !store.loadOnboardingCompleted();
        _loading = false;
      });
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
    final confirmed = await showDialog<bool>(
      context: dialogContext ?? context,
      builder: (context) => AlertDialog(
        title: const Text('Delete contact?'),
        content: const Text(
          'This blood contact will be removed from your saved donor list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
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
      _showDriveSnackBar(
        title: 'Connection failed',
        message: _friendlyErrorMessage(error),
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
    await store.saveOnboardingCompleted(true);
    if (!mounted) return;
    setState(() => _showContinueChoice = false);
    await _syncData(allowInteractiveAuth: true);
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
          syncFailedEnabled: _notifySyncFailed,
          syncStaleEnabled: _notifySyncStale,
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

    final action = await showDialog<_DriveUnlinkAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Google Drive?'),
        content: const Text('Choose how you want to disconnect this account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, _DriveUnlinkAction.localOnly);
            },
            child: const Text('Only unlink'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, _DriveUnlinkAction.removeCloudBackup);
            },
            child: const Text('Unlink and remove data from cloud'),
          ),
        ],
      ),
    );

    if (action == null) return;
    if (!mounted) return;

    if (action == _DriveUnlinkAction.removeCloudBackup) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text(
            'This will delete the Blood Contacts backup file from Google Drive.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete backup'),
            ),
          ],
        ),
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
  }

  Future<void> _syncData({bool allowInteractiveAuth = false}) async {
    if (_syncing) return;
    final folder = _driveFolder?.trim();
    if (folder == null || folder.isEmpty) {
      final store = _store;
      if (store != null) {
        await _addSyncEventNotification(
          store: store,
          status: 'cancelled',
          title: 'Sync cancelled',
          message: 'Connect Google Drive before syncing.',
        );
        await _refreshNotifications();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect Google Drive before syncing.')),
      );
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
      await store.addSyncHistory(syncedAt);
      await store.saveLastSyncStatus('success');
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
        _syncHistory = store.loadSyncHistory();
        _lastSyncStatus = store.loadLastSyncStatus();
      });
      await _refreshNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Synced ${result.contactCount} contacts and ${result.needCount} needs.',
          ),
        ),
      );
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
      final lower = errorMessage.toLowerCase();
      final cancelled =
          lower.contains('cancel') ||
          lower.contains('canceled') ||
          lower.contains('aborted');
      await store.saveLastSyncStatus(cancelled ? 'cancelled' : 'failed');
      await _addSyncEventNotification(
        store: store,
        status: cancelled ? 'cancelled' : 'failed',
        title: cancelled ? 'Sync cancelled' : 'Sync failed',
        message: cancelled ? errorMessage : errorMessage,
      );
      await _refreshNotifications();
      if (!mounted) return;
      setState(() => _lastSyncStatus = store.loadLastSyncStatus());
      _showDriveSnackBar(
        title: cancelled ? 'Sync cancelled' : 'Sync failed',
        message: errorMessage,
        icon: cancelled ? Icons.cloud_off_outlined : Icons.cloud_off_outlined,
        color: cancelled ? const Color(0xfff59e0b) : const Color(0xffd90416),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _addSyncEventNotification({
    required ContactsStore store,
    required String status,
    required String title,
    required String message,
  }) async {
    final now = DateTime.now();
    await store.upsertNotification(
      code: 'sync_${status}_${now.microsecondsSinceEpoch}',
      title: title,
      message: message,
      createdAt: now,
    );
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

  void _selectTab(AppTab tab) {
    setState(() => _selectedTab = tab);
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
      _needsGroupFilter = 'All';
      _needsUrgencyFilter = NeedUrgencyFilter.all;
      _needsStatusFilter = status;
    });
  }

  void _openNeedsTab() {
    setState(() {
      _selectedTab = AppTab.needs;
      _needsGroupFilter = 'All';
      _needsUrgencyFilter = NeedUrgencyFilter.all;
      _needsStatusFilter = NeedStatusFilter.all;
    });
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

    if (_notifySyncFailed && lastSyncStatus == 'failed') {
      await currentStore.upsertNotification(
        code: 'sync_failed',
        title: 'Your last sync failed',
        message:
            'Please sync your contacts again to keep your blood network safe.',
      );
    } else {
      await currentStore.deleteNotificationByCode('sync_failed');
    }

    final lastSyncedAt = syncHistory.isEmpty ? null : syncHistory.first;
    if (lastSyncedAt != null) {
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
    } else {
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
      return Scaffold(
        backgroundColor: const Color(0xfffffbf7),
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
        onAutoSyncChanged: (value) => setState(() {
          _autoSyncEnabled = value;
        }),
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

    return Scaffold(
      body: body,
      bottomNavigationBar: BloodBottomNavigation(
        selectedTab: _selectedTab,
        onHome: () => _selectTab(AppTab.home),
        onContacts: _openAllContacts,
        onNeeds: () => _selectTab(AppTab.needs),
        onProfile: () => _selectTab(AppTab.profile),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How do you want to continue?',
          style: TextStyle(
            color: Color(0xff201716),
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Choose restore if you used this app before. Choose start new if this is your first time.',
          style: TextStyle(
            color: Color(0xff665653),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 22),
        _ContinueOptionCard(
          icon: Icons.cloud_sync_outlined,
          title: 'Restore from Google Drive',
          subtitle:
              'Used this app before? Connect Drive and get your contacts and needs back.',
          onTap: loading ? null : onRestore,
        ),
        const SizedBox(height: 12),
        _ContinueOptionCard(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Start as New',
          subtitle:
              'I am new here. I want to start with an empty contact list.',
          onTap: loading ? null : onStartNew,
        ),
        if (loading) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

class _ContinueOptionCard extends StatelessWidget {
  const _ContinueOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!.call(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffffe5df)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xffffeef0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xffd90416), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xff201716),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xff665653),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Color(0xff7d6c69)),
            ],
          ),
        ),
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
