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
                      color: item.isRead
                          ? Colors.white
                          : const Color(0xfffff6f7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item.isRead
                            ? const Color(0xffece7e5)
                            : const Color(0xffffd8db),
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
                                color: Color(0xffe5161d),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.message,
                          style: const TextStyle(
                            color: Color(0xff5f5351),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatNotificationTime(item.createdAt),
                          style: const TextStyle(
                            color: Color(0xff8b7f7d),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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
