import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roadsos/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/accelerometer_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/sms_service.dart';

final detectionStateProvider =
    StateNotifierProvider<DetectionNotifier, DetectionState>((ref) {
  return DetectionNotifier(ref);
});

final countdownProvider = StateProvider<int>((ref) => 60);
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
    _locationService.speedStream.listen((speedKmh) {
      _accelerometerService.setSpeed(speedKmh);
    });

    _accelerometerService.onImpactConfirmed = () {
      state = DetectionState.alerting;
    };

    _accelerometerService.onCountdownTick = (secondsLeft) {
      _ref.read(countdownProvider.notifier).state = secondsLeft;
    };

    _accelerometerService.onSosTriggered = () {
      state = DetectionState.sosActive;
      _fireSos(triggeredBy: 'auto');
    };

    _accelerometerService.startListening();
  }

  Future<void> _fireSos({String triggeredBy = 'manual'}) async {
    state = DetectionState.sosActive;

    final position = await _locationService.getCurrentPosition();
    if (position == null) return;

    // Save to history
    await _saveToHistory(
      lat: position.latitude,
      lng: position.longitude,
      city: _locationService.lastKnownCity,
      state: _locationService.lastKnownState,
      triggeredBy: triggeredBy,
    );

    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('userName') ?? 'Someone';
    final phone = prefs.getString('userPhone') ?? '';
    final bloodGroup = prefs.getString('bloodGroup') ?? 'Unknown';

    final contactsRaw = prefs.getStringList('emergencyContacts') ?? [];
    final contacts = contactsRaw.map((c) {
      final parts = c.split('|');
      return EmergencyContact(
        name: parts[0],
        phone: parts[1],
        relation: parts[2],
      );
    }).toList();

    final user = UserModel(
      id: '1',
      name: name,
      phone: phone,
      bloodGroup: bloodGroup,
      emergencyContacts: contacts,
    );

    await _smsService.sendSosToAll(
      user: user,
      position: position,
      city: _locationService.lastKnownCity,
      state: _locationService.lastKnownState,
    );
  }

  Future<void> _saveToHistory({
    required double lat,
    required double lng,
    required String city,
    required String state,
    required String triggeredBy,
    bool falseAlarm = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('sos_history') ?? [];
    raw.add(json.encode({
      'timestamp': DateTime.now().toIso8601String(),
      'lat': lat,
      'lng': lng,
      'city': city,
      'state': state,
      'triggeredBy': triggeredBy,
      'falseAlarm': falseAlarm,
    }));
    await prefs.setStringList('sos_history', raw);
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
    _fireSos(triggeredBy: 'manual');
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