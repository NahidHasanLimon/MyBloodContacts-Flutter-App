import 'package:blood_contacts/src/app/app_theme.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.driveFolder,
    required this.onConnectDrive,
    required this.onSyncData,
    required this.onAutoBackup,
    required this.onBackupHistory,
    required this.onAppearance,
    required this.onNotifications,
    required this.onAppLock,
    required this.onPrivacy,
    required this.onPermissions,
    required this.onAbout,
    required this.onRate,
  });

  final String? driveFolder;
  final VoidCallback onConnectDrive;
  final VoidCallback onSyncData;
  final VoidCallback onAutoBackup;
  final VoidCallback onBackupHistory;
  final VoidCallback onAppearance;
  final VoidCallback onNotifications;
  final VoidCallback onAppLock;
  final VoidCallback onPrivacy;
  final VoidCallback onPermissions;
  final VoidCallback onAbout;
  final VoidCallback onRate;

  bool get _driveConnected => driveFolder?.trim().isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xfffbfaf8),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 110),
              sliver: SliverList.list(
                children: [
                  _ProfileHeader(
                    onNotifications: onNotifications,
                    onSettings: onAppearance,
                  ),
                  const SizedBox(height: 26),
                  const _SectionTitle('Storage & Backup'),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _DriveBackupTile(
                        connected: _driveConnected,
                        folderName: driveFolder,
                        onConnect: onConnectDrive,
                        onSync: onSyncData,
                      ),
                      const _CardDivider(),
                      _SettingsTile(
                        icon: Icons.history_toggle_off,
                        iconColor: const Color(0xff119048),
                        iconBackground: const Color(0xffeaf8ed),
                        title: 'Auto Backup',
                        subtitle: 'Off',
                        onTap: onAutoBackup,
                      ),
                      const _CardDivider(),
                      _SettingsTile(
                        icon: Icons.restore_outlined,
                        iconColor: const Color(0xff245d94),
                        iconBackground: const Color(0xffeaf3ff),
                        title: 'Backup History',
                        subtitle: 'No backups yet',
                        onTap: onBackupHistory,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Preferences'),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.brush_outlined,
                        iconColor: const Color(0xff8b2be2),
                        iconBackground: const Color(0xfff5eaff),
                        title: 'App Appearance',
                        subtitle: 'Light theme',
                        onTap: onAppearance,
                      ),
                      const _CardDivider(),
                      _SettingsTile(
                        icon: Icons.notifications_none,
                        iconColor: const Color(0xffe8a100),
                        iconBackground: const Color(0xfffff7df),
                        title: 'Notifications',
                        subtitle: 'Manage notification preferences',
                        onTap: onNotifications,
                      ),
                      const _CardDivider(),
                      _SettingsTile(
                        icon: Icons.lock_outline,
                        iconColor: const Color(0xff1d74e8),
                        iconBackground: const Color(0xffeaf3ff),
                        title: 'App Lock',
                        subtitle: 'Off',
                        onTap: onAppLock,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Privacy & Security'),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.verified_user_outlined,
                        iconColor: const Color(0xff119048),
                        iconBackground: const Color(0xffeaf8ed),
                        title: 'Privacy & Data',
                        subtitle: 'Your data stays on your device',
                        onTap: onPrivacy,
                      ),
                      const _CardDivider(),
                      _SettingsTile(
                        icon: Icons.key_outlined,
                        iconColor: const Color(0xffff8a00),
                        iconBackground: const Color(0xfffff0df),
                        title: 'Permissions',
                        subtitle: 'Manage app permissions',
                        onTap: onPermissions,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('About'),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.info_outline,
                        iconColor: const Color(0xff4b5565),
                        iconBackground: const Color(0xfff1f2f4),
                        title: 'About Blood Contacts',
                        subtitle: 'Version 1.0.0',
                        onTap: onAbout,
                      ),
                      const _CardDivider(),
                      _SettingsTile(
                        icon: Icons.favorite_border,
                        iconColor: const Color(0xffe5161d),
                        iconBackground: const Color(0xffffeef0),
                        title: 'Rate Us',
                        subtitle: 'If you like the app, please rate us',
                        onTap: onRate,
                      ),
                    ],
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
  });

  final VoidCallback onNotifications;
  final VoidCallback onSettings;

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
                  color: Colors.black,
                  fontSize: AppFontSizes.pageTitle,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Manage your preferences and backup',
                style: TextStyle(
                  color: Color(0xff4b5262),
                  fontSize: AppFontSizes.bodyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: Icons.notifications_none,
          badgeText: '3',
          tooltip: 'Notifications',
          onTap: onNotifications,
        ),
        const SizedBox(width: 12),
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
        borderRadius: BorderRadius.circular(16),
        child: SizedBox.square(
          dimension: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(icon, color: const Color(0xff252a3a), size: 30),
              ),
              if (badgeText != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xffe5161d),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
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
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: AppFontSizes.sectionTitle,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffeee5e5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0d000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _DriveBackupTile extends StatelessWidget {
  const _DriveBackupTile({
    required this.connected,
    required this.folderName,
    required this.onConnect,
    required this.onSync,
  });

  final bool connected;
  final String? folderName;
  final VoidCallback onConnect;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return _SettingsTileShell(
      onTap: onConnect,
      icon: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xffeef6ff),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.cloud_outlined,
          color: Color(0xff1d74e8),
          size: 31,
        ),
      ),
      title: 'Google Drive Backup',
      subtitle: connected
          ? 'Connected to ${folderName!.trim()}'
          : 'Not connected',
      subtitleColor: connected
          ? const Color(0xff4b5262)
          : const Color(0xffd90416),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: connected ? onSync : onConnect,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffe5161d),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: AppFontSizes.buttonText,
                fontWeight: FontWeight.w900,
              ),
              minimumSize: const Size(94, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: Text(connected ? 'Sync Data' : 'Connect'),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.black, size: 28),
        ],
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
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingsTileShell(
      onTap: onTap,
      icon: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: iconBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 30),
      ),
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right, color: Colors.black, size: 28),
    );
  }
}

class _SettingsTileShell extends StatelessWidget {
  const _SettingsTileShell({
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.subtitleColor = const Color(0xff4b5262),
  });

  final VoidCallback onTap;
  final Widget icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: AppFontSizes.cardTitle,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: AppFontSizes.bodyText,
                        fontWeight: FontWeight.w600,
                        height: 1.22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
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
      padding: EdgeInsets.only(left: 94, right: 26),
      child: Divider(height: 1, color: Color(0xffe8e9ee)),
    );
  }
}
