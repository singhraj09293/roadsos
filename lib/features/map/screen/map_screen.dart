import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isLoading = true;
  String _statusText = 'Getting location...';
  List<_Place> _hospitals = [];
  List<_Place> _policeStations = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      setState(() => _statusText = 'Checking permissions...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _statusText = 'Location permission denied';
        });
        return;
      }

      setState(() => _statusText = 'Getting location...');
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() =>
          _currentLocation = LatLng(position.latitude, position.longitude));

      setState(() => _statusText = 'Finding nearby help...');
      await _fetchPlaces(position.latitude, position.longitude, 'hospital');
      await _fetchPlaces(position.latitude, position.longitude, 'clinic');
      await _fetchPlaces(position.latitude, position.longitude, 'police');

      setState(() => _isLoading = false);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _mapController.move(_currentLocation!, 14);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusText = 'Error: $e';
      });
    }
  }

  Future<void> _fetchPlaces(double lat, double lng, String type) async {
    final uri = Uri.parse('https://nominatim.openstreetmap.org/search?'
        'amenity=$type&format=json&limit=15&countrycodes=in&'
        'viewbox=${lng - 0.05},${lat + 0.05},${lng + 0.05},${lat - 0.05}&bounded=1');
    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'RoadSoS/1.0 (com.example.roadsos)'
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final places = data
            .map((e) => _Place(
                  name: e['display_name'].toString().split(',')[0],
                  lat: double.parse(e['lat']),
                  lng: double.parse(e['lon']),
                  type: type,
                ))
            .toList();
        if (mounted) {
          setState(() {
            if (type == 'hospital' || type == 'clinic')
              _hospitals = [..._hospitals, ...places];
            else
              _policeStations = places;
          });
        }
      }
    } on TimeoutException {
      debugPrint('⏱️ $type timed out');
    } catch (e) {
      debugPrint('❌ $type error: $e');
    }
  }

  double _distanceKm(_Place place) {
    if (_currentLocation == null) return 0;
    final d = const Distance();
    return d.as(
        LengthUnit.Kilometer, _currentLocation!, LatLng(place.lat, place.lng));
  }

  Future<void> _openGoogleMaps(_Place place) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1'
        '&destination=${place.lat},${place.lng}'
        '&travelmode=driving');
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showPlaceInfo(_Place place) {
    final dist = _distanceKm(place);
    final isHospital = place.type == 'hospital' || place.type == 'clinic';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isHospital ? Colors.blue : Colors.orange)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHospital ? Icons.local_hospital : Icons.local_police,
                    color: isHospital ? Colors.blue : Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text(isHospital ? 'Hospital / Clinic' : 'Police Station',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13)),
                      Text('${dist.toStringAsFixed(1)} km away',
                          style: TextStyle(
                              color: isHospital ? Colors.blue : Colors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isHospital ? Colors.blue : Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.directions, color: Colors.white),
                label: const Text('Get Directions',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  _openGoogleMaps(place);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_currentLocation != null) {
      markers.add(Marker(
        point: _currentLocation!,
        width: 54,
        height: 54,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primaryRed.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 4)
            ],
          ),
          child: const Text('🧍', style: TextStyle(fontSize: 30)),
        ),
      ));
    }

    for (final h in _hospitals) {
      markers.add(Marker(
        point: LatLng(h.lat, h.lng),
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () => _showPlaceInfo(h),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 2)
              ],
            ),
            child: const Text('🏥', style: TextStyle(fontSize: 28)),
          ),
        ),
      ));
    }

    for (final p in _policeStations) {
      markers.add(Marker(
          point: LatLng(p.lat, p.lng),
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () => _showPlaceInfo(p),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 2)
                ],
              ),
              child: const Text('🚓', style: TextStyle(fontSize: 28)),
            ),
          )));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final sortedHospitals = [..._hospitals]
      ..sort((a, b) => _distanceKm(a).compareTo(_distanceKm(b)));
    final sortedPolice = [..._policeStations]
      ..sort((a, b) => _distanceKm(a).compareTo(_distanceKm(b)));

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nearby Help', style: TextStyle(color: Colors.white)),
            Text(
              _isLoading
                  ? _statusText
                  : '${_hospitals.length} hospitals • ${_policeStations.length} police',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hospitals = [];
                  _policeStations = [];
                });
                _init();
              }),
          IconButton(
              icon: const Icon(Icons.my_location, color: Colors.white),
              onPressed: () {
                if (_currentLocation != null)
                  _mapController.move(_currentLocation!, 14);
              }),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  const CircularProgressIndicator(color: AppTheme.primaryRed),
                  const SizedBox(height: 16),
                  Text(_statusText,
                      style: const TextStyle(color: Colors.white54)),
                ]))
          : _currentLocation == null
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const Icon(Icons.location_off,
                          color: Colors.white38, size: 48),
                      const SizedBox(height: 16),
                      Text(_statusText,
                          style: const TextStyle(color: Colors.white54)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _init();
                        },
                        child: const Text('Retry'),
                      ),
                    ]))
              : Stack(children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                        initialCenter: _currentLocation!, initialZoom: 14),
                    children: [
                      TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.roadsos'),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _LegendItem(emoji: '🧍', label: 'You'),
                              _LegendItem(emoji: '🏥', label: 'Hospital'),
                              _LegendItem(emoji: '🚓', label: 'Police'),
                            ],
                          ),
                          if (sortedHospitals.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white12),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('🏥',
                                    style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(sortedHospitals.first.name,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                        overflow: TextOverflow.ellipsis)),
                                Text(
                                    '${_distanceKm(sortedHospitals.first).toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () =>
                                      _openGoogleMaps(sortedHospitals.first),
                                  child: const Icon(Icons.directions,
                                      color: Colors.blue, size: 18),
                                ),
                              ],
                            ),
                          ],
                          if (sortedPolice.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('🚓',
                                    style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(sortedPolice.first.name,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                        overflow: TextOverflow.ellipsis)),
                                Text(
                                    '${_distanceKm(sortedPolice.first).toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () =>
                                      _openGoogleMaps(sortedPolice.first),
                                  child: const Icon(Icons.directions,
                                      color: Colors.orange, size: 18),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ]),
    );
  }
}

class _Place {
  final String name;
  final double lat;
  final double lng;
  final String type;
  const _Place(
      {required this.name,
      required this.lat,
      required this.lng,
      required this.type});
}

class _LegendItem extends StatelessWidget {
  final String emoji;
  final String label;
  const _LegendItem({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
