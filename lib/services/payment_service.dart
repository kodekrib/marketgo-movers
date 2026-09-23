import 'api_client.dart';

/// Calls the authenticated customer payment endpoints for moving jobs.
class PaymentService {
  PaymentService({ApiClient? api}) : api = api ?? ApiClient();
  final ApiClient api;

  Map<String, String> _auth(String token) => {'Authorization': 'Bearer $token'};

  /// Initialize a payment for a quoted moving job. The amount is decided by
  /// the server (job.TotalAmount), never by the client.
  Future<Map<String, dynamic>> initJobPayment(
    String token, {
    required int jobId,
  }) async {
    final data = await api.post(
      '/api/v1/customer/moving-jobs/$jobId/pay',
      headers: _auth(token),
      body: const <String, dynamic>{},
    );
    return data;
  }

  /// Verify a payment reference with the backend.
  Future<Map<String, dynamic>> verifyPayment(
    String token, {
    required String reference,
  }) async {
    final data = await api.post(
      '/api/v1/customer/payments/verify',
      headers: _auth(token),
      body: {'reference': reference},
    );
    return data;
  }
}