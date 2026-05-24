import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../detection/providers/detection_provider.dart';
import '../../detection/screens/are_you_safe_dialog.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/accelerometer_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detectionState = ref.watch(detectionStateProvider);
    final isActive = ref.watch(isDetectionActiveProvider);

 ref.listen(detectionStateProvider, (previous, next) {
  if (next == DetectionState.alerting) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AreYouSafeDialog(),
    );
  }
});
WidgetsBinding.instance.addPostFrameCallback((_) async {
  await Permission.location.request();
  await Permission.sms.request();
});
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.emergency, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'RoadSoS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Detection toggle
          Switch(
            value: isActive,
            activeColor: AppTheme.safeGreen,
            onChanged: (val) {
              ref.read(detectionStateProvider.notifier).toggleDetection(val);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status card
            _StatusCard(isActive: isActive),
            const SizedBox(height: 24),

            // Big SOS Button
            _SosButton(
              onPressed: () {
                ref.read(detectionStateProvider.notifier).triggerManualSos();
              },
            ),
            const SizedBox(height: 24),

            // Quick dial buttons
            const _QuickDial(),
            const SizedBox(height: 24),

            // Stats card
            const _StatsCard(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.cardDark,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isActive;
  const _StatusCard({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.safeGreen.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppTheme.safeGreen : Colors.white24,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.shield : Icons.shield_outlined,
            color: isActive ? AppTheme.safeGreen : Colors.white38,
          ),
          const SizedBox(width: 12),
          Text(
            isActive
                ? '🛡️ Crash detection is ON'
                : '⚠️ Crash detection is OFF',
            style: TextStyle(
              color: isActive ? AppTheme.safeGreen : Colors.white38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SosButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryRed,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRed.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency, color: Colors.white, size: 60),
            SizedBox(height: 8),
            Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            Text(
              'Press & Hold',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDial extends StatelessWidget {
  const _QuickDial();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DialButton(number: '108', label: 'Ambulance', icon: '🚑'),
        const SizedBox(width: 12),
        _DialButton(number: '100', label: 'Police', icon: '🚓'),
        const SizedBox(width: 12),
        _DialButton(number: '1033', label: 'Highway', icon: '🛣️'),
      ],
    );
  }
}

class _DialButton extends StatelessWidget {
  final String number;
  final String label;
  final String icon;

  const _DialButton({
    required this.number,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, color: AppTheme.primaryRed),
          SizedBox(width: 8),
          Text(
            'RoadSoS has helped ',
            style: TextStyle(color: Colors.white70),
          ),
          Text(
            '0 people',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(' across India 🇮🇳', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
