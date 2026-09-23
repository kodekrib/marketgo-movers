import 'package:flutter/material.dart';

import '../app.dart';
import '../services/auth_service.dart';
import '../services/maps_service.dart';
import '../services/mover_service.dart';
import '../widgets/common.dart';
import '../widgets/place_search_field.dart';
import 'job_detail_screen.dart';

/// Booking form for a moving job: vehicle type, addresses, item details and
/// optional extra packers.
class BookMoveScreen extends StatefulWidget {
  const BookMoveScreen({
    super.key,
    required this.auth,
    required this.movers,
    this.initialVehicleType,
  });

  final AuthModel auth;
  final MoverService movers;

  /// Pre-selects a vehicle (e.g. tapped from the home chip rail).
  final String? initialVehicleType;

  @override
  State<BookMoveScreen> createState() => _BookMoveScreenState();
}

class _BookMoveScreenState extends State<BookMoveScreen> {
  static const _vehicleTypes = [
    ('pickup_truck', 'Pickup Truck', Icons.local_shipping_rounded),
    ('van', 'Van', Icons.directions_car_rounded),
    ('mini_truck', 'Mini Truck', Icons.fire_truck_rounded),
    ('lorry', 'Lorry', Icons.airport_shuttle_rounded),
  ];

  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _descriptionController = TextEditingController();

  PlaceSuggestion? _pickup;
  PlaceSuggestion? _delivery;

  String? _vehicleType;
  int _itemCount = 1;
  int _extraPackers = 0;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _vehicleType = widget.initialVehicleType;
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _deliveryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final token = widget.auth.accessToken ?? '';
    if (_vehicleType == null || _pickupController.text.trim().isEmpty || _deliveryController.text.trim().isEmpty) {
      setState(() => _error = 'Select a vehicle and fill in both addresses.');
      return;
    }
    if (token == 'demo.access') {
      setState(() {
        _submitting = true;
        _error = null;
      });
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      final job = demoMovingJobs().first;
      setState(() => _submitting = false);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => JobDetailScreen(
            job: job,
            readOnly: true,
            onCancel: () {},
          ),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final job = await widget.movers.createJob(
        token,
        BookMoveRequest(
          vehicleType: _vehicleType!,
          pickupAddress: _pickupController.text.trim(),
          deliveryAddress: _deliveryController.text.trim(),
          description: _descriptionController.text.trim(),
          itemCount: _itemCount,
          extraPackers: _extraPackers,
          pickupLatitude: _pickup?.latitude,
          pickupLongitude: _pickup?.longitude,
          deliveryLatitude: _delivery?.latitude,
          deliveryLongitude: _delivery?.longitude,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => JobDetailScreen(
            job: job,
            auth: widget.auth,
            movers: widget.movers,
            readOnly: false,
            onCancel: () {},
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book a move')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFB3261E), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFF8F1D16),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _sectionHeader('Vehicle type'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _vehicleTypes.map((v) {
                  final selected = _vehicleType == v.$1;
                  return InkWell(
                    onTap: () => setState(() => _vehicleType = v.$1),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? MoversApp.brandOrange : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? MoversApp.brandOrange : const Color(0xFFE2E5EA),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(v.$3,
                              size: 20,
                              color: selected ? Colors.white : MoversApp.brandOrange),
                          const SizedBox(width: 8),
                          Text(
                            v.$2,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: selected ? Colors.white : MoversApp.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _sectionHeader('Move details'),
              const SizedBox(height: 10),
              PlaceSearchField(
                controller: _pickupController,
                labelText: 'Pickup address',
                hintText: 'Where are the items now?',
                prefixIcon: const Icon(Icons.trip_origin_rounded),
                height: 140,
                onLocationChanged: (p) => setState(() => _pickup = p),
              ),
              const SizedBox(height: 14),
              PlaceSearchField(
                controller: _deliveryController,
                labelText: 'Delivery address',
                hintText: 'Where should everything go?',
                prefixIcon: const Icon(Icons.location_on_outlined),
                height: 140,
                onLocationChanged: (p) => setState(() => _delivery = p),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descriptionController,
                textInputAction: TextInputAction.newline,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g. Sofa, fridge, 3 cartons',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 24),
              _sectionHeader('Items & packers'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StepperField(
                      label: 'Items count',
                      value: _itemCount,
                      min: 1,
                      max: 100,
                      onChanged: (v) => setState(() => _itemCount = v),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StepperField(
                      label: 'Extra packers',
                      value: _extraPackers,
                      min: 0,
                      max: 20,
                      helper: '1 packer included',
                      onChanged: (v) => setState(() => _extraPackers = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MoversApp.brandOrangeLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MoversApp.brandOrange.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sailing_rounded, color: MoversApp.brandOrangeDark),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'One packer is always included. A mover rider will quote '
                        'your move once they accept it — no prepayment now.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: MoversApp.brandOrangeDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Request a mover'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: MoversApp.brandOrangeDark,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E5EA)),
        boxShadow: tileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          if (helper != null)
            Text(helper!,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF9AA1AA))),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepBtn(
                icon: Icons.remove_rounded,
                onTap: value > min ? () => onChanged(value - 1) : null,
              ),
              Text('$value',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              _StepBtn(
                icon: Icons.add_rounded,
                onTap: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: MoversApp.brandOrange.withOpacity(onTap == null ? 0.12 : 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 19,
            color: onTap == null
                ? const Color(0xFFC9CDD4)
                : MoversApp.brandOrangeDark),
      ),
    );
  }
}