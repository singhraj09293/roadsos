class DetectionThresholds {
  // Accelerometer impact threshold (m/s²)
  // Normal gravity = 9.8, impact > 25 is significant
  static const double impactThreshold = 20.0;

  // Stillness check duration (seconds)
  // After impact, how long to wait to confirm no movement
  static const int stillnessCheckSeconds = 3;

  // Are you safe countdown (seconds)
  // High speed (vehicle) scenario
  static const int highPriorityCountdown = 30;

  // Are you safe countdown (seconds)
  // Low speed (walking/stationary) scenario
  static const int lowPriorityCountdown = 30;

  // Speed threshold to determine priority (km/h)
  // Above this = high priority (likely vehicle accident)
  static const double vehicleSpeedThreshold = 20.0;

  // Stillness magnitude threshold
  // Below this = phone is considered still
  static const double stillnessThreshold = 2.0;

  // Cancel PIN
  static const String cancelPin = '1234';

  // SMS location prefix
  static const String googleMapsPrefix = 'https://maps.google.com/?q=';

  // Nearby search radius (meters)
  static const int searchRadiusMeters = 5000;
}
