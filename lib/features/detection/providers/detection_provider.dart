import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/accelerometer_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/sms_service.dart';

// Detection state provider
final detectionStateProvider =
    StateNotifierProvider<DetectionNotifier, DetectionState>((ref) {
  return DetectionNotifier(ref);
});

// Countdown seconds provider
final countdownProvider = StateProvider<int>((ref) => 60);

// Is detection active provider
final isDetectionActiveProvider = StateProvider<bool>((ref) => true);

class DetectionNotifier extends StateNotifier<DetectionState> {
  final Ref _ref;
  final AccelerometerService _accelerometerService = AccelerometerService();
  final LocationService _locationService = LocationService();
  final SmsService _smsService = SmsService();

  DetectionNotifier(this._ref) : super(DetectionState.idle) {
    _init();
  }

  void _init() {
    // Listen to speed for priority detection
    _locationService.speedStream.listen((speedKmh) {
      _accelerometerService.setSpeed(speedKmh);
    });

    // Set up callbacks
    _accelerometerService.onImpactConfirmed = () {
      state = DetectionState.alerting;
    };

    _accelerometerService.onCountdownTick = (secondsLeft) {
      _ref.read(countdownProvider.notifier).state = secondsLeft;
    };

    _accelerometerService.onSosTriggered = () {
      state = DetectionState.sosActive;
      _fireSos();
    };

    // Start listening
    _accelerometerService.startListening();
  }

  Future<void> _fireSos() async {
    state = DetectionState.sosActive;

    // Get location
    final position = await _locationService.getCurrentPosition();
    if (position == null) return;

    // TODO: Get user from Firestore and send SMS
    // This will be wired up with the user provider
  }

  void userIsSafe() {
    _accelerometerService.cancelAlert();
    state = DetectionState.idle;
    _ref.read(countdownProvider.notifier).state = 30;
  }

  void triggerSosNow() {
    _accelerometerService.triggerNow();
  }

  void triggerManualSos() {
    state = DetectionState.sosActive;
    _fireSos();
  }

  void toggleDetection(bool isActive) {
    if (isActive) {
      _accelerometerService.startListening();
    } else {
      _accelerometerService.stopListening();
    }
    _ref.read(isDetectionActiveProvider.notifier).state = isActive;
  }

  @override
  void dispose() {
    _accelerometerService.dispose();
    super.dispose();
  }
}
