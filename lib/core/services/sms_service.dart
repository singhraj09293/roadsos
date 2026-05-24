import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/user_model.dart';

class SmsService {
  Future<void> sendSosToAll({
    required UserModel user,
    required Position position,
    required String city,
    required String state,
    String nearestHospital = '',
  }) async {
    final message = _buildSosMessage(
      userName: user.name,
      position: position,
      city: city,
      state: state,
      bloodGroup: user.bloodGroup,
      nearestHospital: nearestHospital,
    );

    for (final contact in user.emergencyContacts) {
      await _sendSms(contact.phone, message);
      // Small delay between messages
      await Future.delayed(const Duration(milliseconds: 500));
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
    final timeStr =
        '${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';

    return '''🚨 EMERGENCY ALERT - RoadSoS
        
$userName may have been in an accident!

📍 Location: $mapsLink
🏙️ Area: $city, $state
⏰ Time: $timeStr
🩸 Blood Group: $bloodGroup
${nearestHospital.isNotEmpty ? '🏥 Nearest Hospital: $nearestHospital' : ''}

Please call 108 (Ambulance) immediately
or rush to the location.

Sent automatically by RoadSoS app''';
  }

  Future<void> _sendSms(String phone, String message) async {
    // Clean phone number
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanPhone.startsWith('+')) {
      cleanPhone = '+91$cleanPhone'; // Default India code
    }

    final uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
