import 'package:blood_contacts/src/features/contacts/data/contacts_store.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_need_request.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_stats.dart';
import 'package:blood_contacts/src/features/contacts/presentation/pages/donor_details_page.dart';
import 'package:blood_contacts/src/features/contacts/presentation/pages/need_details_page.dart';
import 'package:blood_contacts/src/features/contacts/presentation/pages/new_need_page.dart';
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
  List<BloodNeedRequest> _needs = [];
  String? _driveFolder;
  bool _loading = true;

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

      if (!mounted) return;
      setState(() {
        _store = store;
        _contacts = contacts;
        _needs = needs;
        _driveFolder = store.loadDriveFolder();
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
      builder: (context) => AddBloodContactBottomSheet(contact: contact),
    );

    if (result == null) return;

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

  Future<void> _saveDriveFolder() async {
    final controller = TextEditingController(text: _driveFolder ?? '');
    final folder = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Drive folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            hintText: 'Blood Contacts Backup',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (folder == null || folder.isEmpty) return;

    await _store?.saveDriveFolder(folder);
    setState(() => _driveFolder = folder);
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

  void _syncData() {
    final folder = _driveFolder?.trim();
    final message = folder == null || folder.isEmpty
        ? 'Connect Google Drive before syncing data.'
        : 'Sync data will be connected in a later step.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectTab(AppTab tab) {
    setState(() => _selectedTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final stats = _stats;
    final visibleContacts = _visibleContacts.take(4).toList();
    final body = switch (_selectedTab) {
      AppTab.home => HomeOverviewPage(
        stats: stats,
        visibleContacts: visibleContacts,
        hasMoreContacts: visibleContacts.length < _visibleContacts.length,
        selectedBloodGroup: _selectedBloodGroup,
        selectedFilter: _selectedFilter,
        driveFolder: _driveFolder,
        onAdd: () => _openContactForm(),
        onNeed: _openNewNeed,
        onDriveFolder: _saveDriveFolder,
        onBloodGroupSelected: (group) {
          setState(() {
            _selectedBloodGroup = _selectedBloodGroup == group ? null : group;
          });
        },
        onFilterChanged: (filter) {
          setState(() {
            _selectedFilter = filter;
            if (filter == ContactFilter.all) {
              _selectedBloodGroup = null;
            }
          });
        },
        onViewAll: () => _selectTab(AppTab.contacts),
        onEditContact: _openContactDetails,
        onDeleteContact: _confirmDeleteContact,
      ),
      AppTab.contacts => AllContactsPage(
        contacts: _filteredContacts,
        totalCount: stats.total,
        availableCount: stats.available,
        query: _contactsQuery,
        selectedGroup: _contactsGroupFilter,
        availableOnly: _contactsAvailableOnly,
        nearbyOnly: _contactsNearbyOnly,
        selectedSort: _contactsSortOption,
        onQueryChanged: (value) => setState(() => _contactsQuery = value),
        onGroupChanged: (value) => setState(() => _contactsGroupFilter = value),
        onAvailableChanged: (value) {
          setState(() => _contactsAvailableOnly = value);
        },
        onNearbyChanged: (value) {
          setState(() => _contactsNearbyOnly = value);
        },
        onSortChanged: (value) => setState(() => _contactsSortOption = value),
        onClearFilters: () {
          setState(() {
            _contactsQuery = '';
            _contactsGroupFilter = 'All Groups';
            _contactsAvailableOnly = false;
            _contactsNearbyOnly = false;
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
        onOpenDetails: _openNeedDetails,
      ),
      AppTab.profile => ProfilePage(
        driveFolder: _driveFolder,
        onConnectDrive: _saveDriveFolder,
        onSyncData: _syncData,
        onAutoBackup: () => _showComingSoon('Auto backup'),
        onBackupHistory: () => _showComingSoon('Backup history'),
        onAppearance: () => _showComingSoon('App appearance'),
        onNotifications: () => _showComingSoon('Notifications'),
        onAppLock: () => _showComingSoon('App lock'),
        onPrivacy: () => _showComingSoon('Privacy & data'),
        onPermissions: () => _showComingSoon('Permissions'),
        onAbout: () => _showComingSoon('About Blood Contacts'),
        onRate: () => _showComingSoon('Rate us'),
      ),
    };

    return Scaffold(
      body: body,
      floatingActionButton: _selectedTab == AppTab.contacts
          ? SizedBox(
              width: 72,
              height: 72,
              child: FloatingActionButton(
                onPressed: () => _openContactForm(),
                shape: const CircleBorder(),
                backgroundColor: const Color(0xffe5161d),
                foregroundColor: Colors.white,
                child: const Icon(Icons.add, size: 34),
              ),
            )
          : _selectedTab == AppTab.needs
          ? SizedBox(
              width: 72,
              height: 72,
              child: FloatingActionButton(
                onPressed: _openNewNeed,
                shape: const CircleBorder(),
                backgroundColor: const Color(0xffe5161d),
                foregroundColor: Colors.white,
                child: const Icon(Icons.add, size: 34),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BloodBottomNavigation(
        selectedTab: _selectedTab,
        onHome: () => _selectTab(AppTab.home),
        onContacts: () => _selectTab(AppTab.contacts),
        onNeeds: () => _selectTab(AppTab.needs),
        onProfile: () => _selectTab(AppTab.profile),
      ),
    );
  }
}
