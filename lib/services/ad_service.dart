import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';
import 'progress.dart';

/// All AdMob logic: consent (UMP), banner support, interstitial pacing and
/// rewarded ads. Everything fails soft – the game never depends on an ad.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  /// True once the Mobile Ads SDK is initialised and ads may be requested.
  final ValueNotifier<bool> started = ValueNotifier<bool>(false);

  /// True while a rewarded ad is loaded and ready to show.
  final ValueNotifier<bool> rewardedReady = ValueNotifier<bool>(false);

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  DateTime _lastInterstitial = DateTime.fromMillisecondsSinceEpoch(0);
  int _interstitialAttempts = 0;
  int _rewardedAttempts = 0;
  bool _initStarted = false;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> init() async {
    if (_initStarted || !_supported) return;
    _initStarted = true;
    try {
      await _gatherConsent();
      if (await ConsentInformation.instance.canRequestAds()) {
        await _startSdk();
      }
    } catch (e) {
      debugPrint('AdService.init failed: $e');
    }
  }

  Future<void> _gatherConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null) debugPrint('Consent form: ${error.message}');
          if (!done.isCompleted) done.complete();
        });
      },
      (FormError error) {
        debugPrint('Consent info update: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {},
    );
  }

  Future<void> _startSdk() async {
    if (started.value) return;
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(maxAdContentRating: MaxAdContentRating.pg),
    );
    await MobileAds.instance.initialize();
    started.value = true;
    _loadInterstitial();
    _loadRewarded();
  }

  // ---- privacy options (required by Google UMP in some regions) ----------

  Future<bool> privacyOptionsRequired() async {
    if (!_supported) return false;
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  void showPrivacyOptions() {
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) debugPrint('Privacy options: ${error.message}');
      // The user may have just granted consent.
      _startSdkIfAllowed();
    });
  }

  Future<void> _startSdkIfAllowed() async {
    try {
      if (await ConsentInformation.instance.canRequestAds()) await _startSdk();
    } catch (_) {}
  }

  // ---- interstitial -------------------------------------------------------

  void _loadInterstitial() {
    if (!started.value) return;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          _interstitial = null;
          _retry(() => _interstitialAttempts++, _loadInterstitial,
              _interstitialAttempts);
        },
      ),
    );
  }

  /// Shows a full-screen ad if pacing rules allow it. Completes when the ad is
  /// closed (or immediately when nothing is shown).
  Future<void> maybeShowInterstitial(Progress progress, int levelNumber) async {
    final ad = _interstitial;
    if (ad == null || !started.value) return;
    if (levelNumber < AdConfig.interstitialFirstLevel) return;
    if (progress.levelsSinceAd < AdConfig.interstitialEveryLevels) return;
    if (DateTime.now().difference(_lastInterstitial) <
        AdConfig.interstitialCooldown) {
      return;
    }
    _interstitial = null;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
    );
    progress.levelsSinceAd = 0;
    _lastInterstitial = DateTime.now();
    await ad.show();
    await closed.future.timeout(const Duration(minutes: 2), onTimeout: () {});
    _loadInterstitial();
  }

  // ---- rewarded -----------------------------------------------------------

  void _loadRewarded() {
    if (!started.value) return;
    RewardedAd.load(
      adUnitId: AdConfig.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedAttempts = 0;
          rewardedReady.value = true;
        },
        onAdFailedToLoad: (error) {
          _rewarded = null;
          rewardedReady.value = false;
          _retry(() => _rewardedAttempts++, _loadRewarded, _rewardedAttempts);
        },
      ),
    );
  }

  /// Shows a rewarded ad. Returns true only when the user earned the reward.
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    rewardedReady.value = false;
    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!result.isCompleted) result.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewarded();
        if (!result.isCompleted) result.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (view, reward) => earned = true);
    return result.future.timeout(const Duration(minutes: 5), onTimeout: () => earned);
  }

  void _retry(VoidCallback bump, VoidCallback load, int attempts) {
    bump();
    if (attempts >= 5) return;
    final seconds = 5 * (1 << attempts);
    Timer(Duration(seconds: seconds), load);
  }
}
