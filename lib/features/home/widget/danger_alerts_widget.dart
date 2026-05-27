import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/danger_alert_service.dart';
import '../../../core/theme/app_theme.dart';

class DangerAlertsWidget extends StatefulWidget {
  const DangerAlertsWidget({super.key});

  @override
  State<DangerAlertsWidget> createState() => _DangerAlertsWidgetState();
}

class _DangerAlertsWidgetState extends State<DangerAlertsWidget> {
  final _service = DangerAlertService();
  List<DangerAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      final alerts = await _service.getAlerts(position);
      if (mounted) setState(() { _alerts = alerts; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _levelColor(AlertLevel level) {
    switch (level) {
      case AlertLevel.high: return AppTheme.primaryRed;
      case AlertLevel.medium: return Colors.orange;
      case AlertLevel.low: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)),
            SizedBox(width: 12),
            Text('Checking road conditions...', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }

    if (_alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 12),
            Text('Road conditions look good!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('⚠️ Road Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        ..._alerts.map((alert) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _levelColor(alert.level).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _levelColor(alert.level).withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alert.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: TextStyle(color: _levelColor(alert.level), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(alert.message, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}