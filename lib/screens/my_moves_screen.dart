import 'package:flutter/material.dart';

import '../models/moving.dart';
import '../services/auth_service.dart';
import '../services/mover_service.dart';
import '../widgets/common.dart';
import 'job_detail_screen.dart';
import 'login_screen.dart';

/// Tab listing the customer's moving-job history (and active jobs).
class MyMovesTab extends StatefulWidget {
  const MyMovesTab({super.key, required this.auth, required this.movers});

  final AuthModel auth;
  final MoverService movers;

  @override
  State<MyMovesTab> createState() => _MyMovesTabState();
}

class _MyMovesTabState extends State<MyMovesTab> {
  List<MovingJob> _jobs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MyMovesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auth.isAuthenticated != widget.auth.isAuthenticated) {
      _load();
    }
  }

  Future<void> _load() async {
    final token = widget.auth.accessToken;
    if (token == null || token == 'demo.access') {
      if (mounted) setState(() => _jobs = demoMovingJobs());
      return;
    }
    setState(() => _loading = true);
    try {
      final jobs = await widget.movers.jobs(token);
      if (mounted) setState(() => _jobs = jobs);
    } catch (_) {
      if (mounted) setState(() => _jobs = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.auth.isAuthenticated) {
      return AuthPrompt(
        onSignIn: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LoginScreen(auth: widget.auth),
          ),
        ),
      );
    }
    final active = _jobs.where((j) => j.isActive).toList();
    final history = _jobs.where((j) => !j.isActive).toList();

    return AppScrollTab(
      slivers: [
        const SliverToBoxAdapter(
          child: PageHeader('My Moves', trailing: Icon(Icons.sailing_rounded)),
        ),
        if (_loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          if (active.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Active',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _JobCard(
                  job: active[i],
                  last: i == active.length - 1,
                  onTap: () => _open(active[i]),
                ),
                childCount: active.length,
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, active.isEmpty ? 0 : 20, 20, 8),
              child: Text('History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
            ),
          ),
          if (history.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No moves yet. Book your first move!')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _JobCard(
                  job: history[i],
                  last: i == history.length - 1,
                  onTap: () => _open(history[i]),
                ),
                childCount: history.length,
              ),
            ),
        ],
      ],
    );
  }

  void _open(MovingJob job) {
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
        .then((_) => _load());
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.last, required this.onTap});

  final MovingJob job;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.fromLTRB(20, last ? 4 : 4, 20, last ? 12 : 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAF0EE)),
          boxShadow: premiumShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Move #${job.id}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                StatusChip.statusFor(job),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${job.pickupAddress} → ${job.deliveryAddress}',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(job.vehicleLabel,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111418),
                    )),
                const Spacer(),
                if (job.quotedPrice > 0)
                  Text(formatPrice(job.quotedPrice),
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AuthPrompt extends StatelessWidget {
  const AuthPrompt({super.key, required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return AppScrollTab(
      slivers: [
        const SliverToBoxAdapter(child: PageHeader('My Moves')),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 48),
                  const SizedBox(height: 16),
                  const Text('Sign in to see your moves',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Your bookings and history appear here.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onSignIn,
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}