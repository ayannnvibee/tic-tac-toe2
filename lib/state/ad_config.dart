/// Every AdMob ID the app uses, in one place.
///
/// These are Google's public TEST IDs: they always serve test ads and never
/// earn money. The app ID is repeated in android/app/src/main/AndroidManifest.xml.
///
/// TODO(release): replace all three (and the manifest app ID) with the IDs
/// from your own AdMob account before publishing.
abstract final class AdConfig {
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String interstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';

  /// An interstitial is shown after this many finished rounds.
  static const int roundsPerInterstitial = 4;

  /// How long to wait before trying again after an ad failed to load, for
  /// example while the phone is offline.
  static const Duration retryDelay = Duration(seconds: 30);
}
