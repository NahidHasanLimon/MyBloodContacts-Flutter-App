import 'package:flutter/material.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({
    super.key,
    required this.syncEventsEnabled,
    required this.syncFailedEnabled,
    required this.syncStaleEnabled,
    required this.onSyncEventsChanged,
    required this.onSyncFailedChanged,
    required this.onSyncStaleChanged,
  });

  final bool syncEventsEnabled;
  final bool syncFailedEnabled;
  final bool syncStaleEnabled;
  final ValueChanged<bool> onSyncEventsChanged;
  final ValueChanged<bool> onSyncFailedChanged;
  final ValueChanged<bool> onSyncStaleChanged;

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  late bool _syncEventsEnabled;
  late bool _syncFailedEnabled;
  late bool _syncStaleEnabled;

  @override
  void initState() {
    super.initState();
    _syncEventsEnabled = widget.syncEventsEnabled;
    _syncFailedEnabled = widget.syncFailedEnabled;
    _syncStaleEnabled = widget.syncStaleEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Sync updates'),
            subtitle: const Text(
              'Create a notification after each sync result.',
            ),
            value: _syncEventsEnabled,
            onChanged: (value) {
              setState(() => _syncEventsEnabled = value);
              widget.onSyncEventsChanged(value);
            },
          ),
          SwitchListTile(
            title: const Text('Your last sync failed'),
            subtitle: const Text('Alert when a sync attempt fails.'),
            value: _syncFailedEnabled,
            onChanged: (value) {
              setState(() => _syncFailedEnabled = value);
              widget.onSyncFailedChanged(value);
            },
          ),
          SwitchListTile(
            title: const Text('N days without sync'),
            subtitle: const Text(
              'Alert when data has not been synced for one or more days.',
            ),
            value: _syncStaleEnabled,
            onChanged: (value) {
              setState(() => _syncStaleEnabled = value);
              widget.onSyncStaleChanged(value);
            },
          ),
        ],
      ),
    );
  }
}
