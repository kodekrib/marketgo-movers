import 'dart:async';
import '../widgets/trip_route_map.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../models/moving.dart';
import '../services/auth_service.dart';
import '../services/mover_service.dart';
import '../services/payment_service.dart';
import '../widgets/common.dart';
import '../widgets/movers_app_bar.dart';
import 'payment_webview_screen.dart';

/// Full detail view of a moving job with a status timeline and fee breakdown.
class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({
    super.key,
    required this.job,
    this.auth,
    this.movers,
    this.readOnly = false,
    this.onCancel,
  });

  final MovingJob job;
  final AuthModel? auth;
  final MoverService? movers;

  /// When true, payments and cancellation are hidden (plain read-only view).
  final bool readOnly;
  final VoidCallback? onCancel;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late MovingJob _job;
  bool _cancelling = false;
  List<MovingBid> _bids = [];
  Timer? _refresh;
  bool _refreshing = false, _selecting = false;
  String _sort = 'price';
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    if (!widget.readOnly) {
      _refreshJob();
      _refresh =
          Timer.periodic(const Duration(seconds: 10), (_) => _refreshJob());
    }
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _refreshJob() async {
    final token = widget.auth?.accessToken, service = widget.movers;
    if (token == null || service == null || _refreshing) return;
    _refreshing = true;
    try {
      final job = await service.job(token, _job.id);
      final bids = job.status == MovingJobStatus.pending
          ? await service.bids(token, _job.id)
          : <MovingBid>[];
      if (mounted) {
        setState(() {
          _job = job;
          _bids = bids;
        });
      }
    } catch (_) {/* Keep visible state and retry. */} finally {
      _refreshing = false;
    }
  }

  Future<void> _select(MovingBid bid) async {
    final token = widget.auth?.accessToken, service = widget.movers;
    if (token == null || service == null || _selecting) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('Select ${bid.riderName}?'),
                content: Text(
                    'Agreed total: ${MoversApp.currencySymbol}${bid.total.toStringAsFixed(2)}. This includes the rider, extra packers and platform fee.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Back')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Select rider'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _selecting = true);
    try {
      await service.selectBid(token, _job.id, bid);
      await _refreshJob();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'This bid changed or the rider is unavailable. Refresh and choose again.')));
      }
      await _refreshJob();
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Widget _bidList() {
    final bids = [..._bids]..sort((a, b) => _sort == 'distance'
        ? (a.distanceKM ?? double.infinity)
            .compareTo(b.distanceKM ?? double.infinity)
        : a.total.compareTo(b.total));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const Expanded(
            child: Text('Rider bids',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        DropdownButton<String>(
            value: _sort,
            items: const [
              DropdownMenuItem(value: 'price', child: Text('Cheapest')),
              DropdownMenuItem(value: 'distance', child: Text('Closest'))
            ],
            onChanged: (value) => setState(() => _sort = value ?? 'price'))
      ]),
      if (bids.isEmpty)
        const Text(
            'Waiting for matching riders to send their prices. Bids refresh automatically.'),
      for (final bid in bids)
        Card(
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(bid.riderName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(bid.distanceKM == null
                          ? 'Current distance unavailable'
                          : '${bid.distanceKM!.toStringAsFixed(1)} km to pickup'),
                      Text(
                          'Rider: ${MoversApp.currencySymbol}${bid.price.toStringAsFixed(2)} · Packers: ${MoversApp.currencySymbol}${bid.packerFee.toStringAsFixed(2)}'),
                      Text(
                          'Platform fee: ${MoversApp.currencySymbol}${bid.platformFee.toStringAsFixed(2)}'),
                      Text(
                          'Total: ${MoversApp.currencySymbol}${bid.total.toStringAsFixed(2)}'),
                      ElevatedButton(
                          onPressed: _selecting ? null : () => _select(bid),
                          child: const Text('Select this rider'))
                    ]))),
    ]);
  }

  Future<void> _pay() async {
    final token = widget.auth?.accessToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to pay for this move.')),
      );
      return;
    }

    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final paymentService = PaymentService(api: widget.movers?.api);
      final paymentData = await paymentService.initJobPayment(
        token,
        jobId: _job.id,
      );
      if (!mounted) return;

      final gateway = (paymentData['gateway'] ?? 'paystack').toString();
      final reference = (paymentData['reference'] ?? '').toString();
      final paymentUrl = gateway == 'paystack'
          ? (paymentData['authorization_url'] ?? '').toString()
          : (paymentData['payment_link'] ?? '').toString();

      if (paymentUrl.isEmpty) {
        setState(() {
          _paying = false;
          _error = 'No payment link returned. Please try again.';
        });
        return;
      }

      final paid = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(
            paymentUrl: paymentUrl,
            reference: reference,
            gateway: gateway,
          ),
        ),
      );

      if (!mounted) return;

      if (paid == true) {
        try {
          await paymentService.verifyPayment(token, reference: reference);
        } catch (_) {
          // Verification is best-effort; the webhook will also confirm.
        }
        if (!mounted) return;
        setState(() {
          _job = _copyWithPaymentStatus('paid');
          _paying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _paying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment was not completed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _paying = false;
          _error = '$e';
        });
      }
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this move?'),
        content: Text('Move #${_job.id} will be cancelled. The mover may '
            'already be heading to the pickup.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel move',
                style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
    if (confirmed != true || widget.readOnly) return;

    final token = widget.auth?.accessToken;
    if (token == null || token.isEmpty) return;
    setState(() {
      _cancelling = true;
      _error = null;
    });
    try {
      await widget.movers?.cancel(token, _job.id);
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _job = _copyWithStatus(MovingJobStatus.cancelled);
      });
      widget.onCancel?.call();
    } catch (e) {
      if (mounted) {
        setState(() {
          _cancelling = false;
          _error = '$e';
        });
      }
    }
  }

  MovingJob _copyWithStatus(MovingJobStatus status) {
    // Rebuild model copy with a new status via fromJson is heavy; this narrow
    // helper recreates the record through the same fields.
    return MovingJob(
      id: _job.id,
      customerId: _job.customerId,
      riderId: _job.riderId,
      vehicleType: _job.vehicleType,
      pickupAddress: _job.pickupAddress,
      pickupLat: _job.pickupLat,
      pickupLng: _job.pickupLng,
      deliveryAddress: _job.deliveryAddress,
      deliveryLat: _job.deliveryLat,
      deliveryLng: _job.deliveryLng,
      description: _job.description,
      itemCount: _job.itemCount,
      extraPackers: _job.extraPackers,
      packerPrice: _job.packerPrice,
      totalPackerFee: _job.totalPackerFee,
      quotedPrice: _job.quotedPrice,
      platformFee: _job.platformFee,
      totalAmount: _job.totalAmount,
      status: status,
      paymentStatus: _job.paymentStatus,
      cancelReason: _job.cancelReason,
      riderName: _job.riderName,
      riderPhone: _job.riderPhone,
      vehicleName: _job.vehicleName,
      createdAt: _job.createdAt,
    );
  }

  MovingJob _copyWithPaymentStatus(String paymentStatus) {
    return MovingJob(
      id: _job.id,
      customerId: _job.customerId,
      riderId: _job.riderId,
      vehicleType: _job.vehicleType,
      pickupAddress: _job.pickupAddress,
      pickupLat: _job.pickupLat,
      pickupLng: _job.pickupLng,
      deliveryAddress: _job.deliveryAddress,
      deliveryLat: _job.deliveryLat,
      deliveryLng: _job.deliveryLng,
      description: _job.description,
      itemCount: _job.itemCount,
      extraPackers: _job.extraPackers,
      packerPrice: _job.packerPrice,
      totalPackerFee: _job.totalPackerFee,
      quotedPrice: _job.quotedPrice,
      platformFee: _job.platformFee,
      totalAmount: _job.totalAmount,
      status: _job.status,
      paymentStatus: paymentStatus,
      cancelReason: _job.cancelReason,
      riderName: _job.riderName,
      riderPhone: _job.riderPhone,
      vehicleName: _job.vehicleName,
      createdAt: _job.createdAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoversAppBar(title: 'Move #${_job.id}'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TripRouteMap(
                from: _job.pickupAddress,
                to: _job.deliveryAddress,
                fromLat: _job.pickupLat,
                fromLng: _job.pickupLng,
                toLat: _job.deliveryLat,
                toLng: _job.deliveryLng),
            Row(
              children: [
                Expanded(
                  child: Text(_job.vehicleLabel,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                StatusChip.statusFor(_job),
              ],
            ),
            if (_job.riderName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Mover: ${_job.riderName}',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 20),
            if (!widget.readOnly && _job.status == MovingJobStatus.pending)
              _bidList(),
            _Timeline(status: _job.status),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _AddressCard(
                    icon: Icons.trip_origin_rounded,
                    label: 'Pickup',
                    address: _job.pickupAddress,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AddressCard(
                    icon: Icons.location_on_outlined,
                    label: 'Delivery',
                    address: _job.deliveryAddress,
                  ),
                ),
              ],
            ),
            if (_job.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              _InfoRow(label: 'Details', value: _job.description),
            ],
            const SizedBox(height: 8),
            _InfoRow(label: 'Items', value: '${_job.itemCount}'),
            _InfoRow(
              label: 'Extra packers',
              value:
                  '${_job.extraPackers}${_job.extraPackers > 0 ? ' × ${formatPrice(_job.packerPrice)}' : ''}',
            ),
            if (_job.quotedPrice > 0) ...[
              const SizedBox(height: 16),
              _FareBreakdown(job: _job),
            ],
            if (_job.isPaid && _job.quotedPrice > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F6EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded,
                        color: Color(0xFF15803D), size: 20),
                    SizedBox(width: 10),
                    Text('Payment received',
                        style: TextStyle(
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5)),
                  ],
                ),
              ),
            ],
            if (_job.canPay && widget.auth != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _paying ? null : _pay,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF166534),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _paying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text('Pay ${formatPrice(_job.totalAmount)}',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
            if (_job.cancelReason.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Cancelled: ${_job.cancelReason}',
                  style: const TextStyle(color: Color(0xFFDC2626))),
            ],
            if (_job.isActive && widget.auth != null && !widget.readOnly) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _cancelling ? null : _cancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                  ),
                  child: _cancelling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Text('Cancel this move'),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style:
                      const TextStyle(color: Color(0xFFB3261E), fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});

  final MovingJobStatus status;

  static const _steps = [
    (MovingJobStatus.pending, 'Requested'),
    (MovingJobStatus.accepted, 'Accepted'),
    (MovingJobStatus.enRoute, 'On the way'),
    (MovingJobStatus.arrived, 'Arrived'),
    (MovingJobStatus.loading, 'Loading'),
    (MovingJobStatus.inTransit, 'In transit'),
    (MovingJobStatus.delivered, 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    if (status == MovingJobStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Text('This move was cancelled.',
                style: TextStyle(
                    color: Color(0xFFB91C1C), fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    final current = movingJobStep(status);
    return Column(
      children: List.generate(_steps.length, (index) {
        final (_, label) = _steps[index];
        final done = index <= current;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor:
                      done ? MoversApp.brandOrange : const Color(0xFFE2E5EA),
                  child: done
                      ? Icon(
                          index == current
                              ? Icons.radio_button_checked
                              : Icons.check,
                          size: 16,
                          color: Colors.white)
                      : const Icon(Icons.radio_button_unchecked,
                          size: 16, color: Color(0xFFC9CDD4)),
                ),
                if (index < _steps.length - 1)
                  Container(
                    width: 2,
                    height: 22,
                    color: index < current
                        ? MoversApp.brandOrange
                        : const Color(0xFFE2E5EA),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: EdgeInsets.only(
                top: 6,
                bottom: index < _steps.length - 1 ? 4 : 0,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight:
                      index == current ? FontWeight.w800 : FontWeight.w600,
                  color: done ? MoversApp.ink : const Color(0xFF9AA1AA),
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.icon,
    required this.label,
    required this.address,
  });

  final IconData icon;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAF0EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: MoversApp.brandOrange),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9AA1AA))),
          const SizedBox(height: 2),
          Text(address,
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _FareBreakdown extends StatelessWidget {
  const _FareBreakdown({required this.job});

  final MovingJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _line('Mover quote', formatPrice(job.quotedPrice)),
          if (job.totalPackerFee > 0)
            _line('Packers (${job.extraPackers})',
                formatPrice(job.totalPackerFee)),
          _line('Platform fee', formatPrice(job.platformFee)),
          const Divider(height: 18),
          Row(
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              Text(formatPrice(job.totalAmount),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF5B616A))),
          const Spacer(),
          Text(amount,
              style:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
