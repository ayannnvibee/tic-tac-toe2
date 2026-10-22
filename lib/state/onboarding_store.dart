import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the first-launch steps: which version of the Privacy Policy and
/// Terms of Use the player accepted, and whether the intro has been shown.
/// These are the only things the app saves on the device; scores and levels
/// never are.
abstract class OnboardingStore {
  Future<bool> hasSeenIntro();

  Future<void> markIntroSeen();

  /// The legal version the player accepted, or 0 if they never have.
  Future<int> acceptedLegalVersion();

  Future<void> acceptLegal(int version);
}

/// [OnboardingStore] backed by shared_preferences. If the device storage
/// cannot be read the intro is treated as seen, so a failure never traps the
/// player in it.
class SharedPrefsOnboardingStore implements OnboardingStore {
  const SharedPrefsOnboardingStore();

  static const String _key = 'intro_seen';
  static const String _legalKey = 'legal_accepted_version';

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

  @override
  Future<int> acceptedLegalVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_legalKey) ?? 0;
    } catch (error) {
      // Unreadable storage: ask again rather than assume consent.
      debugPrint('Could not read the consent flag: $error');
      return 0;
    }
  }

  @override
  Future<void> acceptLegal(int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_legalKey, version);
    } catch (error) {
      debugPrint('Could not save the consent flag: $error');
      // Asked again next launch.
    }
  }
}

/// Tests override this with a fake.
final onboardingStoreProvider = Provider<OnboardingStore>(
  (ref) => const SharedPrefsOnboardingStore(),
);
