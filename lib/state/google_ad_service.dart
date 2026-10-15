import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_service.dart';

/// [AdService] backed by Google Mobile Ads.
///
/// One interstitial and one rewarded ad are kept loaded. After an ad is shown
/// the next one is loaded straight away; after a failed load it tries again a
/// little later. Every failure is swallowed so the game never waits on ads.
class GoogleAdService implements AdService {
  final ValueNotifier<bool> _rewardedReady = ValueNotifier(false);

  Future<void>? _starting;
  bool _disposed = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;

  @override
  ValueListenable<bool> get rewardedReady => _rewardedReady;

  @override
  Future<void> initialize() => _starting ??= _start();

  Future<void> _start() async {
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      return;
    }
    _loadInterstitial();
    _loadRewarded();
  }

  void _retry(void Function() load) {
    Timer(AdConfig.retryDelay, () {
      if (!_disposed) load();
    });
  }

  void _loadInterstitial() {
    if (_disposed || _loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    try {
      InterstitialAd.load(
        adUnitId: AdConfig.interstitialUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loadingInterstitial = false;
            if (_disposed) {
              ad.dispose();
            } else {
              _interstitial = ad;
            }
          },
          onAdFailedToLoad: (_) {
            _loadingInterstitial = false;
            _retry(_loadInterstitial);
          },
        ),
      );
    } catch (_) {
      _loadingInterstitial = false;
    }
  }

  void _loadRewarded() {
    if (_disposed || _loadingRewarded || _rewarded != null) return;
    _loadingRewarded = true;
    try {
      RewardedAd.load(
        adUnitId: AdConfig.rewardedUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _loadingRewarded = false;
            if (_disposed) {
              ad.dispose();
            } else {
              _rewarded = ad;
              _rewardedReady.value = true;
            }
          },
          onAdFailedToLoad: (_) {
            _loadingRewarded = false;
            _retry(_loadRewarded);
          },
        ),
      );
    } catch (_) {
      _loadingRewarded = false;
    }
  }

  @override
  Future<void> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;

    final closed = Completer<void>();
    void finish() {
      ad.dispose();
      if (!closed.isCompleted) closed.complete();
      _loadInterstitial();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, _) => finish(),
    );
    try {
      await ad.show();
    } catch (_) {
      finish();
    }
    return closed.future;
  }

  @override
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewarded = null;
    _rewardedReady.value = false;

    var earned = false;
    final closed = Completer<bool>();
    void finish() {
      ad.dispose();
      if (!closed.isCompleted) closed.complete(earned);
      _loadRewarded();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, _) => finish(),
    );
    try {
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
    } catch (_) {
      finish();
    }
    return closed.future;
  }

  @override
  void dispose() {
    _disposed = true;
    _interstitial?.dispose();
    _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
    _rewardedReady.dispose();
  }
}
