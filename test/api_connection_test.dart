import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:movers/services/api_client.dart';

void main() {
  test('Connection failures reach the UI as an ApiException', () async {
    final api = ApiClient(baseUrl:'http://localhost.invalid', httpClient:MockClient((_) async { throw http.ClientException('network unavailable'); }));
    await expectLater(api.post('/api/v1/auth/login',body:{'email':'test@example.invalid','password':'test'}), throwsA(isA<ApiException>()));
  });
}
