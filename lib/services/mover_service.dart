import '../models/moving.dart';
import 'api_client.dart';

/// Payload for booking a moving job (matches CreateMovingJobRequest).
class BookMoveRequest {
  const BookMoveRequest({
    required this.vehicleType,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.description = '',
    this.itemCount = 0,
    this.extraPackers = 0,
    this.pickupLatitude,
    this.pickupLongitude,
    this.deliveryLatitude,
    this.deliveryLongitude,
  });

  final String vehicleType;
  final String pickupAddress;
  final String deliveryAddress;
  final String description;
  final int itemCount;
  final int extraPackers;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? deliveryLatitude;
  final double? deliveryLongitude;

  Map<String, dynamic> toJson() => {
        'vehicle_type': vehicleType,
        'pickup_address': pickupAddress,
        'delivery_address': deliveryAddress,
        'description': description,
        'item_count': itemCount,
        'extra_pickers': extraPackers,
        if (pickupLatitude != null && pickupLatitude != 0)
          'pickup_latitude': pickupLatitude,
        if (pickupLongitude != null && pickupLongitude != 0)
          'pickup_longitude': pickupLongitude,
        if (deliveryLatitude != null && deliveryLatitude != 0)
          'delivery_latitude': deliveryLatitude,
        if (deliveryLongitude != null && deliveryLongitude != 0)
          'delivery_longitude': deliveryLongitude,
      };
}

/// Calls the authenticated mover (> /api/v1/mover) moving-job + pricing
/// endpoints and the public vehicle-type catalog.
class MoverService {
  MoverService({ApiClient? api}) : api = api ?? ApiClient();

  final ApiClient api;

  Map<String, String> _auth(String token) => {'Authorization': 'Bearer $token'};

  /// Loads the active public vehicle catalog (`GET /api/v1/vehicle-types`).
  Future<List<MoverVehicleType>> vehicleTypes() async {
    final data = await api.get('/api/v1/vehicle-types');
    final list = data['vehicle_types'];
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(MoverVehicleType.fromJson)
          .where((v) => v.isActive)
          .toList();
    }
    return const [];
  }

  /// Up-front fare estimate for a route + vehicle (`POST /api/v1/mover/quote`).
  Future<TripQuote> quote(
    String token, {
    required int vehicleTypeId,
    required double pickupLatitude,
    required double pickupLongitude,
    required double deliveryLatitude,
    required double deliveryLongitude,
    required double weightKg,
  }) async {
    final data = await api.post(
      '/api/v1/mover/quote',
      headers: _auth(token),
      body: <String, dynamic>{
        'vehicle_type_id': vehicleTypeId,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'delivery_latitude': deliveryLatitude,
        'delivery_longitude': deliveryLongitude,
        'weight_kg': weightKg,
      },
    );
    final quote = data['quote'];
    if (quote is Map<String, dynamic>) return TripQuote.fromJson(quote);
    throw const ApiException('Unexpected quote payload');
  }

  Future<MovingJob> createJob(String token, BookMoveRequest req) async {
    final data = await api.post(
      '/api/v1/mover/moving-jobs',
      headers: _auth(token),
      body: req.toJson(),
    );
    final job = data['job'];
    if (job is Map<String, dynamic>) return MovingJob.fromJson(job);
    throw const ApiException('Unexpected moving job payload');
  }

  Future<List<MovingJob>> jobs(String token) async {
    final data = await api.get(
      '/api/v1/mover/moving-jobs',
      headers: _auth(token),
    );
    final list = data['jobs'];
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(MovingJob.fromJson)
          .toList();
    }
    return const [];
  }

  Future<MovingJob> job(String token, int id) async {
    final data = await api.get(
      '/api/v1/mover/moving-jobs/$id',
      headers: _auth(token),
    );
    final job = data['job'];
    if (job is Map<String, dynamic>) return MovingJob.fromJson(job);
    throw const ApiException('Unexpected moving job payload');
  }

  Future<void> cancel(String token, int id) async {
    await api.post(
      '/api/v1/mover/moving-jobs/$id/cancel',
      headers: _auth(token),
    );
  }
}
