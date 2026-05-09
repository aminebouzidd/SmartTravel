import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  final Map<String, OnDeviceTranslator> _translators = {};
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  /// Ensures the translation model for [lang] is downloaded.
  Future<bool> ensureModelDownloaded(TranslateLanguage lang) async {
    try {
      final tag = lang.bcpCode;
      final downloaded = await _modelManager.isModelDownloaded(tag);
      if (!downloaded) {
        print('[TRANSLATION] Downloading model for $tag...');
        final ok = await _modelManager.downloadModel(
          tag,
          isWifiRequired: false,
        );
        print('[TRANSLATION] Model $tag download result: $ok');
        return ok == 'downloaded';
      }
      return true;
    } catch (e) {
      print('[TRANSLATION] Model download error for ${lang.bcpCode}: $e');
      return false;
    }
  }

  /// Traduit le texte d'une langue source vers une langue cible
  /// sourceLang et targetLang sont des codes BCP-47 (ex: 'en', 'fr', 'ar')
  Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (text.trim().isEmpty) return '';
    if (sourceLang == targetLang) return text;
    if (sourceLang == 'und') {
      // Language undetermined — try translating from English as fallback
      sourceLang = 'en';
    }

    final key = '${sourceLang}_$targetLang';

    try {
      final sourceTranslateLanguage = _bcp47ToTranslateLanguage(sourceLang);
      final targetTranslateLanguage = _bcp47ToTranslateLanguage(targetLang);

      if (sourceTranslateLanguage == null || targetTranslateLanguage == null) {
        print('[TRANSLATION] Unsupported language: $sourceLang or $targetLang');
        return text;
      }

      // Download models if needed BEFORE creating translator
      await ensureModelDownloaded(sourceTranslateLanguage);
      await ensureModelDownloaded(targetTranslateLanguage);

      if (!_translators.containsKey(key)) {
        _translators[key] = OnDeviceTranslator(
          sourceLanguage: sourceTranslateLanguage,
          targetLanguage: targetTranslateLanguage,
        );
      }

      final result = await _translators[key]!.translateText(text);
      print('[TRANSLATION] $sourceLang→$targetLang OK (${text.length} chars)');
      return result;
    } catch (e) {
      print('[TRANSLATION] Error: $e');
      return text; // Return original on error
    }
  }

  /// Convertit un code BCP-47 en TranslateLanguage
  TranslateLanguage? _bcp47ToTranslateLanguage(String code) {
    final mapping = {
      'af': TranslateLanguage.afrikaans,
      'ar': TranslateLanguage.arabic,
      'be': TranslateLanguage.belarusian,
      'bg': TranslateLanguage.bulgarian,
      'bn': TranslateLanguage.bengali,
      'ca': TranslateLanguage.catalan,
      'cs': TranslateLanguage.czech,
      'cy': TranslateLanguage.welsh,
      'da': TranslateLanguage.danish,
      'de': TranslateLanguage.german,
      'el': TranslateLanguage.greek,
      'en': TranslateLanguage.english,
      'eo': TranslateLanguage.esperanto,
      'es': TranslateLanguage.spanish,
      'et': TranslateLanguage.estonian,
      'fa': TranslateLanguage.persian,
      'fi': TranslateLanguage.finnish,
      'fr': TranslateLanguage.french,
      'ga': TranslateLanguage.irish,
      'gl': TranslateLanguage.galician,
      'gu': TranslateLanguage.gujarati,
      'he': TranslateLanguage.hebrew,
      'hi': TranslateLanguage.hindi,
      'hr': TranslateLanguage.croatian,
      'hu': TranslateLanguage.hungarian,
      'id': TranslateLanguage.indonesian,
      'is': TranslateLanguage.icelandic,
      'it': TranslateLanguage.italian,
      'ja': TranslateLanguage.japanese,
      'ka': TranslateLanguage.georgian,
      'kn': TranslateLanguage.kannada,
      'ko': TranslateLanguage.korean,
      'lt': TranslateLanguage.lithuanian,
      'lv': TranslateLanguage.latvian,
      'mk': TranslateLanguage.macedonian,
      'mr': TranslateLanguage.marathi,
      'ms': TranslateLanguage.malay,
      'mt': TranslateLanguage.maltese,
      'nl': TranslateLanguage.dutch,
      'no': TranslateLanguage.norwegian,
      'pl': TranslateLanguage.polish,
      'pt': TranslateLanguage.portuguese,
      'ro': TranslateLanguage.romanian,
      'ru': TranslateLanguage.russian,
      'sk': TranslateLanguage.slovak,
      'sl': TranslateLanguage.slovenian,
      'sq': TranslateLanguage.albanian,
      'sv': TranslateLanguage.swedish,
      'sw': TranslateLanguage.swahili,
      'ta': TranslateLanguage.tamil,
      'te': TranslateLanguage.telugu,
      'th': TranslateLanguage.thai,
      'tl': TranslateLanguage.tagalog,
      'tr': TranslateLanguage.turkish,
      'uk': TranslateLanguage.ukrainian,
      'ur': TranslateLanguage.urdu,
      'vi': TranslateLanguage.vietnamese,
      'zh': TranslateLanguage.chinese,
    };
    return mapping[code];
  }

  /// Liste des langues cibles disponibles
  static List<Map<String, String>> get availableTargetLanguages => [
    {'code': 'fr', 'name': 'Français'},
    {'code': 'en', 'name': 'English'},
    {'code': 'ar', 'name': 'العربية'},
    {'code': 'es', 'name': 'Español'},
    {'code': 'de', 'name': 'Deutsch'},
    {'code': 'it', 'name': 'Italiano'},
    {'code': 'pt', 'name': 'Português'},
    {'code': 'tr', 'name': 'Türkçe'},
    {'code': 'zh', 'name': '中文'},
    {'code': 'ja', 'name': '日本語'},
    {'code': 'ko', 'name': '한국어'},
    {'code': 'ru', 'name': 'Русский'},
  ];

  void dispose() {
    for (final translator in _translators.values) {
      translator.close();
    }
    _translators.clear();
  }
}
