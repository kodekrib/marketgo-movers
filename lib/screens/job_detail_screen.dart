import 'package:flutter/material.dart';

import '../app.dart';
import '../models/moving.dart';
import '../services/auth_service.dart';
import '../services/mover_service.dart';
import '../services/payment_service.dart';
import '../widgets/common.dart';
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

  /// When true, the screen shows static demo data (no backend calls).
  final bool readOnly;
  final VoidCallback? onCancel;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late MovingJob _job;
  bool _cancelling = false;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
  }

  Future<void> _pay() async {
    final token = widget.auth?.accessToken ?? '';
    // Demo mode — simulate a successful payment without hitting the network.
    if (token.isEmpty || token == 'demo.access') {
      setState(() => _job = _copyWithPaymentStatus('paid'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful (demo).')),
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

    final token = widget.auth?.accessToken ?? '';
    if (token == 'demo.access') {
      setState(() => _cancelling = false);
      return;
    }
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
      appBar: AppBar(title: Text('Move #${_job.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              value: '${_job.extraPackers}${_job.extraPackers > 0 ? ' × ${formatPrice(_job.packerPrice)}' : ''}',
            ),
            if (_job.quotedPrice > 0) ...[
              const SizedBox(height: 16),
              _FareBreakdown(job: _job),
            ],
            if (_job.isPaid && _job.quotedPrice > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F6EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF15803D), size: 20),
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
                  style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13)),
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
                  backgroundColor: done
                      ? MoversApp.brandOrange
                      : const Color(0xFFE2E5EA),
                  child: done
                      ? Icon(index == current
                          ? Icons.radio_button_checked
                          : Icons.check,
                          size: 16, color: Colors.white)
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
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600)),
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
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280))),
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
            _line('Packers (${job.extraPackers})', formatPrice(job.totalPackerFee)),
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
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}