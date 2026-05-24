import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/user_model.dart';

class SmsService {
  static const _channel = MethodChannel('com.roadsos/sms');

  Future<void> sendSosToAll({
    required UserModel user,
    required Position position,
    required String city,
    required String state,
    String nearestHospital = '',
  }) async {
    // Request SMS permission
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      print('❌ SMS permission denied');
      return;
    }

    final message = _buildSosMessage(
      userName: user.name,
      position: position,
      city: city,
      state: state,
      bloodGroup: user.bloodGroup,
      nearestHospital: nearestHospital,
    );

    print('📲 Sending to ${user.emergencyContacts.length} contacts');
    print('📝 Message: $message');

    for (final contact in user.emergencyContacts) {
      String phone = contact.phone.replaceAll(RegExp(r'[^\d]'), '');
      if (!phone.startsWith('91')) {
        phone = '91$phone';
      }
      print('📞 Sending to: $phone');
      await _sendSms(phone, message);
    }
  }

  Future<void> _sendSms(String phone, String message) async {
    try {
      await _channel.invokeMethod('sendSMS', {
        'phone': phone,
        'message': message,
      });
      print('✅ SMS sent to $phone');
    } on PlatformException catch (e) {
      print('❌ Failed to send SMS to $phone: ${e.message}');
    }
  }

  String _buildSosMessage({
    required String userName,
    required Position position,
    required String city,
    required String state,
    required String bloodGroup,
    String nearestHospital = '',
  }) {
    final mapsLink =
        'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    final time = DateTime.now();
    final timeStr = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

    return '''🚨 EMERGENCY - RoadSoS
$userName may be in an accident!
📍 $mapsLink
🏙️ $city, $state
⏰ $timeStr
🩸 Blood: $bloodGroup
${nearestHospital.isNotEmpty ? '🏥 Nearest Hospital: $nearestHospital\n' : ''}Call 108 immediately!''';
  }
}