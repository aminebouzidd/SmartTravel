import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

class LanguageService {
  final LanguageIdentifier _languageIdentifier = LanguageIdentifier(
    confidenceThreshold: 0.2,
  );

  /// Détecte la langue principale du texte
  Future<String> identifyLanguage(String text) async {
    if (text.trim().isEmpty) return 'und';
    try {
      final language = await _languageIdentifier.identifyLanguage(text);
      return language;
    } catch (e) {
      return 'und'; // undetermined
    }
  }

  /// Détecte toutes les langues possibles avec leur confiance
  Future<List<IdentifiedLanguage>> identifyPossibleLanguages(
    String text,
  ) async {
    if (text.trim().isEmpty) return [];
    try {
      return await _languageIdentifier.identifyPossibleLanguages(text);
    } catch (e) {
      return [];
    }
  }

  /// Retourne le nom lisible de la langue à partir du code BCP-47
  static String getLanguageName(String code) {
    const languageNames = {
      'af': 'Afrikaans',
      'ar': 'Arabe',
      'be': 'Biélorusse',
      'bg': 'Bulgare',
      'bn': 'Bengali',
      'ca': 'Catalan',
      'cs': 'Tchèque',
      'cy': 'Gallois',
      'da': 'Danois',
      'de': 'Allemand',
      'el': 'Grec',
      'en': 'Anglais',
      'eo': 'Espéranto',
      'es': 'Espagnol',
      'et': 'Estonien',
      'fa': 'Persan',
      'fi': 'Finnois',
      'fr': 'Français',
      'ga': 'Irlandais',
      'gl': 'Galicien',
      'gu': 'Gujarati',
      'he': 'Hébreu',
      'hi': 'Hindi',
      'hr': 'Croate',
      'ht': 'Créole',
      'hu': 'Hongrois',
      'id': 'Indonésien',
      'is': 'Islandais',
      'it': 'Italien',
      'ja': 'Japonais',
      'ka': 'Géorgien',
      'kn': 'Kannada',
      'ko': 'Coréen',
      'lt': 'Lituanien',
      'lv': 'Letton',
      'mk': 'Macédonien',
      'mr': 'Marathi',
      'ms': 'Malais',
      'mt': 'Maltais',
      'nl': 'Néerlandais',
      'no': 'Norvégien',
      'pl': 'Polonais',
      'pt': 'Portugais',
      'ro': 'Roumain',
      'ru': 'Russe',
      'sk': 'Slovaque',
      'sl': 'Slovène',
      'sq': 'Albanais',
      'sr': 'Serbe',
      'sv': 'Suédois',
      'sw': 'Swahili',
      'ta': 'Tamoul',
      'te': 'Telugu',
      'th': 'Thaï',
      'tl': 'Tagalog',
      'tr': 'Turc',
      'uk': 'Ukrainien',
      'ur': 'Ourdou',
      'vi': 'Vietnamien',
      'zh': 'Chinois',
      'und': 'Indéterminé',
    };
    return languageNames[code] ?? code.toUpperCase();
  }

  void dispose() {
    _languageIdentifier.close();
  }
}
