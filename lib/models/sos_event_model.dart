import 'package:cloud_firestore/cloud_firestore.dart';

class SosEventModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final double lat;
  final double lng;
  final String city;
  final String state;
  final String triggeredBy; // 'auto' or 'manual'
  final bool falseAlarm;
  final String nearestHospital;
  final bool resolved;

  SosEventModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.city,
    required this.state,
    required this.triggeredBy,
    this.falseAlarm = false,
    this.nearestHospital = '',
    this.resolved = false,
  });

  factory SosEventModel.fromMap(Map<String, dynamic> map, String id) {
    return SosEventModel(
      id: id,
      userId: map['userId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      triggeredBy: map['triggeredBy'] ?? 'manual',
      falseAlarm: map['falseAlarm'] ?? false,
      nearestHospital: map['nearestHospital'] ?? '',
      resolved: map['resolved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'lat': lat,
      'lng': lng,
      'city': city,
      'state': state,
      'triggeredBy': triggeredBy,
      'falseAlarm': falseAlarm,
      'nearestHospital': nearestHospital,
      'resolved': resolved,
    };
  }
}
