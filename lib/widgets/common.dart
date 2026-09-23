// Shared UI atoms reused by every screen (DRY).
import 'package:flutter/material.dart';
import '../app.dart';
import '../models/moving.dart';

/// Formats a double amount in the app currency, e.g. 82000.0 -> "₦82,000".
String formatPrice(num value) {
  final s = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
    buffer.write(s[i]);
  }
  return '${MoversApp.currencySymbol}$buffer';
}

/// Soft hand-tuned card shadow that gives surfaces a premium depth without
/// the muddy look of default elevation shadows.
const List<BoxShadow> premiumShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 26, offset: Offset(0, 12)),
  BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
];

/// Gentle shadow for small tiles and chips sitting on a card.
const List<BoxShadow> tileShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
];

/// Coloured moving-job status pill.
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  static const Map<String, Color> _colors = {
    'Pending': Color(0xFFD97706),
    'Accepted': Color(0xFF2563EB),
    'On the way': Color(0xFF2563EB),
    'Arrived': Color(0xFF7C3AED),
    'Loading': Color(0xFF0891B2),
    'In transit': Color(0xFFEA580C),
    'Delivered': Color(0xFF16A34A),
    'Cancelled': Color(0xFFEF4444),
  };

  /// Status pill built from a moving job.
  factory StatusChip.statusFor(MovingJob job) {
    return StatusChip(movingJobStatusLabel(job.status));
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? _colors[label] ?? const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Page title used on tab root screens.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Standard scroll container for tab bodies (safe-area + bottom padding).
class AppScrollTab extends StatelessWidget {
  const AppScrollTab({super.key, required this.slivers});

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.top + 8),
        ),
        ...slivers,
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}