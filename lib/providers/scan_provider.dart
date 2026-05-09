import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_result.dart';
import '../services/ocr_service.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';
import '../services/entity_service.dart';
import '../services/exchange_rate_service.dart';
import '../database/history_db.dart';
import 'settings_provider.dart';

/// Providers pour les services
final ocrServiceProvider = Provider<OcrService>((ref) => OcrService());
final languageServiceProvider = Provider<LanguageService>(
  (ref) => LanguageService(),
);
final translationServiceProvider = Provider<TranslationService>(
  (ref) => TranslationService(),
);
final entityServiceProvider = Provider<EntityService>((ref) => EntityService());
final exchangeRateServiceProvider = Provider<ExchangeRateService>(
  (ref) => ExchangeRateService(),
);
final historyDbProvider = Provider<HistoryDb>((ref) => HistoryDb());

/// État du scan
enum ScanStatus {
  idle,
  scanning,
  processing,
  translating,
  extracting,
  converting,
  done,
  error,
}

class ScanState {
  final ScanStatus status;
  final String? imagePath;
  final String extractedText;
  final String detectedLanguage;
  final String translatedText;
  final Map<String, dynamic> entities;
  final Map<String, double> convertedCurrency;
  final String? errorMessage;
  final ScanResult? result;

  const ScanState({
    this.status = ScanStatus.idle,
    this.imagePath,
    this.extractedText = '',
    this.detectedLanguage = '',
    this.translatedText = '',
    this.entities = const {},
    this.convertedCurrency = const {},
    this.errorMessage,
    this.result,
  });

  ScanState copyWith({
    ScanStatus? status,
    String? imagePath,
    String? extractedText,
    String? detectedLanguage,
    String? translatedText,
    Map<String, dynamic>? entities,
    Map<String, double>? convertedCurrency,
    String? errorMessage,
    ScanResult? result,
  }) {
    return ScanState(
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      extractedText: extractedText ?? this.extractedText,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      translatedText: translatedText ?? this.translatedText,
      entities: entities ?? this.entities,
      convertedCurrency: convertedCurrency ?? this.convertedCurrency,
      errorMessage: errorMessage,
      result: result ?? this.result,
    );
  }

  String get statusLabel {
    switch (status) {
      case ScanStatus.idle:
        return 'Prêt';
      case ScanStatus.scanning:
        return 'Scan en cours...';
      case ScanStatus.processing:
        return 'Extraction du texte...';
      case ScanStatus.translating:
        return 'Traduction...';
      case ScanStatus.extracting:
        return 'Extraction des entités...';
      case ScanStatus.converting:
        return 'Conversion des devises...';
      case ScanStatus.done:
        return 'Terminé';
      case ScanStatus.error:
        return 'Erreur';
    }
  }
}

/// Notifier pour le pipeline de scan complet
class ScanNotifier extends StateNotifier<ScanState> {
  final OcrService _ocrService;
  final LanguageService _languageService;
  final TranslationService _translationService;
  final EntityService _entityService;
  final ExchangeRateService _exchangeRateService;
  final HistoryDb _historyDb;
  final Ref _ref;

  ScanNotifier(
    this._ocrService,
    this._languageService,
    this._translationService,
    this._entityService,
    this._exchangeRateService,
    this._historyDb,
    this._ref,
  ) : super(const ScanState());

