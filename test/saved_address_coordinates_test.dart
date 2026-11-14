import 'package:flutter_test/flutter_test.dart';
import 'package:movers/services/account_store.dart';

void main() {
  test(
      'Saved address retains coordinates across persistence and default changes',
      () {
    const address = SavedAddress(
        id: 'a',
        label: 'Home',
        address: 'Lagos',
        latitude: 6.5,
        longitude: 3.4);
    final restored =
        SavedAddress.fromJson(address.toJson()).copyWith(isDefault: true);
    expect(restored.latitude, 6.5);
    expect(restored.longitude, 3.4);
    expect(restored.isDefault, true);
    expect(
        SavedAddress.fromJson({'id': 'legacy', 'address': 'Old address'})
            .latitude,
        isNull);
  });
}
