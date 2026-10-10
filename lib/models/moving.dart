// Domain models for the Movers customer app.
// Mirrors backend models/mover.go.
import 'package:flutter/material.dart';

/// Moving job statuses in lifecycle order.
enum MovingJobStatus {
  pending,
  accepted,
  enRoute,
  arrived,
  loading,
  inTransit,
  delivered,
  cancelled,
}

MovingJobStatus movingJobStatusFromName(String name) {
  switch (name) {
    case 'accepted':
      return MovingJobStatus.accepted;
    case 'en_route':
      return MovingJobStatus.enRoute;
    case 'arrived':
      return MovingJobStatus.arrived;
    case 'loading':
      return MovingJobStatus.loading;
    case 'in_transit':
      return MovingJobStatus.inTransit;
    case 'delivered':
      return MovingJobStatus.delivered;
    case 'cancelled':
      return MovingJobStatus.cancelled;
    default:
      return MovingJobStatus.pending;
  }
}

String movingJobStatusLabel(MovingJobStatus status) {
  switch (status) {
    case MovingJobStatus.pending:
      return 'Pending';
    case MovingJobStatus.accepted:
      return 'Accepted';
    case MovingJobStatus.enRoute:
      return 'On the way';
    case MovingJobStatus.arrived:
      return 'Arrived';
    case MovingJobStatus.loading:
      return 'Loading';
    case MovingJobStatus.inTransit:
      return 'In transit';
    case MovingJobStatus.delivered:
      return 'Delivered';
    case MovingJobStatus.cancelled:
      return 'Cancelled';
  }
}

const Map<MovingJobStatus, int> _statusStep = {
  MovingJobStatus.pending: 0,
  MovingJobStatus.accepted: 1,
  MovingJobStatus.enRoute: 2,
  MovingJobStatus.arrived: 3,
  MovingJobStatus.loading: 4,
  MovingJobStatus.inTransit: 5,
  MovingJobStatus.delivered: 6,
  MovingJobStatus.cancelled: 6,
};

/// Numeric progress 0–6 used by the timeline stepper.
int movingJobStep(MovingJobStatus s) => _statusStep[s] ?? 0;

class MovingJob {
  const MovingJob({
    required this.id,
    required this.customerId,
    this.riderId,
    required this.vehicleType,
    required this.pickupAddress,
    this.pickupLat = 0,
    this.pickupLng = 0,
    required this.deliveryAddress,
    this.deliveryLat = 0,
    this.deliveryLng = 0,
    this.description = '',
    this.itemCount = 0,
    this.extraPackers = 0,
    this.packerPrice = 0,
    this.totalPackerFee = 0,
    this.quotedPrice = 0,
    this.platformFee = 0,
    this.totalAmount = 0,
    this.status = MovingJobStatus.pending,
    this.paymentStatus = 'pending',
    this.cancelReason = '',
    this.riderName = '',
    this.riderPhone = '',
    this.vehicleName = '',
    this.createdAt,
  });

  final int id;
  final int customerId;
  final int? riderId;
  final String vehicleType;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String deliveryAddress;
  final double deliveryLat;
  final double deliveryLng;
  final String description;
  final int itemCount;
  final int extraPackers;
  final double packerPrice;
  final double totalPackerFee;
  final double quotedPrice;
  final double platformFee;
  final double totalAmount;
  final MovingJobStatus status;
  final String paymentStatus;
  final String cancelReason;
  final String riderName;
  final String riderPhone;
  final String vehicleName;
  final DateTime? createdAt;

  /// Has the rider confirmed the job?
  bool get isPending => status == MovingJobStatus.pending;

  /// Returns true for statuses that indicate an active (non-terminal) job.
  bool get isActive =>
      status != MovingJobStatus.delivered &&
      status != MovingJobStatus.cancelled;

  /// Has the quoted job been paid by the customer?
  bool get isPaid => paymentStatus == 'paid';

  /// True for active, quoted jobs that have not been paid yet.
  bool get canPay =>
      isActive &&
      !isPending &&
      !isPaid &&
      totalAmount > 0 &&
      status != MovingJobStatus.delivered;

  String get vehicleLabel {
    switch (vehicleType) {
      case 'pickup_truck':
        return 'Pickup Truck';
      case 'van':
        return 'Van';
      case 'mini_truck':
        return 'Mini Truck';
      case 'lorry':
        return 'Lorry';
      default:
        return vehicleType;
    }
  }

