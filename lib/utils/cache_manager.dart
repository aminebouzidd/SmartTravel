/// CacheManager - Stratégie hybride intelligente pour l'API ExchangeRate
/// Règle : si dernière requête < 10 minutes → cache local, sinon → nouvel appel API
class CacheManager {
  // Singleton
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // Cache par devise de base
  final Map<String, _CachedData> _ratesCache = {};

  // Durée de validité du cache (10 minutes)
  static const Duration cacheValidity = Duration(minutes: 10);

  /// Récupère les taux en cache si valides (< 10 minutes)
  Map<String, double>? getCachedRates(
    String baseCurrency, {
    bool ignoreExpiry = false,
  }) {
    final key = baseCurrency.toUpperCase();
    final cached = _ratesCache[key];

    if (cached == null) return null;

    if (ignoreExpiry) return cached.rates;

    // Vérifier si le cache est encore valide
    if (DateTime.now().difference(cached.timestamp).inMinutes <
        cacheValidity.inMinutes) {
      return cached.rates;
    }

    return null; // Cache expiré
  }

  /// Met en cache les taux de change
  void cacheRates(String baseCurrency, Map<String, double> rates) {
    final key = baseCurrency.toUpperCase();
    _ratesCache[key] = _CachedData(rates: rates, timestamp: DateTime.now());
  }

  /// Vérifie si un cache est disponible et valide
  bool isCacheValid(String baseCurrency) {
    final key = baseCurrency.toUpperCase();
    final cached = _ratesCache[key];
    if (cached == null) return false;
    return DateTime.now().difference(cached.timestamp).inMinutes <
        cacheValidity.inMinutes;
  }

  /// Retourne le temps restant avant expiration du cache
  Duration? getTimeUntilExpiry(String baseCurrency) {
    final key = baseCurrency.toUpperCase();
    final cached = _ratesCache[key];
    if (cached == null) return null;

    final elapsed = DateTime.now().difference(cached.timestamp);
    final remaining = cacheValidity - elapsed;
    return remaining.isNegative ? null : remaining;
  }

  /// Vide tout le cache
  void clearCache() {
    _ratesCache.clear();
  }
}

class _CachedData {
  final Map<String, double> rates;
  final DateTime timestamp;

  _CachedData({required this.rates, required this.timestamp});
}
