import 'package:flutter/material.dart';

/// A notification leaves the list only after deletion succeeds on the API.
class SwipeNotification extends StatelessWidget {
  const SwipeNotification(
      {super.key,
      required this.id,
      required this.onDelete,
      required this.onDeleted,
      required this.child});
  final int id;
  final Future<void> Function() onDelete;
  final VoidCallback onDeleted;
  final Widget child;
  @override
  Widget build(BuildContext context) => Dismissible(
        key: ValueKey('notification-$id'),
        direction: DismissDirection.endToStart,
        background: Container(
            alignment: AlignmentDirectional.centerEnd,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.delete_outline, color: Colors.white)),
        confirmDismiss: (_) async {
          try {
            await onDelete();
            return true;
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'Could not delete notification. Please try again.')));
            }
            return false;
          }
        },
        onDismissed: (_) => onDeleted(),
        child: child,
      );
}
