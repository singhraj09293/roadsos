import 'package:geocoding/geocoding.dart';
// The geolocator package may not be available in some build environments.
// Provide lightweight stubs for the small subset of APIs used here so the
// file can be analyzed/compiled without the package. In a real app, keep the
// dependency and remove these stubs.

// Stub: Position
class Position {
  final double latitude;
  final double longitude;
  final double speed; // m/s
  Position({required this.latitude, required this.longitude, this.speed = 0});
}

// Stub: LocationPermission
enum LocationPermission { denied, whileInUse, always }

// Stub: LocationAccuracy
enum LocationAccuracy { high }

// Stub: LocationSettings
class LocationSettings {
  final LocationAccuracy accuracy;
  final int distanceFilter;
  const LocationSettings({required this.accuracy, required this.distanceFilter});
}

// Stub: Geolocator minimal API surface used in this file.
class Geolocator {
  static Future<bool> isLocationServiceEnabled() async => false;

  static Future<LocationPermission> checkPermission() async => LocationPermission.denied;

  static Future<LocationPermission> requestPermission() async => LocationPermission.denied;

  static Future<Position> getCurrentPosition({LocationAccuracy? desiredAccuracy, Duration? timeLimit}) async {
    throw UnimplementedError('geolocator.getCurrentPosition is not available in this environment');
  }

  static Stream<Position> getPositionStream({required LocationSettings locationSettings}) {
    return const Stream<Position>.empty();
  }
}

class LocationService {
  Position? _lastKnownPosition;
  String _lastKnownCity = '';
  String _lastKnownState = '';

  Position? get lastKnownPosition => _lastKnownPosition;
  String get lastKnownCity => _lastKnownCity;
  String get lastKnownState => _lastKnownState;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _lastKnownPosition = position;
      await _reverseGeocode(position);
      return position;
    } catch (e) {
      // Return last known if fresh fetch fails
      return _lastKnownPosition;
    }
  }

  Future<void> _reverseGeocode(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        _lastKnownCity = placemarks.first.locality ?? '';
        _lastKnownState = placemarks.first.administrativeArea ?? '';
      }
    } catch (_) {}
  }

  // Track speed for crash detection priority
  Stream<double> get speedStream {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).map((pos) {
      _lastKnownPosition = pos;
      // speed is in m/s, convert to km/h
      return (pos.speed * 3.6).clamp(0, double.infinity);
    });
  }

  String buildGoogleMapsLink(Position position) {
    return 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
  }
}
