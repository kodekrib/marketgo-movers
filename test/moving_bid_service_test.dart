import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:movers/services/api_client.dart';
import 'package:movers/services/mover_service.dart';

void main() {
  test('Customer selects a moving bid using the displayed total', () async {
    Map<String, dynamic>? submitted;
    final client = MockClient((req) async {
      expect(req.headers['Authorization'], 'Bearer token');
      if (req.method == 'GET')
        return http.Response(
            jsonEncode({
              'bids': [
                {
                  'id': 5,
                  'rider_name': 'Ada',
                  'price': 100.25,
                  'total_packer_fee': 21,
                  'platform_fee': 9.7,
                  'total_amount': 130.95,
                  'distance_km': 2.5
                }
              ]
            }),
            200);
      expect(req.url.path, '/api/v1/mover/moving-jobs/7/select-bid');
      submitted = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response('{}', 200);
    });
    final service = MoverService(
        api: ApiClient(baseUrl: 'http://localhost', httpClient: client));
    final bids = await service.bids('token', 7);
    expect(bids.single.total, 130.95);
    expect(bids.single.distanceKM, 2.5);
    await service.selectBid('token', 7, bids.single);
    expect(submitted, {'bid_id': 5, 'total_amount': 130.95});
  });
}
