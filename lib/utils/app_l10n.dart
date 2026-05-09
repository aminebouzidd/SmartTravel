/// Simple localization helper — no extra packages needed.
/// Usage: AppL10n.of(context).scanTitle
class AppL10n {
  final String _lang;
  const AppL10n._(this._lang);

  /// Resolve from the current Locale embedded in BuildContext.
  static AppL10n of(context) {
    // context is unused — lang is passed directly via provider
    return const AppL10n._('fr');
  }

  static AppL10n forLang(String lang) => AppL10n._(lang);

  // ─── Shared ─────────────────────────────────────────────────────────────

  String get appName =>
      _t(fr: 'Smart Travel', en: 'Smart Travel', ar: 'سمارت ترافل');

  // ─── Home ────────────────────────────────────────────────────────────────

  String get homeTagline => _t(
    fr: 'Scannez menus, panneaux et tickets.\nTraduction et devises automatiques.',
    en: 'Scan menus, signs and tickets.\nAutomatic translation & currency.',
    ar: 'امسح القوائم والإشارات والتذاكر.\nترجمة وعملات تلقائية.',
  );
  String get fieldIntelligence => _t(
    fr: 'Field Intelligence',
    en: 'Field Intelligence',
    ar: 'مساعد ميداني',
  );
  String get heroCTA => _t(
    fr: 'Votre assistant\nde voyage.',
    en: 'Your travel\nassistant.',
    ar: 'مساعدك\nفي الرحلة.',
  );
  String get offlineLabel => _t(
    fr: 'Fonctionne hors-ligne · ML on-device',
    en: 'Works offline · On-device ML',
    ar: 'يعمل بدون إنترنت · ML محلي',
  );

  // Tiles
  String get tileCurrency =>
      _t(fr: 'Change\nde devise', en: 'Currency\nexchange', ar: 'صرف\nالعملة');
  String get tileTranslate =>
      _t(fr: 'Traduire\ndu texte', en: 'Translate\ntext', ar: 'ترجمة\nالنص');
  String get tileHistory => _t(fr: 'Historique', en: 'History', ar: 'السجل');
  String get tileBudget => _t(fr: 'Budget', en: 'Budget', ar: 'الميزانية');

  // Bottom nav
  String get navHome => _t(fr: 'ACCUEIL', en: 'HOME', ar: 'الرئيسية');
  String get navScan => _t(fr: 'SCANNER', en: 'SCANNER', ar: 'مسح');
  String get navHistory => _t(fr: 'HISTORIQUE', en: 'HISTORY', ar: 'السجل');
  String get navSettings => _t(fr: 'RÉGLAGES', en: 'SETTINGS', ar: 'الإعدادات');

  // ─── Scan ────────────────────────────────────────────────────────────────

  String get scanTitle => _t(fr: 'SCANNER', en: 'SCANNER', ar: 'المسح');
  String get scanSubtitle => _t(
    fr: 'Photo ou galerie ci-dessous',
    en: 'Take a photo or pick from gallery',
    ar: 'التقط صورة أو اختر من المعرض',
  );
  String get scanNoImage =>
      _t(fr: 'Choisissez une image', en: 'Choose an image', ar: 'اختر صورة');
  String get scanCamera => _t(fr: 'CAMÉRA', en: 'CAMERA', ar: 'كاميرا');
  String get scanGallery => _t(fr: 'GALERIE', en: 'GALLERY', ar: 'المعرض');
  String get scanAnalyze =>
      _t(fr: 'ANALYSER L\'IMAGE', en: 'ANALYZE IMAGE', ar: 'تحليل الصورة');
  String get scanNoText => _t(
    fr: 'Aucun texte détecté dans l\'image',
    en: 'No text detected in the image',
    ar: 'لم يتم اكتشاف نص في الصورة',
  );

  // Pipeline steps
  String get stepOcr => _t(fr: 'OCR', en: 'OCR', ar: 'OCR');
  String get stepTranslation =>
      _t(fr: 'TRADUCTION', en: 'TRANSLATION', ar: 'ترجمة');
  String get stepEntities => _t(fr: 'ENTITÉS', en: 'ENTITIES', ar: 'كيانات');
  String get stepCurrency => _t(fr: 'DEVISES', en: 'CURRENCY', ar: 'عملة');

  // ─── Result ──────────────────────────────────────────────────────────────

  String get resultTitle => _t(fr: 'RÉSULTATS', en: 'RESULTS', ar: 'النتائج');
  String get resultOcrLabel =>
      _t(fr: 'TEXTE EXTRAIT', en: 'EXTRACTED TEXT', ar: 'النص المستخرج');
  String get resultTransLabel =>
      _t(fr: 'TRADUCTION', en: 'TRANSLATION', ar: 'الترجمة');
  String get resultEntitiesLabel => _t(
    fr: 'ENTITÉS DÉTECTÉES',
    en: 'DETECTED ENTITIES',
    ar: 'الكيانات المكتشفة',
  );
  String get resultCurrencyLabel => _t(
    fr: 'CONVERSION DES PRIX',
    en: 'PRICE CONVERSION',
    ar: 'تحويل الأسعار',
  );
  String get resultNoPrices => _t(
    fr: 'Aucun prix détecté dans ce document.',
    en: 'No prices detected in this document.',
    ar: 'لم يتم اكتشاف أسعار في هذا المستند.',
  );
  String get resultNewScan =>
      _t(fr: 'NOUVEAU SCAN', en: 'NEW SCAN', ar: 'مسح جديد');
  String get resultCopied => _t(
    fr: 'Copié dans le presse-papiers',
    en: 'Copied to clipboard',
    ar: 'تم النسخ',
  );

