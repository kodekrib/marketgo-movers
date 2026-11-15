import 'package:flutter/material.dart';

import '../app.dart';
import '../models/moving.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/mover_service.dart';
import '../widgets/animated_3d.dart';
import '../widgets/common.dart';
import '../widgets/movers_app_bar.dart';
import '../widgets/skeuo.dart';
import 'account_screen.dart';
import 'book_move_screen.dart';
import 'faq_screen.dart';
import 'login_screen.dart';
import 'my_moves_screen.dart';
import 'job_detail_screen.dart';

/// MarketGO Movers — app shell with bottom navigation.
///
/// Three tabs: Home (book + active move), Activity (history), Account.
/// Booking and tracking are gated behind marketgo-api auth (mover role).
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

  static const _tabTitles = ['Home', 'Activity', 'Account'];

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _auth = AuthModel(api: _api);
    MoversSession.instance = _auth;
    _movers = MoverService(api: _api);
    _auth.restoreSession();
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
          appBar:
              MoversAppBar(title: _tabIndex == 0 ? '' : _tabTitles[_tabIndex]),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEFF2))),
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          selected ? MoversApp.brandOrange : Colors.transparent,
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
        ),
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
    if (token == null) {
      if (mounted) setState(() => _activeJob = null);
      return;
    }
    setState(() => _loading = true);
    try {
      final jobs = await widget.movers.jobs(token);
      final live = jobs.where((j) => j.isActive).toList();
      if (mounted) {
        setState(() => _activeJob = live.isNotEmpty ? live.first : null);
      }
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
          child: _LandingHero(
            name: name,
            onHelp: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FaqScreen()),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: _BookingCta(onTap: _openBook),
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
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _ActiveJobCard(
                  job: _activeJob!,
                  onRefresh: _refresh,
                  onTap: () => _openJob(_activeJob!),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: Duration(milliseconds: 240),
            child: _HowItWorks(),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 300),
            child: _QuickActions(
              onBook: _openBook,
              onActivity: widget.onNavigateToActivity,
              onHelp: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const FaqScreen()),
              ),
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

/// Animated landing hero: dark brand gradient, a looping 3D truck and the
/// greeting. Everything sits in a padded column, so nothing can overlap.
class _LandingHero extends StatelessWidget {
  const _LandingHero({required this.name, required this.onHelp});

  final String name;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final width = MediaQuery.of(context).size.width;
    final truckSize = (width * 0.36).clamp(104.0, 152.0);
    final headlineSize = width < 360 ? 21.0 : 24.0;
    final deep =
        Color.lerp(MoversApp.brandOrangeDark, const Color(0xFF0E1116), 0.74)!;
    final deeper =
        Color.lerp(MoversApp.brandOrangeDark, const Color(0xFF0E1116), 0.92)!;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deep, deeper],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -60,
            child: PulsingGlow(
              diameter: 260,
              color: MoversApp.brandOrange.withOpacity(0.50),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -70,
            child: GlowOrb(
              diameter: 230,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white.withOpacity(0.18)),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Ready to move something heavy?',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.62),
                              fontSize: 13,
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
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Move big things, without the hassle.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: headlineSize,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Book a truck, van or lorry in seconds.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.68),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    MovingTruck3D(size: truckSize, motionLines: false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact three-step explainer that makes the service obvious at a glance.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How it works',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          const SkeuoCard(
            radius: 22,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                _HowStep(
                  index: 1,
                  icon: Icons.pin_drop_rounded,
                  title: 'Set your route',
                  subtitle: 'Add pickup and drop-off details.',
                ),
                Divider(height: 1, color: Color(0xFFEEF0F3)),
                _HowStep(
                  index: 2,
                  icon: Icons.support_agent_rounded,
                  title: 'Get matched',
                  subtitle: 'We assign a verified mover and vehicle.',
                ),
                Divider(height: 1, color: Color(0xFFEEF0F3)),
                _HowStep(
                  index: 3,
                  icon: Icons.payments_rounded,
                  title: 'Track & pay',
                  subtitle: 'Follow the move live and pay upfront.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final int index;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Skeuo.shade(MoversApp.brandOrangeLight, 0.25),
                      Skeuo.shade(MoversApp.brandOrangeLight, -0.06),
                    ],
                  ),
                  border: Border.all(
                      color: Skeuo.shade(MoversApp.brandOrangeLight, -0.18)),
                  boxShadow: Skeuo.raisedShadows(depth: 0.4),
                ),
                child: Icon(icon, color: MoversApp.brandOrangeDark, size: 22),
              ),
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: MoversApp.brandOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: MoversApp.ink,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: MoversApp.inkMuted,
                      height: 1.35,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Illustrated invitation to the full booking form.
class _BookingCta extends StatelessWidget {
  const _BookingCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: SkeuoCard(
        radius: 26,
        padding: const EdgeInsets.all(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                decoration: BoxDecoration(
                  color: MoversApp.brandOrangeLight.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _stop(Icons.inventory_2_rounded, 'Pack'),
                    _connector(),
                    _stop(Icons.local_shipping_rounded, 'Move'),
                    _connector(),
                    _stop(Icons.home_rounded, 'Arrive'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your next move starts here',
              style: TextStyle(
                fontSize: 21,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: MoversApp.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'From a single item to a whole home. Tell us where, and we’ll help you get moving.',
              style: TextStyle(
                  fontSize: 13, height: 1.5, color: MoversApp.inkMuted),
            ),
            const SizedBox(height: 18),
            SkeuoButton(
              label: 'Book a move',
              icon: Icons.arrow_forward_rounded,
              color: MoversApp.brandOrange,
              height: 52,
              radius: 16,
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stop(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: MoversApp.brandOrange.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: MoversApp.brandOrangeDark, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                color: MoversApp.ink,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _connector() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 4, right: 4, bottom: 22),
        child: Row(
          children: [
            Expanded(
                child: Container(
                    height: 2, color: MoversApp.brandOrange.withOpacity(0.3))),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: MoversApp.brandOrange),
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
    return SkeuoCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.22), color.withOpacity(0.10)],
              ),
              border: Border.all(color: color.withOpacity(0.20)),
              boxShadow: Skeuo.raisedShadows(depth: 0.35, tint: color),
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
    );
  }
}
