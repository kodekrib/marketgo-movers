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

/// Calls the authenticated customer moving-job endpoints.
class MoverService {
  MoverService({ApiClient? api}) : api = api ?? ApiClient();

  final ApiClient api;

  Map<String, String> _auth(String token) => {'Authorization': 'Bearer $token'};

  Future<MovingJob> createJob(String token, BookMoveRequest req) async {
    final data = await api.post(
      '/api/v1/customer/moving-jobs',
      headers: _auth(token),
      body: req.toJson(),
    );
    final job = data['job'];
    if (job is Map<String, dynamic>) return MovingJob.fromJson(job);
    throw const ApiException('Unexpected moving job payload');
  }

  Future<List<MovingJob>> jobs(String token) async {
    final data = await api.get(
      '/api/v1/customer/moving-jobs',
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
      '/api/v1/customer/moving-jobs/$id',
      headers: _auth(token),
    );
    final job = data['job'];
    if (job is Map<String, dynamic>) return MovingJob.fromJson(job);
    throw const ApiException('Unexpected moving job payload');
  }

  Future<void> cancel(String token, int id) async {
    await api.post(
      '/api/v1/customer/moving-jobs/$id/cancel',
      headers: _auth(token),
    );
  }
}

/// Demo records shown when an unauthenticated/demo session explores the app.
List<MovingJob> demoMovingJobs() {
  return [
    const MovingJob(
      id: 1001,
      customerId: 1,
      riderId: 1,
      vehicleType: 'pickup_truck',
      pickupAddress: '12 Admiralty Way, Lekki Phase 1',
      deliveryAddress: '3 Bourdillon Road, Ikoyi',
      description: 'Sofa, two mattresses and a wardrobe',
      itemCount: 8,
      extraPackers: 1,
      packerPrice: 2000,
      totalPackerFee: 2000,
      quotedPrice: 45000,
      platformFee: 3760,
      totalAmount: 50760,
      status: MovingJobStatus.inTransit,
      riderName: 'Tunde Adebayo',
      vehicleName: 'Toyota Hilux',
    ),
    MovingJob(
      id: 1000,
      customerId: 1,
      vehicleType: 'van',
      pickupAddress: '8 Adeola Odeku, VI',
      deliveryAddress: '21 Surulere Industrial Estate',
      description: 'Office desks and chairs',
      itemCount: 14,
      extraPackers: 0,
      status: MovingJobStatus.delivered,
      quotedPrice: 38000,
      platformFee: 3040,
      totalAmount: 41040,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];
}