  // Entity labels
  String entityLabel(String key) {
    switch (key) {
      case 'dates':
        return _t(fr: 'Dates', en: 'Dates', ar: 'تواريخ');
      case 'addresses':
        return _t(fr: 'Adresses', en: 'Addresses', ar: 'عناوين');
      case 'phones':
        return _t(fr: 'Téléphones', en: 'Phones', ar: 'هواتف');
      case 'emails':
        return _t(fr: 'E-mails', en: 'Emails', ar: 'بريد');
      case 'urls':
        return _t(fr: 'Liens', en: 'Links', ar: 'روابط');
      case 'prices':
        return _t(fr: 'Prix', en: 'Prices', ar: 'أسعار');
      default:
        return key;
    }
  }

  // ─── History ─────────────────────────────────────────────────────────────

  String get historyTitle => _t(fr: 'HISTORIQUE', en: 'HISTORY', ar: 'السجل');
  String get historySearch =>
      _t(fr: 'Rechercher...', en: 'Search...', ar: 'بحث...');
  String get historyEmpty =>
      _t(fr: 'AUCUN RAPPORT', en: 'NO RECORDS', ar: 'لا سجلات');
  String get historyNoResults =>
      _t(fr: 'aucun résultat', en: 'no results', ar: 'لا نتائج');
  String get historyEmptySub => _t(
    fr: 'Vos scans apparaîtront ici.',
    en: 'Your scans will appear here.',
    ar: 'ستظهر عمليات المسح هنا.',
  );
  String reportsCount(int n) => _t(
    fr: '$n RAPPORT${n > 1 ? "S" : ""}',
    en: '$n RECORD${n > 1 ? "S" : ""}',
    ar: '$n سجل',
  );
  String timeAgoMin(int m) =>
      _t(fr: 'IL Y A $m MIN', en: '$m MIN AGO', ar: 'منذ $m د');
  String timeAgoHour(int h) =>
      _t(fr: 'IL Y A ${h}H', en: '${h}H AGO', ar: 'منذ ${h}س');
  String timeAgoDays(int d) =>
      _t(fr: 'IL Y A $d J', en: '$d DAYS AGO', ar: 'منذ $d أيام');

  // ─── Settings ────────────────────────────────────────────────────────────

  String get settingsTitle =>
      _t(fr: 'PARAMÈTRES', en: 'SETTINGS', ar: 'الإعدادات');
  String get settingsAppearance =>
      _t(fr: 'APPARENCE', en: 'APPEARANCE', ar: 'المظهر');
  String get settingsDarkMode =>
      _t(fr: 'Mode Sombre', en: 'Dark Mode', ar: 'الوضع الداكن');
  String get settingsEnabled => _t(fr: 'Activé', en: 'Enabled', ar: 'مفعّل');
  String get settingsDisabled =>
      _t(fr: 'Désactivé', en: 'Disabled', ar: 'معطّل');
  String get settingsDarkModeSub =>
      _t(fr: 'Thème sombre', en: 'Dark theme', ar: 'السمة الداكنة');
  String get settingsLanguage =>
      _t(fr: 'LANGUE APP', en: 'APP LANGUAGE', ar: 'لغة التطبيق');
  String get settingsTranslation =>
      _t(fr: 'TRADUCTION', en: 'TRANSLATION', ar: 'الترجمة');
  String get settingsTransLang =>
      _t(fr: 'Traduire vers', en: 'Translate to', ar: 'ترجمة إلى');
  String get settingsCurrency => _t(fr: 'DEVISE', en: 'CURRENCY', ar: 'العملة');
  String get settingsTranslateTo =>
      _t(fr: 'Traduire vers', en: 'Translate to', ar: 'ترجمة إلى');
  String get settingsConvertTo => _t(
    fr: 'Convertir les prix en',
    en: 'Convert prices to',
    ar: 'تحويل الأسعار إلى',
  );
  String get settingsConvertFrom => _t(
    fr: 'Devise du document scanné',
    en: 'Currency in scanned document',
    ar: 'عملة المستند',
  );
  String get settingsCurrencyLabel =>
      _t(fr: 'Convertir en', en: 'Convert to', ar: 'تحويل إلى');
  String get settingsNotifs =>
      _t(fr: 'NOTIFICATIONS', en: 'NOTIFICATIONS', ar: 'الإشعارات');
  String get settingsNotifsLabel =>
      _t(fr: 'Notifications', en: 'Notifications', ar: 'الإشعارات');
  String get settingsNotifsSub => _t(
    fr: 'Notifications push',
    en: 'Push notifications',
    ar: 'إشعارات فورية',
  );
  String get settingsSound => _t(fr: 'Sons', en: 'Sounds', ar: 'الأصوات');
  String get settingsSoundSub =>
      _t(fr: 'Sons de l\'interface', en: 'UI sounds', ar: 'أصوات الواجهة');
  String get settingsVibration =>
      _t(fr: 'Vibration', en: 'Vibration', ar: 'الاهتزاز');
  String get settingsVibrationSub =>
      _t(fr: 'Retour haptique', en: 'Haptic feedback', ar: 'استجابة لمسية');
  String get settingsAbout => _t(fr: 'À PROPOS', en: 'ABOUT', ar: 'حول');
  String get settingsAboutDesc => _t(
    fr: 'OCR, traduction et conversion de devises basés sur Google ML Kit.',
    en: 'OCR, translation and currency conversion powered by Google ML Kit.',
    ar: 'OCR والترجمة وتحويل العملات مدعوم بـ Google ML Kit.',
  );

  // ─── Internal helper ────────────────────────────────────────────────────

  String _t({required String fr, required String en, required String ar}) {
    switch (_lang) {
      case 'en':
        return en;
      case 'ar':
        return ar;
      default:
        return fr;
    }
  }
}
