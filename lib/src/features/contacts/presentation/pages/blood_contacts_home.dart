import 'package:blood_contacts/src/features/contacts/data/contacts_store.dart';
import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_stats.dart';
import 'package:blood_contacts/src/features/contacts/presentation/widgets/contact_widgets.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BloodContactsHome extends StatefulWidget {
  const BloodContactsHome({super.key});

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
  AvailabilityFilter _contactsAvailabilityFilter = AvailabilityFilter.all;
  String _contactsAreaFilter = 'All Areas';
  bool _contactsNearbyOnly = false;
  String? _driveFolder;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = ContactsStore(prefs);

    setState(() {
      _store = store;
      _contacts = store.loadContacts();
      _driveFolder = store.loadDriveFolder();
      _loading = false;
    });
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

  List<String> get _areaFilters {
    final areas =
        _contacts
            .map((contact) => contact.area)
            .where((area) => area != 'Local contact')
            .toSet()
            .toList()
          ..sort();
    return ['All Areas', ...areas];
  }

  List<BloodContact> get _filteredContacts {
    final query = _contactsQuery.toLowerCase().trim();

    return _contacts.where((contact) {
      final matchesSearch =
          query.isEmpty ||
          '${contact.name} ${contact.phone} ${contact.area} ${contact.bloodGroup}'
              .toLowerCase()
              .contains(query);
      final matchesGroup =
          _contactsGroupFilter == 'All Groups' ||
          contact.bloodGroup == _contactsGroupFilter;
      final matchesStatus = switch (_contactsAvailabilityFilter) {
        AvailabilityFilter.all => true,
        AvailabilityFilter.available => contact.isAvailable,
        AvailabilityFilter.unavailable => !contact.isAvailable,
      };
      final matchesArea =
          _contactsAreaFilter == 'All Areas' ||
          contact.area == _contactsAreaFilter;
      final matchesNearby = !_contactsNearbyOnly || contact.isNearby;

      return matchesSearch &&
          matchesGroup &&
          matchesStatus &&
          matchesArea &&
          matchesNearby;
    }).toList();
  }

  ContactStats get _stats => ContactStats.fromContacts(_contacts);

  Future<void> _openContactForm([BloodContact? contact]) async {
    final result = await showModalBottomSheet<BloodContact>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => ContactFormSheet(contact: contact),
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
  }

  Future<void> _deleteContact(BloodContact contact) async {
    await _saveContacts(
      _contacts.where((existing) => existing.id != contact.id).toList(),
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

  void _showImportNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Native contact import is the next integration step; local entries work now.',
        ),
      ),
    );
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label will be connected in a later step.')),
    );
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
        onImport: _showImportNotice,
        onDriveFolder: _saveDriveFolder,
        onBloodGroupSelected: (group) {
          setState(() {
            _selectedBloodGroup = _selectedBloodGroup == group ? null : group;
          });
        },
        onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
        onViewAll: () => _selectTab(AppTab.contacts),
        onEditContact: _openContactForm,
        onDeleteContact: _deleteContact,
      ),
      AppTab.contacts => AllContactsPage(
        stats: stats,
        contacts: _filteredContacts,
        query: _contactsQuery,
        selectedGroup: _contactsGroupFilter,
        selectedAvailability: _contactsAvailabilityFilter,
        selectedArea: _contactsAreaFilter,
        nearbyOnly: _contactsNearbyOnly,
        areaOptions: _areaFilters,
        onQueryChanged: (value) => setState(() => _contactsQuery = value),
        onGroupChanged: (value) => setState(() => _contactsGroupFilter = value),
        onAvailabilityChanged: (value) {
          setState(() => _contactsAvailabilityFilter = value);
        },
        onAreaChanged: (value) => setState(() => _contactsAreaFilter = value),
        onNearbyChanged: (value) {
          setState(() => _contactsNearbyOnly = value);
        },
        onClearFilters: () {
          setState(() {
            _contactsQuery = '';
            _contactsGroupFilter = 'All Groups';
            _contactsAvailabilityFilter = AvailabilityFilter.all;
            _contactsAreaFilter = 'All Areas';
            _contactsNearbyOnly = false;
          });
        },
        onAdd: () => _openContactForm(),
        onBack: () => _selectTab(AppTab.home),
        onEditContact: _openContactForm,
        onDeleteContact: _deleteContact,
      ),
    };

    return Scaffold(
      body: body,
      floatingActionButton: SizedBox(
        width: _selectedTab == AppTab.contacts ? 72 : null,
        height: _selectedTab == AppTab.contacts ? 72 : null,
        child: FloatingActionButton(
          onPressed: () => _openContactForm(),
          shape: const CircleBorder(),
          backgroundColor: const Color(0xffe5161d),
          foregroundColor: Colors.white,
          child: const Icon(Icons.add, size: 34),
        ),
      ),
      floatingActionButtonLocation: _selectedTab == AppTab.contacts
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BloodBottomNavigation(
        selectedTab: _selectedTab,
        onHome: () => _selectTab(AppTab.home),
        onContacts: () => _selectTab(AppTab.contacts),
        onRequests: () => _showComingSoon('Requests'),
        onAlerts: () => _showComingSoon('Alerts'),
        onProfile: () => _showComingSoon('Profile'),
      ),
    );
  }
}
