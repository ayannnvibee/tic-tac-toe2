import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the intro has been shown. This one flag is the only
/// thing the app saves on the device; scores and levels never are.
abstract class OnboardingStore {
  Future<bool> hasSeenIntro();

  Future<void> markIntroSeen();
}

/// [OnboardingStore] backed by shared_preferences. If the device storage
/// cannot be read the intro is treated as seen, so a failure never traps the
/// player in it.
class SharedPrefsOnboardingStore implements OnboardingStore {
  const SharedPrefsOnboardingStore();

  static const String _key = 'intro_seen';

  @override
  Future<bool> hasSeenIntro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (error) {
      debugPrint('Could not read the intro flag: $error');
      return true;
    }
  }

  @override
  Future<void> markIntroSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (error) {
      debugPrint('Could not save the intro flag: $error');
      // Shown again next launch; nothing else is affected.
    }
  }
}

/// Tests override this with a fake.
final onboardingStoreProvider = Provider<OnboardingStore>(
  (ref) => const SharedPrefsOnboardingStore(),
);
