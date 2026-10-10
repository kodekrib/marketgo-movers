import 'package:flutter/material.dart';

import '../app.dart';
import '../models/moving.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/mover_service.dart';
import '../widgets/common.dart';
import 'account_screen.dart';
import 'book_move_screen.dart';
import 'faq_screen.dart';
import 'login_screen.dart';
import 'my_moves_screen.dart';
import 'job_detail_screen.dart';

/// MarketGO Movers — app shell with bottom navigation.
///
/// Three tabs: Home (book + active move), Activity (history), Account.
/// Booking and tracking are gated behind marketgo-api auth; demo sessions show
/// sample data so the app can be explored before the backend is up.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiClient _api;
  late final AuthModel _auth;
  late final MoverService _movers;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _auth = AuthModel(api: _api);
    _movers = MoverService(api: _api);
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        return Scaffold(
          body: _buildTab(_tabIndex),
          bottomNavigationBar: _MoversNav(
            currentIndex: _tabIndex,
            onTap: (i) => setState(() => _tabIndex = i),
          ),
        );
      },
    );
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return BookTab(
          key: ValueKey('book-${_auth.isAuthenticated}'),
          auth: _auth,
          movers: _movers,
          onNavigateToActivity: () => setState(() => _tabIndex = 1),
        );
      case 1:
        return MyMovesTab(
          key: ValueKey('moves-${_auth.isAuthenticated}'),
          auth: _auth,
          movers: _movers,
        );
      default:
        return AccountTab(
          auth: _auth,
          movers: _movers,
          onLogout: () => setState(() => _tabIndex = 0),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation (Bolt-style pill)
// ---------------------------------------------------------------------------

class _MoversNav extends StatelessWidget {
  const _MoversNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.receipt_long_rounded, 'Activity'),
      (Icons.person_rounded, 'Account'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: List.generate(items.length, (index) {
          final (icon, label) = items[index];
          final selected = index == currentIndex;
          final color = selected ? Colors.white : const Color(0xFF9AA1AA);
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? MoversApp.brandOrange : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home tab (Uber/Bolt-style)
// ---------------------------------------------------------------------------

class BookTab extends StatefulWidget {
  const BookTab({
    super.key,
    required this.auth,
    required this.movers,
    this.onNavigateToActivity,
  });

  final AuthModel auth;
  final MoverService movers;
  final VoidCallback? onNavigateToActivity;

  @override
  State<BookTab> createState() => _BookTabState();
}

class _BookTabState extends State<BookTab> {
  static const _vehicleTypes = [
    ('pickup_truck', 'Pickup', Icons.local_shipping_rounded),
    ('van', 'Van', Icons.directions_car_rounded),
    ('mini_truck', 'Mini truck', Icons.fire_truck_rounded),
    ('lorry', 'Lorry', Icons.airport_shuttle_rounded),
  ];

  MovingJob? _activeJob;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  @override
  void didUpdateWidget(covariant BookTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auth.isAuthenticated != widget.auth.isAuthenticated) {
      _loadActive();
    }
  }

  Future<void> _loadActive() async {
    final token = widget.auth.accessToken;
    if (token == null || token == 'demo.access') {
      final active = demoMovingJobs().where((j) => j.isActive).toList();
      if (mounted)
        setState(() => _activeJob = active.isNotEmpty ? active.first : null);
      return;
    }
    setState(() => _loading = true);
    try {
      final jobs = await widget.movers.jobs(token);
      final live = jobs.where((j) => j.isActive).toList();
      if (mounted)
        setState(() => _activeJob = live.isNotEmpty ? live.first : null);
    } catch (_) {
      if (mounted) setState(() => _activeJob = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() => _loadActive();

  @override
  Widget build(BuildContext context) {
    final name =
        widget.auth.isAuthenticated ? widget.auth.user!.firstName : 'there';
    return AppScrollTab(
      slivers: [
        SliverToBoxAdapter(
          child: _HeroHeader(
            name: name,
            onHelp: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FaqScreen()),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _WhereToBar(
            onTap: _openBook,
            onVehicle: _openBookWithVehicle,
            vehicleTypes: _vehicleTypes,
          ),
        ),
        if (_loading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_activeJob != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _ActiveJobCard(
                job: _activeJob!,
                onRefresh: _refresh,
                onTap: () => _openJob(_activeJob!),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: _QuickActions(
            onBook: _openBook,
            onActivity: widget.onNavigateToActivity,
            onHelp: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FaqScreen()),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  void _openBook() {
    if (!widget.auth.isAuthenticated) {
      _openLogin();
      return;
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) =>
                BookMoveScreen(auth: widget.auth, movers: widget.movers),
          ),
        )
        .then((_) => _refresh());
  }

  void _openBookWithVehicle(String vehicleType) {
    if (!widget.auth.isAuthenticated) {
      _openLogin();
      return;
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => BookMoveScreen(
              auth: widget.auth,
              movers: widget.movers,
              initialVehicleType: vehicleType,
            ),
          ),
        )
        .then((_) => _refresh());
  }

  void _openJob(MovingJob job) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => JobDetailScreen(
              job: job,
              auth: widget.auth,
              movers: widget.movers,
              readOnly: false,
              onCancel: () {},
            ),
          ),
        )
        .then((_) => _refresh());
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(auth: widget.auth, onAuthenticated: () {}),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home widgets
// ---------------------------------------------------------------------------

/// Glossy dark hero band on the Home tab: greeting, brand-glow ochre accents
/// and a soft rounded base for the where-to card to float over.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.name, required this.onHelp});

  final String name;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14171C), Color(0xFF262B33)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: _Glow(
                diameter: 220, color: MoversApp.brandOrange.withOpacity(0.28)),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: _Glow(
                diameter: 200,
                color: MoversApp.brandOrangeLight.withOpacity(0.12)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: MoversApp.brandOrangeLight,
                    child: Icon(Icons.local_shipping_rounded,
                        color: MoversApp.brandOrangeDark),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $name 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Ready to move something heavy?',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.62),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onHelp,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.10),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.help_outline_rounded),
                  tooltip: 'Help & FAQ',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}

/// Uber-style destination card: pickup + drop-off rows that open booking.
class _WhereToBar extends StatelessWidget {
  const _WhereToBar({
    required this.onTap,
    required this.onVehicle,
    required this.vehicleTypes,
  });

  final VoidCallback onTap;
  final ValueChanged<String> onVehicle;
  final List<(String, String, IconData)> vehicleTypes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: premiumShadow,
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Column(
                  children: [
                    _RouteRow(
                      icon: Icons.trip_origin_rounded,
                      color: MoversApp.brandOrange,
                      hint: 'Pickup location',
                    ),
                    Divider(height: 1, color: Color(0xFFEEF0F3)),
                    _RouteRow(
                      icon: Icons.sports_score_rounded,
                      color: Color(0xFF16A34A),
                      hint: 'Where are you moving to?',
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.search_rounded, size: 20),
                label: const Text('Book a move'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Row(
                children: List.generate(vehicleTypes.length, (index) {
                  final (type, label, icon) = vehicleTypes[index];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < vehicleTypes.length - 1 ? 8 : 0,
                      ),
                      child: _VehicleChip(
                        icon: icon,
                        label: label,
                        onTap: () => onVehicle(type),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow(
      {required this.icon, required this.color, required this.hint});

  final IconData icon;
  final Color color;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(
                color: Color(0xFF9AA1AA),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: MoversApp.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEAF0EE)),
        ),
        child: Column(
          children: [
            Icon(icon, color: MoversApp.brandOrangeDark, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: MoversApp.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  const _ActiveJobCard({
    required this.job,
    required this.onRefresh,
    required this.onTap,
  });

  final MovingJob job;
  final VoidCallback onRefresh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F2937), Color(0xFF111827)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x3D000000),
                blurRadius: 26,
                offset: Offset(0, 12)),
            BoxShadow(
                color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sailing_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Move in progress',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white, fontSize: 16),
                  ),
                ),
                StatusChip.statusFor(job),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${job.pickupAddress} → ${job.deliveryAddress}',
              style: const TextStyle(color: Colors.white70, fontSize: 13.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Move #${job.id}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12.5)),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onBook,
    required this.onActivity,
    required this.onHelp,
  });

  final VoidCallback onBook;
  final VoidCallback? onActivity;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        Icons.local_shipping_rounded,
        'Book a move',
        onBook,
        MoversApp.brandOrange
      ),
      (
        Icons.receipt_long_rounded,
        'My moves',
        onActivity,
        const Color(0xFF2563EB)
      ),
      (
        Icons.help_outline_rounded,
        'Help & FAQ',
        onHelp,
        const Color(0xFF16A34A)
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick actions',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(actions.length, (index) {
              final (icon, label, onTap, color) = actions[index];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < actions.length - 1 ? 10 : 0,
                  ),
                  child: _ActionTile(
                    icon: icon,
                    label: label,
                    color: color,
                    onTap: onTap ?? () {},
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAF0EE)),
            boxShadow: tileShadow,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: MoversApp.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
