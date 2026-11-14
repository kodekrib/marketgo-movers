import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/maps_service.dart';

/// Historical pickup/destination pins, with no simulated rider or live GPS.
class TripRouteMap extends StatefulWidget {
  const TripRouteMap(
      {super.key,
      required this.from,
      required this.to,
      this.fromLat,
      this.fromLng,
      this.toLat,
      this.toLng,
      this.service});
  final String from, to;
  final double? fromLat, fromLng, toLat, toLng;
  final MapsService? service;
  @override
  State<TripRouteMap> createState() => _TripRouteMapState();
}

class _TripRouteMapState extends State<TripRouteMap> {
  LatLng? _from, _to;
  MapConfig _config = const MapConfig();
  bool _loading = true;
  bool _valid(double? lat, double? lng) =>
      lat != null &&
      lng != null &&
      lat.isFinite &&
      lng.isFinite &&
      lat.abs() <= 90 &&
      lng.abs() <= 180 &&
      (lat != 0 || lng != 0);
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<LatLng?> _point(
      MapsService service, String address, double? lat, double? lng) async {
    if (_valid(lat, lng)) return LatLng(lat!, lng!);
    final found = await service.searchPlaces(address);
    if (found.isEmpty || !_valid(found.first.latitude, found.first.longitude)) {
      return null;
    }
    return LatLng(found.first.latitude, found.first.longitude);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final service = widget.service ?? MapsService();
    final config = await service.fetchConfig();
    final from =
        await _point(service, widget.from, widget.fromLat, widget.fromLng);
    final to = await _point(service, widget.to, widget.toLat, widget.toLng);
    if (!mounted) return;
    setState(() {
      _config = config;
      _from = from;
      _to = to;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tile = _config.isMapbox
        ? 'https://api.mapbox.com/styles/v1/mapbox/${_config.mapboxStyle}/tiles/256/{z}/{x}/{y}@2x?access_token=${Uri.encodeQueryComponent(_config.mapboxPublicToken)}'
        : _config.isLeaflet
            ? _config.leafletTileUrl
            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    return Card(
        clipBehavior: Clip.antiAlias,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ListTile(
              leading: const Icon(Icons.trip_origin, color: Colors.green),
              title: const Text('From'),
              subtitle: Text(widget.from.isEmpty
                  ? 'Pickup address unavailable'
                  : widget.from)),
          ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: const Text('To'),
              subtitle: Text(
                  widget.to.isEmpty ? 'Destination unavailable' : widget.to)),
          if (_loading)
            const SizedBox(
                height: 180, child: Center(child: CircularProgressIndicator()))
          else if (_from == null || _to == null)
            Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const Text('Map locations are unavailable for this trip.'),
                  TextButton(onPressed: _load, child: const Text('Retry map'))
                ]))
          else
            SizedBox(
                height: 280,
                child: FlutterMap(
                    key: ValueKey('${_from!}:${_to!}'),
                    options: MapOptions(
                        initialCenter: _from!,
                        initialZoom: 13,
                        initialCameraFit: CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints([_from!, _to!]),
                            padding: const EdgeInsets.all(48),
                            maxZoom: 16)),
                    children: [
                      TileLayer(
                          urlTemplate: tile,
                          userAgentPackageName: 'com.marketgo.app'),
                      PolylineLayer(polylines: [
                        Polyline(
                            points: [_from!, _to!],
                            strokeWidth: 3,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(.6))
                      ]),
                      MarkerLayer(markers: [
                        Marker(
                            point: _from!,
                            width: 40,
                            height: 40,
                            child: const Tooltip(
                                message: 'Pickup',
                                child: Icon(Icons.trip_origin,
                                    size: 32, color: Colors.green))),
                        Marker(
                            point: _to!,
                            width: 40,
                            height: 40,
                            child: const Tooltip(
                                message: 'Destination',
                                child: Icon(Icons.location_on,
                                    size: 36, color: Colors.red)))
                      ])
                    ])),
          if (_from != null && _to != null)
            const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                    'Pickup and destination overview · Line connects stops',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11))),
          Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                  _config.isMapbox
                      ? '© Mapbox © OpenStreetMap'
                      : '© OpenStreetMap contributors',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 10))),
        ]));
  }
}
