import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final isOnboardedProvider = StateProvider<bool>((ref) {
  // TODO: Read from SharedPreferences
  // For now returns false so onboarding always shows first time
  return false;
});

final onboardingPageProvider = StateProvider<int>((ref) => 0);

class OnboardingNotifier {
  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboarded', true);
  }

  static Future<bool> checkOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isOnboarded') ?? false;
  }
}
