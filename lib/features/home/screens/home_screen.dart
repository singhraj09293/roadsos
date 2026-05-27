import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:roadsos/core/services/accelerometer_service.dart';
import 'package:roadsos/features/history/screen/histroy_screen.dart';
import 'package:roadsos/features/home/widget/danger_alerts_widget.dart';
import 'package:roadsos/features/map/screen/map_screen.dart';
import 'package:roadsos/features/profile/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../detection/providers/detection_provider.dart';
import '../../detection/screens/are_you_safe_dialog.dart';
import '../../../core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
// adjust import path

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final _screens = const [
    _HomeBody(),
    MapScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Permission.location.request();
      await Permission.sms.request();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(detectionStateProvider, (previous, next) {
      if (next == DetectionState.alerting) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AreYouSafeDialog(),
        );
      }
    });

    final isActive = ref.watch(isDetectionActiveProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: AppTheme.backgroundDark,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.emergency,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'RoadSoS',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              actions: [
                Switch(
                  value: isActive,
                  activeColor: AppTheme.safeGreen,
                  onChanged: (val) => ref
                      .read(detectionStateProvider.notifier)
                      .toggleDetection(val),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.cardDark,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
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

class _HomeBody extends ConsumerWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(isDetectionActiveProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _StatusCard(isActive: isActive), // ← 1st
          const SizedBox(height: 12),
          const _ConnectivityCard(), // ← 2nd
          const SizedBox(height: 24),
          _SosButton(
            onPressed: () =>
                ref.read(detectionStateProvider.notifier).triggerManualSos(),
          ),
          const SizedBox(height: 24),
          const _QuickDial(),
          const SizedBox(height: 24),
          const _StatsCard(),
          const SizedBox(height: 24),
          const DangerAlertsWidget(), // ← last
        ],
      ),
    );
  }
}

// Temporary placeholder for unbuilt screens
class _PlaceholderScreen extends StatelessWidget {
  final String name;
  const _PlaceholderScreen(this.name);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(name,
          style: const TextStyle(color: Colors.white54, fontSize: 20)),
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
        border:
            Border.all(color: isActive ? AppTheme.safeGreen : Colors.white24),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.shield : Icons.shield_outlined,
            color: isActive ? AppTheme.safeGreen : Colors.white38,
          ),
          const SizedBox(width: 12),
          Text(
            isActive ? 'Crash detection is ON' : 'Crash detection is OFF',
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

class _SosButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _SosButton({required this.onPressed});

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton> {
  bool _holding = false;
  int _countdown = 3;
  Timer? _timer;

  void _startHold() {
    setState(() {
      _holding = true;
      _countdown = 3;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 1) {
        t.cancel();
        setState(() => _holding = false);
        widget.onPressed();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _cancelHold() {
    if (!_holding) return; // ← guard: ignore if already triggered
    _timer?.cancel();
    setState(() {
      _holding = false;
      _countdown = 3;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _holding ? _cancelHold() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _holding ? 220 : 200,
        height: _holding ? 220 : 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryRed,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRed.withOpacity(_holding ? 0.7 : 0.4),
              blurRadius: _holding ? 50 : 30,
              spreadRadius: _holding ? 20 : 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emergency, color: Colors.white, size: 60),
            const SizedBox(height: 8),
            Text(
              _holding ? '$_countdown' : 'SOS',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            Text(
              _holding ? 'Release to cancel' : 'Press & Hold',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
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
    return const Row(
      children: [
        _DialButton(number: '108', label: 'Ambulance', icon: '🚑'),
        SizedBox(width: 12),
        _DialButton(number: '100', label: 'Police', icon: '🚓'),
        SizedBox(width: 12),
        _DialButton(number: '1033', label: 'Highway', icon: '🛣️'),
      ],
    );
  }
}

class _DialButton extends StatelessWidget {
  final String number;
  final String label;
  final String icon;
  const _DialButton(
      {required this.number, required this.label, required this.icon});

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: _call,
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
              Text(number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatefulWidget {
  const _StatsCard({super.key});

  @override
  State<_StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<_StatsCard> {
  int _helpedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('sos_history') ?? [];
    // Count only real SOS events (not false alarms)
    final count = history.where((e) {
      final map = json.decode(e);
      return map['falseAlarm'] != true;
    }).length;
    if (mounted) setState(() => _helpedCount = count);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, color: AppTheme.primaryRed),
            const SizedBox(width: 8),
            const Text('RoadSoS has helped ',
                style: TextStyle(color: Colors.white70)),
            Text(
              '$_helpedCount ${_helpedCount == 1 ? 'person' : 'people'}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const Text(' across India 🇮🇳',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _ConnectivityCard extends StatefulWidget {
  const _ConnectivityCard();

  @override
  State<_ConnectivityCard> createState() => _ConnectivityCardState();
}

class _ConnectivityCardState extends State<_ConnectivityCard> {
  bool _isOnline = true;
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      setState(() => _isOnline = !results.contains(ConnectivityResult.none));
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted)
      setState(() => _isOnline = !results.contains(ConnectivityResult.none));
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isOnline
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isOnline
                  ? Colors.green.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isOnline ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isOnline ? 'Online' : 'Offline — SOS active',
                style: TextStyle(
                  color: _isOnline ? Colors.green : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
