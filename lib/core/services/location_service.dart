import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
  );
      _lastKnownPosition = position;
      await _reverseGeocode(position);
      return position;
    } catch (e) {
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

  Stream<double> get speedStream {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).map((pos) {
      _lastKnownPosition = pos;
      return (pos.speed * 3.6).clamp(0, double.infinity);
    });
  }

  String buildGoogleMapsLink(Position position) {
    return 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
  }
}
