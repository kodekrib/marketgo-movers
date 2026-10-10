import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/moving.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/maps_service.dart';
import '../services/mover_service.dart';
import '../widgets/common.dart';
import '../widgets/place_search_field.dart';
import 'job_detail_screen.dart';

/// Booking form for a moving job: vehicle type, addresses, item details and
/// optional extra packers. Shows a live up-front fare estimate (Uber-style)
/// once a vehicle and both geocoded addresses are in place.
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
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _descriptionController = TextEditingController();

  PlaceSuggestion? _pickup;
  PlaceSuggestion? _delivery;

  List<MoverVehicleType> _vehicleTypes = const [];
  bool _loadingVehicles = false;
  String? _vehicleError;

  String? _vehicleType;
  int _itemCount = 1;
  int _extraPackers = 0;

  /// Live quote state (debounced so typing/stepping doesn't spam the API).
  Timer? _quoteDebounce;
  int _quoteSeq = 0;
  TripQuote? _quote;
  bool _quoting = false;
  String? _quoteError;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _vehicleType = widget.initialVehicleType;
    _loadVehicleTypes();
  }

  @override
  void dispose() {
    _quoteDebounce?.cancel();
    _pickupController.dispose();
    _deliveryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleTypes() async {
    setState(() {
      _loadingVehicles = true;
      _vehicleError = null;
    });
    try {
      final types = await widget.movers.vehicleTypes();
      if (!mounted) return;
      setState(() {
        _loadingVehicles = false;
        _vehicleTypes = types;
        if (_vehicleType == null && types.isNotEmpty) {
          _vehicleType = types.first.name;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingVehicles = false;
        _vehicleError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingVehicles = false;
        _vehicleError = 'Could not load vehicle types.';
      });
    }
    _maybeQuote();
  }

  /// Reschedules the fare estimate fetch after the user changes a selector.
  void _maybeQuote() {
    _quoteDebounce?.cancel();
    if (_quoteReady()) {
      _quoteDebounce =
          Timer(const Duration(milliseconds: 400), () => _fetchQuote());
    } else {
      setState(() {
        _quote = null;
        _quoting = false;
        _quoteError = null;
      });
    }
  }

  bool _quoteReady() {
    final token = widget.auth.accessToken;
    final pickup = _pickup;
    final delivery = _delivery;
    return token != null &&
        token.isNotEmpty &&
        _vehicleType != null &&
        pickup != null &&
        delivery != null &&
        (pickup.latitude != 0 || pickup.longitude != 0) &&
        (delivery.latitude != 0 || delivery.longitude != 0);
  }

  Future<void> _fetchQuote() async {
    final token = widget.auth.accessToken;
    final vehicle = _vehicleType;
    final pickup = _pickup;
    final delivery = _delivery;
    if (token == null ||
        vehicle == null ||
        pickup == null ||
        delivery == null) {
      return;
    }
    MoverVehicleType? selectedType;
    for (final t in _vehicleTypes) {
      if (t.name == vehicle) {
        selectedType = t;
        break;
      }
    }
    if (selectedType == null) return;

    final seq = ++_quoteSeq;
    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    try {
      final q = await widget.movers.quote(
        token,
        vehicleTypeId: selectedType.id,
        pickupLatitude: pickup.latitude,
        pickupLongitude: pickup.longitude,
        deliveryLatitude: delivery.latitude,
        deliveryLongitude: delivery.longitude,
        weightKg: _itemCount == 0 ? 0 : _itemCount * 10.0,
      );
      if (!mounted || seq != _quoteSeq) return;
      setState(() {
        _quote = q;
        _quoting = false;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _quoteSeq) return;
      setState(() {
        _quote = null;
        _quoting = false;
        _quoteError = e.message;
      });
    } catch (_) {
      if (!mounted || seq != _quoteSeq) return;
      setState(() {
        _quote = null;
        _quoting = false;
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final token = widget.auth.accessToken;
    if (_vehicleType == null ||
        _pickupController.text.trim().isEmpty ||
        _deliveryController.text.trim().isEmpty) {
      setState(() => _error = 'Select a vehicle and fill in both addresses.');
      return;
    }
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Sign in to book a move.');
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              if (_loadingVehicles)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
                )
              else if (_vehicleTypes.isEmpty && _vehicleError != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: MoversApp.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 18, color: Color(0xFF9AA1AA)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$_vehicleError',
                          style: const TextStyle(
                              fontSize: 12.5, color: Color(0xFF6B7280)),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadVehicleTypes,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ] else if (_vehicleTypes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No vehicles are available right now.',
                      style: TextStyle(color: Color(0xFF9AA1AA))),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _vehicleTypes.map((v) {
                    final selected = _vehicleType == v.name;
                    return InkWell(
                      onTap: () {
                        setState(() => _vehicleType = v.name);
                        _maybeQuote();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              selected ? MoversApp.brandOrange : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? MoversApp.brandOrange
                                : const Color(0xFFE2E5EA),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(vehicleIconForType(v.name),
                                size: 20,
                                color: selected
                                    ? Colors.white
                                    : MoversApp.brandOrange),
                            const SizedBox(width: 8),
                            Text(
                              v.label,
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
                onLocationChanged: (p) {
                  setState(() => _pickup = p);
                  _maybeQuote();
                },
              ),
              const SizedBox(height: 14),
              PlaceSearchField(
                controller: _deliveryController,
                labelText: 'Delivery address',
                hintText: 'Where should everything go?',
                prefixIcon: const Icon(Icons.location_on_outlined),
                height: 140,
                onLocationChanged: (p) {
                  setState(() => _delivery = p);
                  _maybeQuote();
                },
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
                      onChanged: (v) {
                        setState(() => _itemCount = v);
                        _maybeQuote();
                      },
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
                  border: Border.all(
                      color: MoversApp.brandOrange.withOpacity(0.35)),
                ),
                child: _buildEstimate(),
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

  /// Fare estimate panel: live quote when available, otherwise guidance text.
  Widget _buildEstimate() {
    final theme = Theme.of(context);
    final caption = TextStyle(
      fontSize: 12.5,
      color: MoversApp.brandOrangeDark,
      fontWeight: FontWeight.w500,
      height: 1.4,
    );
    if (_quoting) {
      return Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Estimating your fare…', style: caption),
          ),
        ],
      );
    }
    if (_quote != null && _quote!.fare > 0) {
      final quote = _quote!;
      final vehicle = quote.vehicleType;
      final route = StringBuffer(
          '~${quote.distanceKm.toStringAsFixed(1)} km · ~${quote.durationMin} min');
      if (vehicle != null && vehicle.label.isNotEmpty) {
        route.write(' · ${vehicle.label}');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sailing_rounded,
                  color: MoversApp.brandOrangeDark, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Estimated fare',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: MoversApp.brandOrangeDark)),
              ),
              Text(formatPrice(quote.fare),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: MoversApp.brandOrangeDark,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Text(route.toString(), style: caption),
          const SizedBox(height: 4),
          Text(
            'Estimate assumes ~10 kg per item (${_itemCount * 10} kg total) '
            'and uses the zone price rule. Final fare is confirmed when a '
            'mover accepts your move.',
            style: TextStyle(
              fontSize: 11.5,
              color: MoversApp.brandOrangeDark.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      );
    }
    if (_quoteError != null) {
      return Row(
        children: [
          Icon(Icons.error_outline, color: MoversApp.brandOrangeDark, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(_quoteError!, style: caption)),
        ],
      );
    }
    return Row(
      children: [
        Icon(Icons.sailing_rounded, color: MoversApp.brandOrangeDark, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'One packer is always included. Pick both addresses and a '
            'vehicle to see an estimated fare — no prepayment now.',
            style: caption,
          ),
        ),
      ],
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
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          if (helper != null)
            Text(helper!,
                style:
                    const TextStyle(fontSize: 10.5, color: Color(0xFF9AA1AA))),
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
