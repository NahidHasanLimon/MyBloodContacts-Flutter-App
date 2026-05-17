import 'package:blood_contacts/src/app/app_theme.dart';
import 'package:blood_contacts/src/features/contacts/data/contacts_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as phone_contacts;

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.driveFolder,
    required this.driveEmail,
    required this.syncing,
    required this.connectingDrive,
    required this.autoSyncEnabled,
    required this.syncHistory,
    required this.lastSyncStatus,
    required this.notificationCount,
    required this.onConnectDrive,
    required this.onSyncData,
    required this.onDisconnectDrive,
    required this.onAutoSyncChanged,
    required this.onBackupHistory,
    required this.onAppearance,
    required this.onNotificationList,
    required this.onNotificationPreferences,
    required this.onPrivacy,
    required this.onPermissions,
    required this.onAbout,
    required this.onRate,
  });

  final String? driveFolder;
  final String? driveEmail;
  final bool syncing;
  final bool connectingDrive;
  final bool autoSyncEnabled;
  final List<SyncHistoryEntry> syncHistory;
  final String? lastSyncStatus;
  final int notificationCount;
  final VoidCallback onConnectDrive;
  final VoidCallback onSyncData;
  final VoidCallback onDisconnectDrive;
  final ValueChanged<bool> onAutoSyncChanged;
  final VoidCallback onBackupHistory;
  final VoidCallback onAppearance;
  final VoidCallback onNotificationList;
  final VoidCallback onNotificationPreferences;
  final VoidCallback onPrivacy;
  final VoidCallback onPermissions;
  final VoidCallback onAbout;
  final VoidCallback onRate;

  bool get _driveConnected => driveFolder?.trim().isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    final lastSyncedAt = syncHistory.isEmpty ? null : syncHistory.first.at;

    return ColoredBox(
      color: const Color(0xfffffbf7),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 110),
              sliver: SliverList.list(
                children: [
                  _ProfileHeader(
                    onNotifications: onNotificationList,
                    onSettings: onAppearance,
                    notificationCount: notificationCount,
                  ),
                  const SizedBox(height: 28),
                  const _SectionTitle(title: 'Backup & Sync'),
                  const SizedBox(height: 12),
                  _DriveStatusCard(
                    connected: _driveConnected,
                    accountEmail: driveEmail,
                    syncing: syncing,
                    connecting: connectingDrive,
                    onConnect: onConnectDrive,
                    onSync: onSyncData,
                    onLongPress: onDisconnectDrive,
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: _AutoSyncTile(
                      connected: _driveConnected,
                      value: _driveConnected && autoSyncEnabled,
                      onChanged: onAutoSyncChanged,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: _SyncHistoryTile(
                      lastSyncedAt: lastSyncedAt,
                      lastSyncStatus: lastSyncStatus,
                      enabled: _driveConnected,
                      onTap: onBackupHistory,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _SectionTitle(title: 'Privacy & Security'),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.notifications_none,
                          iconColor: const Color(0xffc47a00),
                          iconBackground: const Color(0xfffff5dc),
                          title: 'Notifications',
                          onTap: onNotificationPreferences,
                        ),
                        const _CardDivider(),
                        _SettingsTile(
                          icon: Icons.verified_user_outlined,
                          iconColor: const Color(0xff119048),
                          iconBackground: const Color(0xffeaf8ed),
                          title: 'Privacy & Data',
                          onTap: onPrivacy,
                        ),
                        const _CardDivider(),
                        _SettingsTile(
                          icon: Icons.key_outlined,
                          iconColor: const Color(0xffff8a00),
                          iconBackground: const Color(0xfffff0df),
                          title: 'Permissions',
                          onTap: onPermissions,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _SectionTitle(title: 'Appearance'),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: _SettingsTile(
                      icon: Icons.brush_outlined,
                      iconColor: const Color(0xff8b2be2),
                      iconBackground: const Color(0xfff5eaff),
                      title: 'Theme',
                      onTap: onAppearance,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _SectionTitle(title: 'About'),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.info_outline,
                          iconColor: const Color(0xff4b5565),
                          iconBackground: const Color(0xfff1f2f4),
                          title: 'About Blood Contacts',
                          onTap: onAbout,
                        ),
                        const _CardDivider(),
                        _SettingsTile(
                          icon: Icons.favorite_border,
                          iconColor: const Color(0xffe5161d),
                          iconBackground: const Color(0xffffeef0),
                          title: 'Rate Us',
                          onTap: onRate,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.onNotifications,
    required this.onSettings,
    required this.notificationCount,
  });

  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  color: Color(0xff201716),
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Keep everything calm, safe, and easy to manage.',
                style: TextStyle(
                  color: Color(0xff6f605c),
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: Icons.notifications_none,
          badgeText: notificationCount > 0 ? '$notificationCount' : null,
          tooltip: 'Notifications',
          onTap: onNotifications,
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeText,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xffffe1d7)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: Icon(icon, color: const Color(0xff3a2926))),
              if (badgeText != null)
                Positioned(
                  right: -3,
                  top: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xffe5161d),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      badgeText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xff231816),
        fontSize: AppFontSizes.sectionTitle,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffffe9e2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0d7a2a1e),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DriveStatusCard extends StatelessWidget {
  const _DriveStatusCard({
    required this.connected,
    required this.accountEmail,
    required this.syncing,
    required this.connecting,
    required this.onConnect,
    required this.onSync,
    required this.onLongPress,
  });

  final bool connected;
  final String? accountEmail;
  final bool syncing;
  final bool connecting;
  final VoidCallback onConnect;
  final VoidCallback onSync;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final connectedEmail = accountEmail?.trim();
    final busy = syncing || connecting;

    return _SettingsCard(
      child: InkWell(
        onLongPress: connected && !busy ? onLongPress : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusGraphic(connected: connected),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connect to Google Drive',
                          style: TextStyle(
                            color: Color(0xff201716),
                            fontSize: AppFontSizes.cardTitle,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        _StatusBadge(
                          label: connected ? 'Connected' : 'Not Connected',
                          connected: connected,
                          email: connected
                              ? connectedEmail?.isNotEmpty == true
                                    ? connectedEmail!
                                    : 'Connected account'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: busy
                          ? null
                          : connected
                          ? onSync
                          : onConnect,
                      icon: busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(connected ? Icons.sync : Icons.login),
                      label: Text(
                        connecting
                            ? 'Connecting...'
                            : syncing
                            ? 'Syncing...'
                            : connected
                            ? 'Sync Now'
                            : 'Connect',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xffe5161d),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: AppFontSizes.buttonText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusGraphic extends StatelessWidget {
  const _StatusGraphic({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: connected ? const Color(0xffeaf8ed) : const Color(0xfffff0ef),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.cloud_outlined,
            color: connected
                ? const Color(0xff119048)
                : const Color(0xffbe4b4b),
            size: 36,
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: connected
                    ? const Color(0xff119048)
                    : const Color(0xffd90416),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                connected ? Icons.check : Icons.close,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.connected,
    this.email,
  });

  final String label;
  final bool connected;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: connected ? const Color(0xffeaf8ed) : const Color(0xffffeeee),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: connected
                  ? const Color(0xff0b7a38)
                  : const Color(0xffc71421),
              fontSize: AppFontSizes.smallMetadata,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (email != null) ...[
            const SizedBox(width: 6),
            const Text(
              '•',
              style: TextStyle(
                color: Color(0xff5f7f68),
                fontSize: AppFontSizes.smallMetadata,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                email!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff0b7a38),
                  fontSize: AppFontSizes.smallMetadata,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AutoSyncTile extends StatelessWidget {
  const _AutoSyncTile({
    required this.connected,
    required this.value,
    required this.onChanged,
  });

  final bool connected;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      child: Row(
        children: [
          _SmallGraphic(
            icon: Icons.autorenew,
            enabled: connected,
            enabledColor: const Color(0xff119048),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Auto Sync',
              style: TextStyle(
                color: Color(0xff201716),
                fontSize: AppFontSizes.cardTitle,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: connected ? onChanged : null,
            activeThumbColor: const Color(0xffe5161d),
          ),
        ],
      ),
    );
  }
}

class _SyncHistoryTile extends StatelessWidget {
  const _SyncHistoryTile({
    required this.lastSyncedAt,
    required this.lastSyncStatus,
    required this.enabled,
    required this.onTap,
  });

  final DateTime? lastSyncedAt;
  final String? lastSyncStatus;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SmallGraphic(
                  icon: Icons.history,
                  enabled: enabled && lastSyncedAt != null,
                  enabledColor: const Color(0xff245d94),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Sync History',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xff201716),
                      fontSize: AppFontSizes.cardTitle,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Color(0xff4c403d)),
              ],
            ),
            if (lastSyncedAt != null || lastSyncStatus != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 40),
                  if (lastSyncedAt != null)
                    _LastSyncedBadge(date: lastSyncedAt!),
                  if (lastSyncedAt != null && lastSyncStatus != null)
                    const SizedBox(width: 8),
                  if (lastSyncStatus != null)
                    _SyncStatusBadge(status: lastSyncStatus!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SmallGraphic extends StatelessWidget {
  const _SmallGraphic({
    required this.icon,
    required this.enabled,
    required this.enabledColor,
  });

  final IconData icon;
  final bool enabled;
  final Color enabledColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: enabled
            ? enabledColor.withValues(alpha: 0.12)
            : const Color(0xfff1eeee),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: enabled ? enabledColor : const Color(0xffb9aeae),
        size: 25,
      ),
    );
  }
}

class _LastSyncedBadge extends StatelessWidget {
  const _LastSyncedBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xffeaf3ff),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Last ${_formatShortDateTime(date)}',
        style: const TextStyle(
          color: Color(0xff245d94),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SyncStatusBadge extends StatelessWidget {
  const _SyncStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'success' => const Color(0xff119048),
      'failed' => const Color(0xffc71421),
      'cancelled' => const Color(0xfff59e0b),
      'terminated' => const Color(0xff7d5a50),
      _ => const Color(0xff8b807d),
    };
    final label = switch (status) {
      'success' => 'Success',
      'failed' => 'Failed',
      'cancelled' => 'Cancelled',
      'terminated' => 'Terminated',
      _ => 'Unknown',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class ProfileSyncHistoryPage extends StatelessWidget {
  const ProfileSyncHistoryPage({
    super.key,
    required this.syncHistory,
    required this.driveConnected,
  });

  final List<SyncHistoryEntry> syncHistory;
  final bool driveConnected;

  @override
  Widget build(BuildContext context) {
    final sortedHistory = [...syncHistory]
      ..sort((a, b) => b.at.compareTo(a.at));

    return Scaffold(
      backgroundColor: const Color(0xfffffbf7),
      appBar: AppBar(
        backgroundColor: const Color(0xfffffbf7),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Sync History',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            if (!driveConnected || sortedHistory.isEmpty)
              _EmptyHistory(enabled: driveConnected)
            else
              for (final entry in sortedHistory)
                _HistoryRow(entry: entry, latest: entry == sortedHistory.first),
          ],
        ),
      ),
    );
  }
}

class ProfilePermissionsPage extends StatefulWidget {
  const ProfilePermissionsPage({super.key});

  @override
  State<ProfilePermissionsPage> createState() => _ProfilePermissionsPageState();
}

class _ProfilePermissionsPageState extends State<ProfilePermissionsPage> {
  phone_contacts.PermissionStatus? _contactsStatus;
  bool _loadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadContactsStatus();
  }

  Future<void> _loadContactsStatus() async {
    setState(() => _loadingContacts = true);
    final status = await phone_contacts.FlutterContacts.permissions.check(
      phone_contacts.PermissionType.readWrite,
    );
    if (!mounted) return;
    setState(() {
      _contactsStatus = status;
      _loadingContacts = false;
    });
  }

  Future<void> _requestContactsAccess() async {
    setState(() => _loadingContacts = true);
    final status = await phone_contacts.FlutterContacts.permissions.request(
      phone_contacts.PermissionType.readWrite,
    );
    if (!mounted) return;
    setState(() {
      _contactsStatus = status;
      _loadingContacts = false;
    });
  }

  Future<void> _openAppSettings() async {
    await phone_contacts.FlutterContacts.permissions.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    final contactsStatus = _contactsStatus;

    return Scaffold(
      backgroundColor: const Color(0xfffffbf7),
      appBar: AppBar(
        backgroundColor: const Color(0xfffffbf7),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Permissions',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            _PermissionCard(
              icon: Icons.contacts_outlined,
              iconColor: const Color(0xff119048),
              title: 'Contacts',
              subtitle:
                  'Used to choose donors from phone contacts and optionally save blood contacts back to your phone.',
              statusLabel: _loadingContacts
                  ? 'Checking'
                  : _permissionStatusLabel(contactsStatus),
              granted: _isPermissionGranted(contactsStatus),
              actionLabel:
                  _isPermissionGranted(contactsStatus) || _loadingContacts
                  ? null
                  : _shouldOpenSettings(contactsStatus)
                  ? 'Open Settings'
                  : 'Allow Access',
              busy: _loadingContacts,
              onAction: _isPermissionGranted(contactsStatus) || _loadingContacts
                  ? null
                  : _shouldOpenSettings(contactsStatus)
                  ? _openAppSettings
                  : _requestContactsAccess,
            ),
            const SizedBox(height: 12),
            _PermissionCard(
              icon: Icons.photo_library_outlined,
              iconColor: const Color(0xff8b2be2),
              title: 'Photos',
              subtitle:
                  'Used only when you choose a donor photo from your gallery.',
              statusLabel: 'Managed by system',
              granted: null,
              actionLabel: 'Open Settings',
              onAction: _openAppSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileAboutPage extends StatelessWidget {
  const ProfileAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffffbf7),
      appBar: AppBar(
        backgroundColor: const Color(0xfffffbf7),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'About Blood Contacts',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: const [
            _AboutHeroCard(),
            SizedBox(height: 12),
            _AboutInfoCard(),
            SizedBox(height: 12),
            _AboutTextCard(),
          ],
        ),
      ),
    );
  }
}

class ProfilePrivacyDataPage extends StatelessWidget {
  const ProfilePrivacyDataPage({super.key, required this.driveConnected});

  final bool driveConnected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffffbf7),
      appBar: AppBar(
        backgroundColor: const Color(0xfffffbf7),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Privacy & Data',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            _SettingsCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _SmallGraphic(
                          icon: Icons.lock_outline,
                          enabled: true,
                          enabledColor: Color(0xff119048),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your contacts stay on your device',
                            style: TextStyle(
                              color: const Color(0xff201716),
                              fontSize: AppFontSizes.cardTitle,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Blood Contacts stores donor and need data locally in the app database. You control when data is synced.',
                      style: TextStyle(
                        color: Color(0xff665653),
                        fontSize: AppFontSizes.bodyText,
                        height: 1.28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _SettingsCard(
              child: Column(
                children: [
                  _InfoRow(label: 'Primary storage', value: 'On-device SQLite'),
                  _CardDivider(),
                  _InfoRow(
                    label: 'Sync provider',
                    value: 'Google Drive (optional)',
                  ),
                  _CardDivider(),
                  _InfoRow(
                    label: 'Sync behavior',
                    value: 'Manual unless auto-sync is enabled',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Google Drive backup status',
                        style: TextStyle(
                          color: Color(0xff201716),
                          fontSize: AppFontSizes.cardTitle,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _PermissionStatusBadge(
                      label: driveConnected ? 'Connected' : 'Not connected',
                      color: driveConnected
                          ? const Color(0xff119048)
                          : const Color(0xffc71421),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _SettingsCard(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'You can disconnect Google Drive anytime from the Profile page. Notification preferences only affect local reminders and do not send data to third-party services.',
                  style: TextStyle(
                    color: Color(0xff413431),
                    fontSize: AppFontSizes.bodyText,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.granted,
    this.actionLabel,
    this.onAction,
    this.busy = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String statusLabel;
  final bool? granted;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final resolvedGranted = granted;
    final statusColor = resolvedGranted == null
        ? const Color(0xff245d94)
        : resolvedGranted
        ? const Color(0xff119048)
        : const Color(0xffc71421);

    return _SettingsCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SmallGraphic(
                  icon: icon,
                  enabled: true,
                  enabledColor: iconColor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xff201716),
                          fontSize: AppFontSizes.cardTitle,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xff665653),
                          fontSize: AppFontSizes.bodyText,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _PermissionStatusBadge(label: statusLabel, color: statusColor),
                if (busy || actionLabel != null) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: busy ? null : onAction,
                    child: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionStatusBadge extends StatelessWidget {
  const _PermissionStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppFontSizes.smallMetadata,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AboutHeroCard extends StatelessWidget {
  const _AboutHeroCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xffe5161d),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.bloodtype, color: Colors.white, size: 34),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blood Contacts',
                    style: TextStyle(
                      color: Color(0xff201716),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Color(0xff665653),
                      fontSize: AppFontSizes.bodyText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutInfoCard extends StatelessWidget {
  const _AboutInfoCard();

  @override
  Widget build(BuildContext context) {
    return const _SettingsCard(
      child: Column(
        children: [
          _InfoRow(label: 'App name', value: 'Blood Contacts'),
          _CardDivider(),
          _InfoRow(label: 'Version', value: '1.0.0'),
          _CardDivider(),
          _InfoRow(label: 'Data storage', value: 'On-device with Drive backup'),
        ],
      ),
    );
  }
}

class _AboutTextCard extends StatelessWidget {
  const _AboutTextCard();

  @override
  Widget build(BuildContext context) {
    return const _SettingsCard(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Blood Contacts helps you keep donor details, blood requests, and backup settings organized on your device. Google Drive sync is optional and controlled from the Profile page.',
          style: TextStyle(
            color: Color(0xff413431),
            fontSize: AppFontSizes.bodyText,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff665653),
                fontSize: AppFontSizes.bodyText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xff201716),
                fontSize: AppFontSizes.bodyText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfffffbf8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffffe8e0)),
      ),
      child: Text(
        enabled
            ? 'No sync history yet'
            : 'Connect Google Drive to start history',
        style: const TextStyle(
          color: Color(0xff9a8a86),
          fontSize: AppFontSizes.bodyText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.latest});

  final SyncHistoryEntry entry;
  final bool latest;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (entry.status) {
      'success' => 'Success',
      'failed' => 'Failed',
      'cancelled' => 'Cancelled',
      'terminated' => 'Terminated',
      _ => 'Unknown',
    };
    final statusColor = switch (entry.status) {
      'success' => const Color(0xff119048),
      'failed' => const Color(0xffc71421),
      'cancelled' => const Color(0xfff59e0b),
      'terminated' => const Color(0xff7d5a50),
      _ => const Color(0xff8b807d),
    };
    final statusIcon = switch (entry.status) {
      'success' => Icons.check_circle,
      'failed' => Icons.error,
      'cancelled' => Icons.remove_circle,
      'terminated' => Icons.stop_circle,
      _ => Icons.schedule,
    };
    final hasCounts = entry.contactCount != null || entry.needCount != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: latest ? const Color(0xfffff1ed) : const Color(0xfffffbf8),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: latest ? const Color(0xffffc5b9) : const Color(0xffffe8e0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatDateTime(entry.at),
                  style: const TextStyle(
                    color: Color(0xff413431),
                    fontSize: AppFontSizes.bodyText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: AppFontSizes.smallMetadata,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (latest)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    'Latest',
                    style: TextStyle(
                      color: Color(0xffe5161d),
                      fontSize: AppFontSizes.smallMetadata,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          if (hasCounts) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _HistoryCountChip(
                  label: '${entry.contactCount ?? 0} contacts',
                  color: const Color(0xff245d94),
                ),
                const SizedBox(width: 8),
                _HistoryCountChip(
                  label: '${entry.needCount ?? 0} needs',
                  color: const Color(0xff7a4d00),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryCountChip extends StatelessWidget {
  const _HistoryCountChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff201716),
                    fontSize: AppFontSizes.cardTitle,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xff4c403d)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 80, right: 20),
      child: Divider(height: 1, color: Color(0xffffe8e0)),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${_monthName(local.month)} ${local.day}, ${local.year} '
      '${_formatTime(local)}';
}

String _formatShortDateTime(DateTime value) {
  final local = value.toLocal();
  return '${_shortMonthName(local.month)} ${local.day}, ${_formatTime(local)}';
}

bool _isPermissionGranted(phone_contacts.PermissionStatus? status) {
  return status == phone_contacts.PermissionStatus.granted ||
      status == phone_contacts.PermissionStatus.limited;
}

bool _shouldOpenSettings(phone_contacts.PermissionStatus? status) {
  return status == phone_contacts.PermissionStatus.permanentlyDenied ||
      status == phone_contacts.PermissionStatus.restricted;
}

String _permissionStatusLabel(phone_contacts.PermissionStatus? status) {
  return switch (status) {
    phone_contacts.PermissionStatus.granted => 'Allowed',
    phone_contacts.PermissionStatus.limited => 'Limited',
    phone_contacts.PermissionStatus.denied => 'Denied',
    phone_contacts.PermissionStatus.permanentlyDenied => 'Open Settings',
    phone_contacts.PermissionStatus.restricted => 'Restricted',
    phone_contacts.PermissionStatus.notDetermined => 'Not requested',
    null => 'Unknown',
  };
}

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String _monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[month - 1];
}

String _shortMonthName(int month) {
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
  return months[month - 1];
}
