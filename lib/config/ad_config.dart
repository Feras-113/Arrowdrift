/// AdMob configuration.
///
/// By default every ad unit is Google's official *test* unit, so the game is
/// always safe to run. For release builds pass your real ids at build time:
///
/// ```
/// flutter build appbundle --release \
///   --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXXX/1111111111 \
///   --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-XXXX/2222222222 \
///   --dart-define=ADMOB_REWARDED_ID=ca-app-pub-XXXX/3333333333
/// ```
///
/// and set your AdMob *app* id with `-PADMOB_APP_ID=ca-app-pub-XXXX~YYYY`
/// (or in `android/gradle.properties`). See README.md.
class AdConfig {
  const AdConfig._();

  static const String testBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const String testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static const String banner = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: testBanner,
  );
  static const String interstitial = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID',
    defaultValue: testInterstitial,
  );
  static const String rewarded = String.fromEnvironment(
    'ADMOB_REWARDED_ID',
    defaultValue: testRewarded,
  );

  /// Show a full-screen ad after every N completed levels...
  static const int interstitialEveryLevels = 3;

  /// ...but never more often than this.
  static const Duration interstitialCooldown = Duration(seconds: 90);

  /// No interstitials before the player has finished this many levels.
  static const int interstitialFirstLevel = 4;
}
