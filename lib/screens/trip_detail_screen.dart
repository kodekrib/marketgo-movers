import 'package:flutter/material.dart';
import '../widgets/trip_route_map.dart';

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen(
      {super.key,
      required this.title,
      required this.from,
      required this.to,
      required this.status,
      this.fromLat,
      this.fromLng,
      this.toLat,
      this.toLng,
      this.details = const {}});
  final String title, from, to, status;
  final double? fromLat, fromLng, toLat, toLng;
  final Map<String, String> details;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ListTile(
            title: Text(title), subtitle: Text(status.replaceAll('_', ' '))),
        TripRouteMap(
            from: from,
            to: to,
            fromLat: fromLat,
            fromLng: fromLng,
            toLat: toLat,
            toLng: toLng),
        ...details.entries.map((entry) => ListTile(
            title: Text(entry.key), subtitle: SelectableText(entry.value))),
      ]));
}
