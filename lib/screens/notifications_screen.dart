import '../widgets/swipe_notification.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/movers_app_bar.dart';

/// Notifications center for the movers app — move updates, quotes and promos.
/// Loads the shopper's real notifications from the backend.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  List<AppNotification>? _notifications;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = MoversSession.instance?.accessToken;
    if (token == null) {
      setState(() => _notifications = null);
      return;
    }
    setState(() => _loading = true);
    try {
      final notifs = await _service.list(token);
      if (!mounted) return;
      setState(() {
        _notifications = notifs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notifications = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifs = _notifications;

    return Scaffold(
      backgroundColor: MoversApp.surfaceMuted,
      appBar: MoversAppBar(
        title: 'Notifications',
        actions: [
          if (notifs != null && notifs.isNotEmpty)
            TextButton(
              onPressed: () async {
                final token = MoversSession.instance?.accessToken;
                if (token == null) return;
                await _service.markAllRead(token);
                _load();
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : notifs == null || notifs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No notifications yet.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              : _buildList(notifs, theme),
    );
  }

  Widget _buildList(List<AppNotification> notifs, ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: notifs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final n = notifs[index];
        final icon = _iconForType(n.type);
        final color = _colorForType(n.type);
        return SwipeNotification(
            id: n.id,
            onDelete: () async {
              final token = MoversSession.instance?.accessToken;
              if (token == null) throw StateError('Sign in required');
              await _service.delete(token, n.id);
            },
            onDeleted: () {
              if (mounted) {
                setState(() => _notifications =
                    _notifications?.where((e) => e.id != n.id).toList());
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: n.isRead ? Colors.white : MoversApp.brandOrangeLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEAF0EE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                n.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                            if (!n.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: MoversApp.brandOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(n.body, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 6),
                        Text(
                          _timeAgo(n.createdAt),
                          style:
                              theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ));
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'moving':
      case 'move':
        return Icons.local_shipping_rounded;
      case 'payment':
        return Icons.payments_outlined;
      case 'promo':
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'moving':
      case 'move':
        return MoversApp.brandOrangeDark;
      case 'payment':
        return const Color(0xFFF59E0B);
      case 'promo':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF7C3AED);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}
