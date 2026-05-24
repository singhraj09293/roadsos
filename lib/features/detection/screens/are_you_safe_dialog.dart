import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roadsos/core/services/accelerometer_service.dart';
import '../providers/detection_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/thresholds.dart';
import 'sos_firing_screen.dart';

class AreYouSafeDialog extends ConsumerStatefulWidget {
  const AreYouSafeDialog({super.key});

  @override
  ConsumerState<AreYouSafeDialog> createState() => _AreYouSafeDialogState();
}

class _AreYouSafeDialogState extends ConsumerState<AreYouSafeDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _showPinEntry = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(detectionStateProvider, (previous, next) {
        if (next == DetectionState.sosActive && mounted) {
          // Close dialog first
          Navigator.of(context).pop();
          // Then navigate to SOS screen
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SosFiringScreen()),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _checkPin(String pin) {
    if (pin == DetectionThresholds.cancelPin) {
      ref.read(detectionStateProvider.notifier).userIsSafe();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final countdown = ref.watch(countdownProvider);

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.primaryRed, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: AppTheme.primaryRed,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Are You Safe?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'We detected a possible accident.\nSending SOS in...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),

                // Countdown circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: countdown <= 10
                          ? AppTheme.primaryRed
                          : AppTheme.warningOrange,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$countdown',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: countdown <= 10
                            ? AppTheme.primaryRed
                            : AppTheme.warningOrange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // PIN entry toggle
                if (!_showPinEntry) ...[
                  TextButton(
                    onPressed: () => setState(() => _showPinEntry = true),
                    child: const Text(
                      'Type PIN to cancel (1234)',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter PIN',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      counterText: '',
                    ),
                    onChanged: _checkPin,
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 8),

                // I AM SAFE button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.safeGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      ref.read(detectionStateProvider.notifier).userIsSafe();
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      '✅  I AM SAFE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // SEND SOS NOW button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryRed),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // close dialog first
                      ref.read(detectionStateProvider.notifier).triggerSosNow();
                    },
                    child: const Text(
                      '🚨  SEND SOS NOW',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}