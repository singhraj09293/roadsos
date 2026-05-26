import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint(
          '📍 Got position: ${position.latitude}, ${position.longitude}');
      setState(() =>
          _currentLocation = LatLng(position.latitude, position.longitude));

      setState(() => _statusText = 'Finding nearby help...');

      // Sequential instead of parallel
      await _fetchPlaces(position.latitude, position.longitude, 'hospital');
      await _fetchPlaces(position.latitude, position.longitude, 'clinic');
      await _fetchPlaces(position.latitude, position.longitude, 'police');

      setState(() => _isLoading = false);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _mapController.move(_currentLocation!, 14);
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() {
        _isLoading = false;
        _statusText = 'Error: $e';
      });
    }
  }

  Future<void> _fetchPlaces(double lat, double lng, String type) async {
    debugPrint('🔍 Fetching $type at $lat, $lng');
    final amenity = type;
    final uri = Uri.parse('https://nominatim.openstreetmap.org/search?'
        'amenity=$amenity&'
        'format=json&'
        'limit=15&'
        'countrycodes=in&'
        'viewbox=${lng - 0.05},${lat + 0.05},${lng + 0.05},${lat - 0.05}&'
        'bounded=1');
    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'RoadSoS/1.0 (com.example.roadsos)'},
      ).timeout(const Duration(seconds: 15));

      debugPrint('✅ $type status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        debugPrint('📊 $type count: ${data.length}');
        if (_hospitals.isNotEmpty) {
          debugPrint(
              '🏥 First hospital: ${_hospitals[0].lat}, ${_hospitals[0].lng}');
        }

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
            setState(() {
              if (type == 'hospital' || type == 'clinic')
                _hospitals = [..._hospitals, ...places];
              else
                _policeStations = places;
            });
          });
        }
      }
    } on TimeoutException {
      debugPrint('⏱️ $type timed out');
    } catch (e) {
      debugPrint('❌ $type error: $e');
    }
  }

  List<Marker> _buildMarkers() {
    debugPrint(
        '🗺️ Building markers: ${_hospitals.length} hospitals, ${_policeStations.length} police');
    final markers = <Marker>[];

    if (_currentLocation != null) {
      markers.add(Marker(
        point: _currentLocation!,
        width: 50,
        height: 50,
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
          child: const Icon(Icons.person_pin, color: Colors.white, size: 20),
        ),
      ));
    }

    for (final h in _hospitals) {
      markers.add(Marker(
        point: LatLng(h.lat, h.lng),
        width: 44,
        height: 44,
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
            child:
                const Icon(Icons.local_hospital, color: Colors.white, size: 20),
          ),
        ),
      ));
    }

    for (final p in _policeStations) {
      markers.add(Marker(
        point: LatLng(p.lat, p.lng),
        width: 44,
        height: 44,
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
            child:
                const Icon(Icons.local_police, color: Colors.white, size: 20),
          ),
        ),
      ));
    }

    return markers;
  }

  void _showPlaceInfo(_Place place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (place.type == 'hospital' ? Colors.blue : Colors.orange)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                place.type == 'hospital'
                    ? Icons.local_hospital
                    : Icons.local_police,
                color: place.type == 'hospital' ? Colors.blue : Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text(place.type == 'hospital' ? 'Hospital' : 'Police Station',
                      style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  : '${_hospitals.length} hospitals • ${_policeStations.length} police stations',
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
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: () {
              if (_currentLocation != null)
                _mapController.move(_currentLocation!, 14);
            },
          ),
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
                ],
              ),
            )
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
                    ],
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                          initialCenter: _currentLocation!, initialZoom: 14),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.roadsos',
                        ),
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _LegendItem(
                                icon: Icons.person_pin,
                                color: AppTheme.primaryRed,
                                label: 'You'),
                            _LegendItem(
                                icon: Icons.local_hospital,
                                color: Colors.blue,
                                label: 'Hospital'),
                            _LegendItem(
                                icon: Icons.local_police,
                                color: Colors.orange,
                                label: 'Police'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
  final IconData icon;
  final Color color;
  final String label;
  const _LegendItem(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
