import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'google_ad_service.dart';

/// Full-screen ads. Ads are never essential: when one is not loaded (offline,
/// an error, no fill) every call returns at once and the game carries on.
abstract class AdService {
  /// Starts the ads SDK and loads the first ads. Safe to call more than once.
  Future<void> initialize();

  /// Whether a rewarded ad is loaded and can be shown right now.
  ValueListenable<bool> get rewardedReady;

  /// Shows an interstitial if one is loaded. Completes when it is closed, or
  /// at once when there is nothing to show.
  Future<void> showInterstitial();

  /// Shows a rewarded ad if one is loaded. Completes when it is closed, with
  /// true only if the player earned the reward.
  Future<bool> showRewarded();

  void dispose();
}

/// Tests override this with a fake.
final adServiceProvider = Provider<AdService>((ref) {
  final service = GoogleAdService();
  ref.onDispose(service.dispose);
  return service;
});