  factory MovingJob.fromJson(Map<String, dynamic> j) {
    final riderIdRaw = j['rider_id'];
    final riderId = riderIdRaw != null ? (riderIdRaw as num).toInt() : null;
    return MovingJob(
      id: (j['id'] as num?)?.toInt() ?? 0,
      customerId: (j['customer_id'] as num?)?.toInt() ?? 0,
      riderId: riderId,
      vehicleType: j['vehicle_type'] as String? ?? '',
      pickupAddress: j['pickup_address'] as String? ?? '',
      pickupLat: (j['pickup_latitude'] as num?)?.toDouble() ?? 0,
      pickupLng: (j['pickup_longitude'] as num?)?.toDouble() ?? 0,
      deliveryAddress: j['delivery_address'] as String? ?? '',
      deliveryLat: (j['delivery_latitude'] as num?)?.toDouble() ?? 0,
      deliveryLng: (j['delivery_longitude'] as num?)?.toDouble() ?? 0,
      description: j['description'] as String? ?? '',
      itemCount: (j['item_count'] as num?)?.toInt() ?? 0,
      extraPackers: (j['extra_pickers'] as num?)?.toInt() ?? 0,
      packerPrice: (j['packer_price'] as num?)?.toDouble() ?? 0,
      totalPackerFee: (j['total_packer_fee'] as num?)?.toDouble() ?? 0,
      quotedPrice: (j['quoted_price'] as num?)?.toDouble() ?? 0,
      platformFee: (j['platform_fee'] as num?)?.toDouble() ?? 0,
      totalAmount: (j['total_amount'] as num?)?.toDouble() ?? 0,
      status: movingJobStatusFromName(j['status'] as String? ?? 'pending'),
      paymentStatus: j['payment_status'] as String? ?? 'pending',
      cancelReason: j['cancel_reason'] as String? ?? '',
      riderName: j['rider_name'] as String? ?? '',
      riderPhone: j['rider_phone'] as String? ?? '',
      vehicleName: j['vehicle_name'] as String? ?? '',
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'] as String)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Vehicle types + up-front quotes
// ---------------------------------------------------------------------------

/// A bookable vehicle class served by `/api/v1/vehicle-types` (also exposed on
/// the authenticated mover/rider routes). Mirrors backend models.VehicleType.
class MoverVehicleType {
  const MoverVehicleType({
    required this.id,
    required this.name,
    required this.label,
    this.icon = '',
    this.isActive = true,
  });

  final int id;
  final String name;
  final String label;
  final String icon;
  final bool isActive;

  factory MoverVehicleType.fromJson(Map<String, dynamic> j) {
    return MoverVehicleType(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: j['name'] as String? ?? '',
      label: j['label'] as String? ?? '',
      icon: j['icon'] as String? ?? '',
      isActive: j['is_active'] != false,
    );
  }
}

/// Material icon matched to a vehicle type name (admin/riders use the same
/// naming, e.g. `pickup_truck`, `van`, `mini_truck`, `lorry`).
IconData vehicleIconForType(String name) {
  switch (name) {
    case 'pickup_truck':
      return Icons.local_shipping_rounded;
    case 'van':
      return Icons.directions_car_rounded;
    case 'mini_truck':
    case 'truck':
      return Icons.fire_truck_rounded;
    case 'lorry':
      return Icons.airport_shuttle_rounded;
    default:
      return Icons.local_shipping_rounded;
  }
}

/// An item inside the up-front fare breakdown.
class QuoteVehicle {
  const QuoteVehicle({required this.id, required this.name, this.label = ''});

  final int id;
  final String name;
  final String label;

  factory QuoteVehicle.fromJson(Map<String, dynamic> j) => QuoteVehicle(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        label: j['label'] as String? ?? '',
      );
}

/// Up-front fare returned by `/api/v1/mover/quote` (zone + vehicle aware).
class TripQuote {
  const TripQuote({
    required this.fare,
    this.currency = 'NGN',
    this.distanceKm = 0,
    this.durationMin = 0,
    this.weightKg = 0,
    this.vehicleType,
  });

  final double fare;
  final String currency;
  final double distanceKm;
  final int durationMin;
  final double weightKg;
  final QuoteVehicle? vehicleType;

  factory TripQuote.fromJson(Map<String, dynamic> j) {
    final vehicle = j['vehicle_type'];
    return TripQuote(
      fare: (j['fare'] as num?)?.toDouble() ?? 0,
      currency: j['currency'] as String? ?? 'NGN',
      distanceKm: (j['distance_km'] as num?)?.toDouble() ?? 0,
      durationMin: (j['duration_min'] as num?)?.toInt() ?? 0,
      weightKg: (j['weight_kg'] as num?)?.toDouble() ?? 0,
      vehicleType: vehicle is Map<String, dynamic>
          ? QuoteVehicle.fromJson(vehicle)
          : null,
    );
  }
}
