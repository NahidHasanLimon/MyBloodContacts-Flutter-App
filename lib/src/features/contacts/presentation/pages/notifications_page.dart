import 'package:blood_contacts/src/features/contacts/domain/app_notification.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.notifications,
    required this.onMarkAllRead,
    required this.onOpenPreferences,
    required this.onToggleSeen,
  });

  final List<AppNotification> notifications;
  final Future<void> Function() onMarkAllRead;
  final VoidCallback onOpenPreferences;
  final Future<void> Function(AppNotification item, bool markSeen) onToggleSeen;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late List<AppNotification> _items;

  @override
  void initState() {
    super.initState();
    _items = List<AppNotification>.from(widget.notifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Notification preferences',
            onPressed: widget.onOpenPreferences,
            icon: const Icon(Icons.tune),
          ),
          TextButton(
            onPressed: _items.isEmpty
                ? null
                : () async {
                    await widget.onMarkAllRead();
                    if (!mounted) return;
                    final now = DateTime.now();
                    setState(() {
                      _items = _items
                          .map(
                            (item) => item.isRead
                                ? item
                                : AppNotification(
                                    id: item.id,
                                    code: item.code,
                                    title: item.title,
                                    message: item.message,
                                    createdAt: item.createdAt,
                                    readAt: now,
                                  ),
                          )
                          .toList();
                    });
                  },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('No notifications yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _items[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: item.isRead
                      ? null
                      : () async {
                          await widget.onToggleSeen(item, true);
                          if (!mounted) return;
                          setState(() {
                            _items[index] = AppNotification(
                              id: item.id,
                              code: item.code,
                              title: item.title,
                              message: item.message,
                              createdAt: item.createdAt,
                              readAt: DateTime.now(),
                            );
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item.isRead
                            ? const Color(0xffece7e5)
                            : const Color(0xffd8e5ff),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: item.isRead
                                      ? FontWeight.w700
                                      : FontWeight.w900,
                                ),
                              ),
                            ),
                            if (!item.isRead)
                              const Icon(
                                Icons.fiber_manual_record,
                                size: 10,
                                color: Color(0xff3b82f6),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _humanizeNotificationMessage(item),
                          style: const TextStyle(
                            color: Color(0xff5f5351),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_outlined,
                              size: 14,
                              color: Color(0xff665653),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatNotificationTime(item.createdAt),
                              style: const TextStyle(
                                color: Color(0xff665653),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

String _humanizeNotificationMessage(AppNotification item) {
  final raw = item.message.trim();
  final lower = raw.toLowerCase();
  final isSyncRelated = item.code.startsWith('sync_');
  if (!isSyncRelated) return raw;

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
  if (lower.contains('exception:') ||
      lower.contains('stateerror:') ||
      lower.contains('typeerror') ||
      lower.contains('missingpluginexception')) {
    return 'Sync could not complete. Please try again.';
  }
  return raw;
}

String _formatNotificationTime(DateTime createdAt) {
  final now = DateTime.now();
  final diff = now.difference(createdAt);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

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
  final hour12 = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
  final minute = createdAt.minute.toString().padLeft(2, '0');
  final suffix = createdAt.hour >= 12 ? 'PM' : 'AM';
  return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}, $hour12:$minute $suffix';
}
