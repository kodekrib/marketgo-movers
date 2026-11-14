import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movers/services/maps_service.dart';
import 'package:movers/widgets/place_search_field.dart';
class FakeMaps extends MapsService {
 @override Future<MapConfig> fetchConfig() async => const MapConfig();
 @override Future<List<PlaceSuggestion>> searchPlaces(String query, {int limit=6}) async => [];
}
void main() {
 testWidgets('Editing selected address invalidates its coordinates', (tester) async {
  final controller=TextEditingController(text:'Selected home');
  const picked=PlaceSuggestion(placeId:'home',label:'Selected home',secondary:'',latitude:6.5,longitude:3.4);
  PlaceSuggestion? selection=picked;
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:PlaceSearchField(controller:controller, initialLocation:picked,showMap:false,service:FakeMaps(),onLocationChanged:(value)=>selection=value))));
  await tester.pumpAndSettle();
  expect(find.text('Use phone location'),findsOneWidget);
  await tester.enterText(find.byType(TextField),'Different address');
  await tester.pump(const Duration(seconds:1));
  expect(selection,isNull);
  await tester.pumpWidget(const SizedBox());
  controller.dispose();
 });
}
