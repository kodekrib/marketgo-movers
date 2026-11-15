import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/services/account_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('upgrade erases legacy saved card summaries', () async {
    SharedPreferences.setMockInitialValues({
      'movers.account.cards':
          '[{"brand":"Visa","last4":"1234","expiry":"01/30"}]'
    });
    await AccountStore.instance.ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('movers.account.cards'), isFalse);
  });
}
