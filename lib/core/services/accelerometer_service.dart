import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../constants/thresholds.dart';

enum DetectionState {
  idle,
  impactFound,
  confirmingStillness,
  alerting,
  sosActive,
  resolved,
}

class AccelerometerService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  Timer? _stillnessTimer;
  Timer? _countdownTimer;

  // Callbacks
  Function()? onImpactConfirmed;
  Function(int secondsLeft)? onCountdownTick;
  Function()? onSosTriggered;

  DetectionState _state = DetectionState.idle;
  DetectionState get state => _state;

  double _lastSpeed = 0.0;
  double _currentMagnitude = 0.0;

  void setSpeed(double speedKmh) {
    _lastSpeed = speedKmh;
  }

  void startListening() {
    _subscription = accelerometerEventStream().listen((event) {
      _currentMagnitude = _calculateMagnitude(event.x, event.y, event.z);

      _processReading(_currentMagnitude);
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _stillnessTimer?.cancel();
    _countdownTimer?.cancel();
    _state = DetectionState.idle;
  }

  double _calculateMagnitude(double x, double y, double z) {
    double raw = sqrt(x * x + y * y + z * z);
    // Subtract gravity (9.8) to get only impact force
    return (raw - 9.8).abs();
  }

  void _processReading(double magnitude) {
    if (_state != DetectionState.idle) return;

    if (magnitude > DetectionThresholds.impactThreshold) {
      _state = DetectionState.alerting;
      onImpactConfirmed?.call();
      _startCountdown();
    }
  }

  void _startStillnessCheck() {
    // STEP 2: Check stillness for 3 seconds
    _state = DetectionState.confirmingStillness;

    _stillnessTimer = Timer(
      const Duration(seconds: DetectionThresholds.stillnessCheckSeconds),
      () {
        // After 3 seconds, check if phone is still still
        if (_currentMagnitude < DetectionThresholds.stillnessThreshold) {
          // Confirmed crash — phone hasn't moved
          _state = DetectionState.alerting;
          onImpactConfirmed?.call();
          _startCountdown();
        } else {
          // Phone moved — normal drop, reset
          _state = DetectionState.idle;
        }
      },
    );

    // Monitor for movement during stillness check
    StreamSubscription<AccelerometerEvent>? movementCheck;
    movementCheck = accelerometerEventStream().listen((event) {
      double mag = _calculateMagnitude(event.x, event.y, event.z);
      if (_state == DetectionState.confirmingStillness &&
          mag > DetectionThresholds.stillnessThreshold + 5) {
        // Movement detected — false alarm
        _stillnessTimer?.cancel();
        _state = DetectionState.idle;
        movementCheck?.cancel();
      }
    });
  }

  void _startCountdown() {
    bool isHighPriority =
        _lastSpeed > DetectionThresholds.vehicleSpeedThreshold;
    int totalSeconds = isHighPriority
        ? DetectionThresholds.highPriorityCountdown
        : DetectionThresholds.lowPriorityCountdown;

    int secondsLeft = totalSeconds;

    // Set initial value immediately
    onCountdownTick?.call(secondsLeft);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsLeft--;
      onCountdownTick?.call(secondsLeft);

      if (secondsLeft <= 0) {
        timer.cancel();
        _state = DetectionState.sosActive;
        onSosTriggered?.call();
      }
    });
  }

  // Called when user taps "I AM SAFE" or enters PIN
  void cancelAlert() {
    _countdownTimer?.cancel();
    _stillnessTimer?.cancel();
    _state = DetectionState.idle;
  }

  // Called when user taps "SEND SOS NOW"
  void triggerNow() {
    _countdownTimer?.cancel();
    _state = DetectionState.sosActive;
    onSosTriggered?.call();
  }

  void dispose() {
    stopListening();
  }
}