  /// Pipeline complet : Image → OCR → Language Detection → Translation → Entity Extraction → Price Conversion
  Future<void> processImage(String imagePath) async {
    try {
      // Étape 1 : OCR
      state = state.copyWith(
        status: ScanStatus.processing,
        imagePath: imagePath,
      );
      final text = await _ocrService.extractTextFromImage(imagePath);

      if (text.trim().isEmpty) {
        state = state.copyWith(
          status: ScanStatus.error,
          errorMessage: 'Aucun texte détecté dans l\'image',
        );
        return;
      }
      state = state.copyWith(extractedText: text);

      // Étape 2 : Détection de langue
      final language = await _languageService.identifyLanguage(text);
      state = state.copyWith(detectedLanguage: language);

      // Étape 3 : Traduction
      state = state.copyWith(status: ScanStatus.translating);
      final settings = _ref.read(appSettingsProvider);
      // Normalize whitespace before translating: collapse newlines/tabs
      // so ML Kit sees the full sentence as one unit (prevents tokenization errors)
      final textForTranslation = text.trim().replaceAll(RegExp(r'\s+'), ' ');
      final translated = await _translationService.translate(
        text: textForTranslation,
        sourceLang: language,
        targetLang: settings.targetTranslationLang,
      );
      state = state.copyWith(translatedText: translated);

      // Étape 4 : Extraction des entités (dates, phones, etc. – pas les prix)
      state = state.copyWith(status: ScanStatus.extracting);
      final entities = await _entityService.extractEntities(
        text,
        assumedCurrency: settings.sourceCurrency,
      );
      state = state.copyWith(entities: entities);

      // Étape 5 : Conversion des devises (approche aveugle)
      // On ignore toute indication de devise dans le texte OCR.
      // Tous les nombres détectés sont supposés être en sourceCurrency.
      state = state.copyWith(status: ScanStatus.converting);
      final Map<String, double> convertedCurrency = {};
      final sourceCurrency = settings.sourceCurrency;
      final targetCurrency = settings.targetCurrency;

      final blindItems = EntityService.extractAmountsBlind(
        text,
        sourceCurrency,
      );
      print('[PIPELINE] Blind items: $blindItems');

      if (blindItems.isNotEmpty && sourceCurrency != targetCurrency) {
        // Fetch rates once for all conversions
        Map<String, double>? rates;
        try {
          rates = await _exchangeRateService.getRatesSmart(sourceCurrency);
        } catch (e) {
          print('[PIPELINE] Rate fetch failed: $e');
        }
        final rate = rates?[targetCurrency];
        print('[PIPELINE] Rate $sourceCurrency→$targetCurrency = $rate');

        for (final item in blindItems) {
          final sepIdx = item.indexOf('||');
          if (sepIdx < 0) continue;
          final amountStr = item.substring(sepIdx + 2).trim();
          final amount = double.tryParse(amountStr);
          if (amount == null || amount <= 0) continue;

          // Key is always the source amount string (no labels)
          String uniqueKey = '${amount.toStringAsFixed(3)} $sourceCurrency';
          int n = 2;
          while (convertedCurrency.containsKey(uniqueKey)) {
            uniqueKey = '${amount.toStringAsFixed(3)} $sourceCurrency ($n)';
            n++;
          }

          convertedCurrency[uniqueKey] = rate != null
              ? double.parse((amount * rate).toStringAsFixed(2))
              : amount;
        }
      } else if (blindItems.isNotEmpty) {
        // Source == target, just show amounts as-is
        for (final item in blindItems) {
          final sepIdx = item.indexOf('||');
          if (sepIdx < 0) continue;
          final amountStr = item.substring(sepIdx + 2).trim();
          final amount = double.tryParse(amountStr);
          if (amount == null || amount <= 0) continue;
          String uniqueKey = '${amount.toStringAsFixed(3)} $sourceCurrency';
          int n = 2;
          while (convertedCurrency.containsKey(uniqueKey)) {
            uniqueKey = '${amount.toStringAsFixed(3)} $sourceCurrency ($n)';
            n++;
          }
          convertedCurrency[uniqueKey] = amount;
        }
      }
      print('[PIPELINE] Final convertedCurrency: $convertedCurrency');
      state = state.copyWith(convertedCurrency: convertedCurrency);

      // Créer le résultat final
      final result = ScanResult(
        extractedText: text,
        detectedLanguage: language,
        translatedText: translated,
        targetLanguage: settings.targetTranslationLang,
        entities: entities,
        convertedCurrency: convertedCurrency,
      );

      // Sauvegarder dans l'historique
      final id = await _historyDb.insertScan(result);
      final savedResult = result.copyWith(id: id);

      state = state.copyWith(status: ScanStatus.done, result: savedResult);
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const ScanState();
  }
}

/// Provider principal pour le scan
final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier(
    ref.watch(ocrServiceProvider),
    ref.watch(languageServiceProvider),
    ref.watch(translationServiceProvider),
    ref.watch(entityServiceProvider),
    ref.watch(exchangeRateServiceProvider),
    ref.watch(historyDbProvider),
    ref,
  );
});

/// Provider pour l'historique
final historyProvider = FutureProvider<List<ScanResult>>((ref) async {
  final db = ref.watch(historyDbProvider);
  return db.getAllScans();
});
