class HospitalModel {
  final String name;
  final double lat;
  final double lng;
  final String phone;
  final double distanceKm;
  final String type; // hospital, police, ambulance, rescue
  final String placeId;

  HospitalModel({
    required this.name,
    required this.lat,
    required this.lng,
    required this.phone,
    required this.distanceKm,
    required this.type,
    required this.placeId,
  });

  String get distanceText {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)}m away';
    }
    return '${distanceKm.toStringAsFixed(1)}km away';
  }

  String get typeEmoji {
    switch (type) {
      case 'hospital':
        return '🏥';
      case 'police':
        return '🚓';
      case 'ambulance':
        return '🚑';
      case 'rescue':
        return '🔧';
      default:
        return '📍';
    }
  }
}
