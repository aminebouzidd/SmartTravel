import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/global_params.dart';
import '../services/notification_service.dart';
import '../utils/app_l10n.dart';

/// Provider pour SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

/// État des paramètres de l'application
class AppSettings {
  final bool isDarkMode;
  final String appLanguage; // 'fr', 'en', 'ar'
  final String targetTranslationLang; // Langue cible pour la traduction
  final String targetCurrency; // Devise cible par défaut
  final String sourceCurrency; // Devise source (celle scannée)
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final String userNom;
  final String userPrenom;

  const AppSettings({
    this.isDarkMode = false,
    this.appLanguage = 'fr',
    this.targetTranslationLang = 'fr',
    this.targetCurrency = 'EUR',
    this.sourceCurrency = 'TND',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.notificationsEnabled = true,
    this.userNom = '',
    this.userPrenom = '',
  });

  AppSettings copyWith({
    bool? isDarkMode,
    String? appLanguage,
    String? targetTranslationLang,
    String? targetCurrency,
    String? sourceCurrency,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    String? userNom,
    String? userPrenom,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      appLanguage: appLanguage ?? this.appLanguage,
      targetTranslationLang:
          targetTranslationLang ?? this.targetTranslationLang,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      sourceCurrency: sourceCurrency ?? this.sourceCurrency,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      userNom: userNom ?? this.userNom,
      userPrenom: userPrenom ?? this.userPrenom,
    );
  }
}

/// Notifier pour les paramètres
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  AppSettingsNotifier(this._prefs) : super(const AppSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    state = AppSettings(
      isDarkMode: _prefs.getBool('isDarkMode') ?? false,
      appLanguage: _prefs.getString('appLanguage') ?? 'fr',
      targetTranslationLang: _prefs.getString('targetTranslationLang') ?? 'fr',
      targetCurrency: _prefs.getString('targetCurrency') ?? 'EUR',
      sourceCurrency: _prefs.getString('sourceCurrency') ?? 'TND',
      soundEnabled: _prefs.getBool('soundEnabled') ?? true,
      vibrationEnabled: _prefs.getBool('vibrationEnabled') ?? true,
      notificationsEnabled: _prefs.getBool('notificationsEnabled') ?? true,
      userNom: _prefs.getString('userNom') ?? '',
      userPrenom: _prefs.getString('userPrenom') ?? '',
    );
  }

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool('isDarkMode', value);
    state = state.copyWith(isDarkMode: value);
    // Synchronise le mode dans Firebase Realtime Database
    final mode = value ? 'Nuit' : 'Jour';
    await FirebaseDatabase.instance.ref().child('mode').set(mode);
    // Notifier le ChangeNotifier GlobalParams
    GlobalParams.themeActuel.setMode(mode);
  }

  Future<void> setAppLanguage(String value) async {
    await _prefs.setString('appLanguage', value);
    state = state.copyWith(appLanguage: value);
  }

  Future<void> setTargetTranslationLang(String value) async {
    await _prefs.setString('targetTranslationLang', value);
    state = state.copyWith(targetTranslationLang: value);
  }

  Future<void> setTargetCurrency(String value) async {
    await _prefs.setString('targetCurrency', value);
    state = state.copyWith(targetCurrency: value);
  }

  Future<void> setSourceCurrency(String value) async {
    await _prefs.setString('sourceCurrency', value);
    state = state.copyWith(sourceCurrency: value);
  }

  Future<void> setSoundEnabled(bool value) async {
    await _prefs.setBool('soundEnabled', value);
    state = state.copyWith(soundEnabled: value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    await _prefs.setBool('vibrationEnabled', value);
    state = state.copyWith(vibrationEnabled: value);
  }

  /// Locale dérivée du paramètre de langue
  final appLocaleProvider = Provider<Locale>((ref) {
    final lang = ref.watch(appSettingsProvider).appLanguage;
    return Locale(lang);
  });

  /// AppL10n instance dérivée du paramètre de langue
  final appL10nProvider = Provider<AppL10n>((ref) {
    final lang = ref.watch(appSettingsProvider).appLanguage;
    return AppL10n.forLang(lang);
  });

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool('notificationsEnabled', value);
    state = state.copyWith(notificationsEnabled: value);
    // Programmer ou annuler la notification quotidienne selon le choix
    if (value) {
      await NotificationService.instance.requestPermission();
      await NotificationService.instance.scheduleDailyReminder();
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  Future<void> setUserName(String nom, String prenom) async {
    await _prefs.setString('userNom', nom);
    await _prefs.setString('userPrenom', prenom);
    state = state.copyWith(userNom: nom, userPrenom: prenom);
  }
}

/// Provider pour les paramètres de l'app
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return AppSettingsNotifier(prefs);
    });
