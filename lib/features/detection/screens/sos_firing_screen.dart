import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/detection_provider.dart';
import '../../home/screens/home_screen.dart';

class SosFiringScreen extends ConsumerWidget {
  const SosFiringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SOS icon pulsing
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  border: Border.all(color: AppTheme.primaryRed, width: 2),
                ),
                child: const Icon(
                  Icons.emergency,
                  color: AppTheme.primaryRed,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                '🚨 SOS ACTIVATED',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Status items
              const _StatusItem(icon: '📍', text: 'Getting your location...'),
              const SizedBox(height: 16),
              const _StatusItem(icon: '📲', text: 'Alerting emergency contacts...'),
              const SizedBox(height: 16),
              const _StatusItem(icon: '🏥', text: 'Finding nearest hospitals...'),
              const SizedBox(height: 48),

              // Quick dial
              const Text(
                'Call Now',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  _CallButton(number: '108', label: 'Ambulance'),
                  SizedBox(width: 12),
                  _CallButton(number: '100', label: 'Police'),
                  SizedBox(width: 12),
                  _CallButton(number: '1033', label: 'Highway'),
                ],
              ),
              const SizedBox(height: 32),

              // I am safe button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.safeGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    ref.read(detectionStateProvider.notifier).userIsSafe();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  child: const Text(
                    '✅ I AM SAFE — Cancel SOS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String icon;
  final String text;
  const _StatusItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  final String number;
  final String label;
  const _CallButton({required this.number, required this.label});

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: _call,
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}