import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/cache_manager.dart';

class ExchangeRateService {
  // API gratuite ouverte (pas besoin de clé API)
  static const String _baseUrl = 'https://open.er-api.com/v6/latest';

  final CacheManager _cacheManager = CacheManager();

  /// Taux de secours (approximatifs) utilisés si l'API est inaccessible
  static const Map<String, Map<String, double>> _fallbackRates = {
    'TND': {
      'EUR': 0.294,
      'USD': 0.347,
      'GBP': 0.256,
      'MAD': 3.197,
      'DZD': 45.83,
      'SAR': 1.302,
      'AED': 1.276,
      'JPY': 50.25,
      'CNY': 2.526,
      'INR': 29.43,
      'CHF': 0.286,
      'CAD': 0.484,
      'AUD': 0.541,
      'TRY': 13.33,
      'TND': 1.0,
    },
    'EUR': {
      'USD': 1.18,
      'GBP': 0.87,
      'TND': 3.40,
      'MAD': 10.87,
      'DZD': 155.8,
      'SAR': 4.43,
      'AED': 4.34,
      'JPY': 170.8,
      'CNY': 8.59,
      'INR': 100.0,
      'CHF': 0.97,
      'CAD': 1.65,
      'AUD': 1.84,
      'TRY': 45.3,
      'EUR': 1.0,
    },
    'USD': {
      'EUR': 0.85,
      'GBP': 0.74,
      'TND': 2.88,
      'MAD': 9.20,
      'DZD': 131.9,
      'SAR': 3.75,
      'AED': 3.67,
      'JPY': 144.6,
      'CNY': 7.27,
      'INR': 84.6,
      'CHF': 0.82,
      'CAD': 1.39,
      'AUD': 1.56,
      'TRY': 38.4,
      'USD': 1.0,
    },
  };

  /// Récupère les taux de change avec stratégie de cache intelligent
  /// Si la dernière requête date de moins de 10 minutes, utilise le cache
  Future<Map<String, double>> getRatesSmart(String baseCurrency) async {
    // Vérifier le cache
    final cachedRates = _cacheManager.getCachedRates(baseCurrency);
    if (cachedRates != null) {
      return cachedRates;
    }

    // Sinon, appel API
    try {
      final rates = await _fetchRatesFromAPI(baseCurrency);
      _cacheManager.cacheRates(baseCurrency, rates);
      return rates;
    } catch (e) {
      print('[EXCHANGE] API failed: $e');
      // Si l'API échoue, essayer le cache expiré
      final expiredCache = _cacheManager.getCachedRates(
        baseCurrency,
        ignoreExpiry: true,
      );
      if (expiredCache != null) return expiredCache;

      // Dernier recours : taux de secours hardcodés
      final fallback = _fallbackRates[baseCurrency.toUpperCase()];
      if (fallback != null) {
        print('[EXCHANGE] Using fallback rates for $baseCurrency');
        return fallback;
      }
      rethrow;
    }
  }

  /// Appel API pour récupérer les taux de change
  Future<Map<String, double>> _fetchRatesFromAPI(String baseCurrency) async {
    final url = '$_baseUrl/${baseCurrency.toUpperCase()}';
    print('[EXCHANGE] Fetching: $url');
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['result'] == 'success') {
        final rates = data['rates'] as Map<String, dynamic>;
        return rates.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
      }
      throw Exception('API Error: ${data['error-type'] ?? 'Unknown'}');
    }
    throw Exception('HTTP Error: ${response.statusCode}');
  }

  /// Convertit un montant d'une devise source vers une devise cible
  Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    print('[EXCHANGE] convertCurrency: $amount $fromCurrency → $toCurrency');
    if (fromCurrency == toCurrency) return amount;

    final rates = await getRatesSmart(fromCurrency);
    print('[EXCHANGE] Got ${rates.length} rates for $fromCurrency');
    final rate = rates[toCurrency.toUpperCase()];
    print('[EXCHANGE] Rate $fromCurrency → $toCurrency = $rate');

    if (rate == null) {
      throw Exception('Taux de change non disponible pour $toCurrency');
    }

    return amount * rate;
  }

  /// Convertit un montant vers plusieurs devises à la fois
  Future<Map<String, double>> convertToMultipleCurrencies({
    required double amount,
    required String fromCurrency,
    required List<String> toCurrencies,
  }) async {
    final rates = await getRatesSmart(fromCurrency);
    final Map<String, double> results = {};

    for (final currency in toCurrencies) {
      final rate = rates[currency.toUpperCase()];
      if (rate != null) {
        results[currency] = double.parse((amount * rate).toStringAsFixed(2));
      }
    }

    return results;
  }

  /// Liste des devises communes pour l'UI
  static List<Map<String, String>> get commonCurrencies => [
    {'code': 'USD', 'name': 'Dollar US', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'Livre Sterling', 'symbol': '£'},
    {'code': 'TND', 'name': 'Dinar Tunisien', 'symbol': 'TND'},
    {'code': 'MAD', 'name': 'Dirham Marocain', 'symbol': 'MAD'},
    {'code': 'DZD', 'name': 'Dinar Algérien', 'symbol': 'DZD'},
    {'code': 'SAR', 'name': 'Riyal Saoudien', 'symbol': 'SAR'},
    {'code': 'AED', 'name': 'Dirham Émirati', 'symbol': 'AED'},
    {'code': 'JPY', 'name': 'Yen Japonais', 'symbol': '¥'},
    {'code': 'CNY', 'name': 'Yuan Chinois', 'symbol': '¥'},
    {'code': 'INR', 'name': 'Roupie Indienne', 'symbol': '₹'},
    {'code': 'CHF', 'name': 'Franc Suisse', 'symbol': 'CHF'},
    {'code': 'CAD', 'name': 'Dollar Canadien', 'symbol': 'CA\$'},
    {'code': 'AUD', 'name': 'Dollar Australien', 'symbol': 'AU\$'},
    {'code': 'TRY', 'name': 'Livre Turque', 'symbol': '₺'},
  ];
}
