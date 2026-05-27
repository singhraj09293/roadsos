import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class DangerAlert {
  final String title;
  final String message;
  final String icon;
  final AlertLevel level;

  DangerAlert({
    required this.title,
    required this.message,
    required this.icon,
    required this.level,
  });
}

enum AlertLevel { low, medium, high }

class DangerAlertService {
  static const _apiKey = 'd497b9a81e97afe2132b8de2e562f119';

  Future<List<DangerAlert>> getAlerts(Position position) async {
    final alerts = <DangerAlert>[];

    // Weather alerts
    final weatherAlerts = await _getWeatherAlerts(position);
    alerts.addAll(weatherAlerts);

    // Time based alerts
    alerts.addAll(_getTimeBasedAlerts());

    return alerts;
  }

  Future<List<DangerAlert>> _getWeatherAlerts(Position position) async {
    final alerts = <DangerAlert>[];
    try {
      final uri = Uri.parse('https://api.openweathermap.org/data/2.5/weather?'
          'lat=${position.latitude}&lon=${position.longitude}'
          '&appid=$_apiKey&units=metric');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weatherId = data['weather'][0]['id'] as int;
        final weatherMain = data['weather'][0]['main'].toString().toLowerCase();
        final windSpeed = (data['wind']['speed'] as num).toDouble();
        final visibility = data['visibility'] as int? ?? 10000;
        final temp = (data['main']['temp'] as num).toDouble();

        // Rain alerts
        if (weatherId >= 500 && weatherId < 600) {
          alerts.add(DangerAlert(
            title: 'Rain Alert',
            message: weatherId >= 502
                ? 'Heavy rain detected! Roads are very slippery. Reduce speed.'
                : 'Light rain detected. Watch for slippery roads.',
            icon: '🌧️',
            level: weatherId >= 502 ? AlertLevel.high : AlertLevel.medium,
          ));
        }

        // Thunderstorm
        if (weatherId >= 200 && weatherId < 300) {
          alerts.add(DangerAlert(
            title: 'Thunderstorm Warning',
            message:
                'Thunderstorm in your area! Avoid riding. Pull over safely.',
            icon: '⛈️',
            level: AlertLevel.high,
          ));
        }

        // Fog/mist
        if (weatherId >= 700 && weatherId < 800) {
          alerts.add(DangerAlert(
            title: 'Low Visibility',
            message: 'Fog or mist detected. Use headlights and reduce speed.',
            icon: '🌫️',
            level: AlertLevel.medium,
          ));
        }

        // Strong wind
        if (windSpeed > 10) {
          alerts.add(DangerAlert(
            title: 'Strong Wind',
            message:
                'Wind speed ${windSpeed.toStringAsFixed(0)} m/s. Be careful on open roads.',
            icon: '💨',
            level: AlertLevel.medium,
          ));
        }

        // Poor visibility
        if (visibility < 1000) {
          alerts.add(DangerAlert(
            title: 'Very Poor Visibility',
            message: 'Visibility below 1km. Extremely dangerous to ride.',
            icon: '⚠️',
            level: AlertLevel.high,
          ));
        }

        // Extreme heat
        if (temp > 42) {
          alerts.add(DangerAlert(
            title: 'Extreme Heat',
            message:
                'Temperature ${temp.toStringAsFixed(0)}°C. Stay hydrated. Risk of tire blowout.',
            icon: '🌡️',
            level: AlertLevel.medium,
          ));
        }
      }
    } catch (e) {
      // silently fail
    }
    return alerts;
  }

  List<DangerAlert> _getTimeBasedAlerts() {
    final alerts = <DangerAlert>[];
    final hour = DateTime.now().hour;

    // Night driving
    if (hour >= 22 || hour < 5) {
      alerts.add(DangerAlert(
        title: 'Night Driving Alert',
        message:
            'Night time increases accident risk by 3x. Stay alert and use headlights.',
        icon: '🌙',
        level: AlertLevel.medium,
      ));
    }

    // Peak traffic hours
    if ((hour >= 8 && hour <= 10) || (hour >= 17 && hour <= 20)) {
      alerts.add(DangerAlert(
        title: 'Peak Traffic Hours',
        message: 'High traffic period. Extra caution needed at intersections.',
        icon: '🚦',
        level: AlertLevel.low,
      ));
    }

    // Monsoon season (June - September)
    final month = DateTime.now().month;
    if (month >= 6 && month <= 9) {
      alerts.add(DangerAlert(
        title: 'Monsoon Season',
        message:
            'Monsoon season active. Watch for waterlogged roads and reduced visibility.',
        icon: '☔',
        level: AlertLevel.medium,
      ));
    }

    return alerts;
  }
}
