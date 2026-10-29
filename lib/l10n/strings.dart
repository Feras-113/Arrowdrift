import 'package:flutter/widgets.dart';

/// Tiny in-code localisation (English + Arabic). Arabic gets RTL layout from
/// the Flutter localisation delegates registered in app.dart.
class S {
  S._(this._m);

  final Map<String, String> _m;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  static S of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return S._(code == 'ar' ? _ar : _en);
  }

  String _t(String key) => _m[key] ?? _en[key] ?? key;

  String get appName => 'Arrowdrift';
  String get play => _t('play');
  String get levels => _t('levels');
  String get settings => _t('settings');
  String get level => _t('level');
  String get tapHint => _t('tapHint');
  String get easy => _t('easy');
  String get medium => _t('medium');
  String get hard => _t('hard');
  String get expert => _t('expert');
  String get hint => _t('hint');
  String get undo => _t('undo');
  String get skip => _t('skip');
  String get retry => _t('retry');
  String get next => _t('next');
  String get home => _t('home');
  String get levelClear => _t('levelClear');
  String get outOfHearts => _t('outOfHearts');
  String get outOfHeartsBody => _t('outOfHeartsBody');
  String get revive => _t('revive');
  String get watchAd => _t('watchAd');
  String get adNotReady => _t('adNotReady');
  String get notEnoughCoins => _t('notEnoughCoins');
  String get getMore => _t('getMore');
  String get freeWithAd => _t('freeWithAd');
  String get buyWithCoins => _t('buyWithCoins');
  String get cancel => _t('cancel');
  String get skipTitle => _t('skipTitle');
  String get skipBody => _t('skipBody');
  String get sound => _t('sound');
  String get haptics => _t('haptics');
  String get themes => _t('themes');
  String get owned => _t('owned');
  String get selected => _t('selected');
  String get resetProgress => _t('resetProgress');
  String get resetBody => _t('resetBody');
  String get reset => _t('reset');
  String get adPrivacy => _t('adPrivacy');
  String get about => _t('about');
  String get noMoves => _t('noMoves');
  String get blocked => _t('blocked');
  String get stars => _t('stars');
  String get continueLabel => _t('continueLabel');
  String get allDone => _t('allDone');
  String get coinsEarned => _t('coinsEarned');

  static const Map<String, String> _en = <String, String>{
    'play': 'PLAY',
    'levels': 'Levels',
    'settings': 'Settings',
    'level': 'Level',
    'tapHint': 'Tap an arrow to slide it out. Blocked arrows cost a heart.',
    'easy': 'Easy',
    'medium': 'Medium',
    'hard': 'Hard',
    'expert': 'Expert',
    'hint': 'Hint',
    'undo': 'Undo',
    'skip': 'Skip',
    'retry': 'Retry',
    'next': 'Next level',
    'home': 'Home',
    'levelClear': 'Level clear!',
    'outOfHearts': 'Out of hearts',
    'outOfHeartsBody': 'Watch a short ad to keep going, or try again.',
    'revive': 'Revive',
    'watchAd': 'Watch ad',
    'adNotReady': 'No ad available right now. Try again in a moment.',
    'notEnoughCoins': 'Not enough coins.',
    'getMore': 'Get more',
    'freeWithAd': 'Free – watch an ad',
    'buyWithCoins': 'Buy with coins',
    'cancel': 'Cancel',
    'skipTitle': 'Skip this level?',
    'skipBody': 'You will move on to the next level without completing it.',
    'sound': 'Sound',
    'haptics': 'Vibration',
    'themes': 'Themes',
    'owned': 'Owned',
    'selected': 'Selected',
    'resetProgress': 'Reset progress',
    'resetBody': 'This deletes your levels, coins and items. This cannot be undone.',
    'reset': 'Reset',
    'adPrivacy': 'Ad privacy settings',
    'about': 'Arrowdrift • v1.0',
    'noMoves': 'No move available',
    'blocked': 'Blocked!',
    'stars': 'Stars',
    'continueLabel': 'Continue',
    'allDone': 'You cleared every level. Legend!',
    'coinsEarned': 'Coins earned',
  };

  static const Map<String, String> _ar = <String, String>{
    'play': 'العب',
    'levels': 'المراحل',
    'settings': 'الإعدادات',
    'level': 'المرحلة',
    'tapHint': 'اضغط على السهم ليخرج من اللوحة. السهم المسدود يكلّفك قلباً.',
    'easy': 'سهل',
    'medium': 'متوسط',
    'hard': 'صعب',
    'expert': 'خبير',
    'hint': 'تلميح',
    'undo': 'تراجع',
    'skip': 'تخطي',
    'retry': 'إعادة',
    'next': 'المرحلة التالية',
    'home': 'الرئيسية',
    'levelClear': 'أحسنت!',
    'outOfHearts': 'انتهت القلوب',
    'outOfHeartsBody': 'شاهد إعلاناً قصيراً لتكمل، أو حاول من جديد.',
    'revive': 'إحياء',
    'watchAd': 'شاهد إعلاناً',
    'adNotReady': 'لا يوجد إعلان متاح الآن. حاول بعد قليل.',
    'notEnoughCoins': 'عملاتك غير كافية.',
    'getMore': 'احصل على المزيد',
    'freeWithAd': 'مجاناً – شاهد إعلاناً',
    'buyWithCoins': 'اشترِ بالعملات',
    'cancel': 'إلغاء',
    'skipTitle': 'تخطي هذه المرحلة؟',
    'skipBody': 'ستنتقل للمرحلة التالية دون إكمال هذه.',
    'sound': 'الصوت',
    'haptics': 'الاهتزاز',
    'themes': 'السمات',
    'owned': 'مملوك',
    'selected': 'محدد',
    'resetProgress': 'مسح التقدم',
    'resetBody': 'سيتم حذف مراحلك وعملاتك وأدواتك. لا يمكن التراجع.',
    'reset': 'مسح',
    'adPrivacy': 'خصوصية الإعلانات',
    'about': 'Arrowdrift • الإصدار 1.0',
    'noMoves': 'لا توجد حركة متاحة',
    'blocked': 'مسدود!',
    'stars': 'النجوم',
    'continueLabel': 'متابعة',
    'allDone': 'أنهيت كل المراحل. أسطورة!',
    'coinsEarned': 'العملات المكتسبة',
  };
}
