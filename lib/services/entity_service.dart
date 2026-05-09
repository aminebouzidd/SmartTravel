import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';

class EntityService {
  EntityExtractor? _entityExtractor;

  /// Extrait les entités (prix, lieux, dates, etc.) d un texte.
  /// [assumedCurrency] : devise pour les prix sans symbole explicite.
  Future<Map<String, dynamic>> extractEntities(
    String text, {
    String assumedCurrency = 'TND',
  }) async {
    if (text.trim().isEmpty) return {};
    final normalizedText = _normalizeOcrText(text);
    print(
      '[ENTITY] Raw OCR (first 500 chars):\n${normalizedText.substring(0, normalizedText.length.clamp(0, 500))}',
    );

    _entityExtractor ??= EntityExtractor(
      language: EntityExtractorLanguage.english,
    );

    try {
      final List<EntityAnnotation> annotations = await _entityExtractor!
          .annotateText(normalizedText);

      final result = <String, dynamic>{};
      final List<String> prices = [];
      final List<String> dates = [];
      final List<String> addresses = [];
      final List<String> phones = [];
      final List<String> emails = [];
      final List<String> urls = [];

      for (final annotation in annotations) {
        for (final entity in annotation.entities) {
          switch (entity.type) {
            case EntityType.money:
              prices.add(annotation.text);
              break;
            case EntityType.dateTime:
              dates.add(annotation.text);
              break;
            case EntityType.address:
              addresses.add(annotation.text);
              break;
            case EntityType.phone:
              phones.add(annotation.text);
              break;
            case EntityType.email:
              emails.add(annotation.text);
              break;
            case EntityType.url:
              urls.add(annotation.text);
              break;
            default:
              break;
          }
        }
      }

      if (dates.isNotEmpty) result['dates'] = dates;
      if (addresses.isNotEmpty) result['addresses'] = addresses;
      if (phones.isNotEmpty) result['phones'] = phones;
      if (emails.isNotEmpty) result['emails'] = emails;
      if (urls.isNotEmpty) result['urls'] = urls;

      print('[ENTITY] ML Kit prices: $prices');

      final regexPrices = _extractPricesWithRegex(
        normalizedText,
        assumedCurrency,
      );
      print('[ENTITY] Regex prices: $regexPrices');

      final merged = <String>[...prices, ...regexPrices];
      final allPrices = _deduplicatePrices(merged, assumedCurrency);
      if (allPrices.isNotEmpty) result['prices'] = allPrices;
      print('[ENTITY] Final prices: ${result["prices"]}');

      // Extract labeled menu line items (item + price per line)
      final lineItems = _extractMenuLineItems(normalizedText, assumedCurrency);
      print('[ENTITY] Line items: $lineItems');
      if (lineItems.isNotEmpty) result['lineItems'] = lineItems;

      return result;
    } catch (e) {
      print('[ENTITY] ML Kit failed: $e - fallback regex');
      return _extractWithRegexOnly(normalizedText, assumedCurrency);
    }
  }

  // Normalise le texte OCR
  String _normalizeOcrText(String text) {
    return text
        .replaceAll('\u062f.\u062a', 'TND')
        .replaceAll('\u062f\u062a', 'TND')
        .replaceAll(RegExp(r'\bD\.?T\.?\b'), 'DT')
        .replaceAll(RegExp(r'\bD\.?H\.?\b'), 'DH')
        .replaceAllMapped(
          RegExp(r'(\d)\s+(\d)(?=\s*[.,\d])'),
          (m) => '${m[1]}${m[2]}',
        );
  }

  static const _currCode =
      r'(?:DT|TND|MAD|DH|DZD|DA|EUR|USD|GBP|SAR|AED|JPY|CNY|INR|CHF|CAD|AUD|TRY)';
  static const _currSymbol = r'[\$\u20AC\u00A3\u00A5\u20B9\u20BA]';

  List<String> _extractPricesWithRegex(String text, String assumedCurrency) {
    final prices = <String>[];

    // Symboles monetaires avant ou apres le montant
    final symAny = RegExp(
      r'(?:' +
          _currSymbol +
          r')\s*(\d[\d ]*(?:[.,]\d+)?)'
              r'|'
              r'(\d[\d ]*(?:[.,]\d+)?)\s*(?:' +
          _currSymbol +
          r')',
    );
    for (final m in symAny.allMatches(text)) {
      final raw = m.group(0)!.trim();
      if (_looksLikePrice(raw, assumedCurrency)) prices.add(raw);
    }

    // Montant + code devise
    final codeAfter = RegExp(
      r'(\d[\d ]*(?:[.,]\d{1,3})?)\s*(' + _currCode + r')\b',
      caseSensitive: false,
    );
    for (final m in codeAfter.allMatches(text)) {
      final raw = m.group(0)!.trim();
      if (_looksLikePrice(raw, assumedCurrency)) prices.add(raw);
    }

    // Code devise + montant
    final codeBefore = RegExp(
      r'\b(' + _currCode + r')\s*(\d[\d ]*(?:[.,]\d{1,3})?)',
      caseSensitive: false,
    );
    for (final m in codeBefore.allMatches(text)) {
      final raw = m.group(0)!.trim();
      if (_looksLikePrice(raw, assumedCurrency)) prices.add(raw);
    }

    // Prix nus en format menu (apres separateur visuel)
    // Ex: "Brick .............. 2.500"  "Pizza - 8.500"  "Cafe: 1,200"
    final bareMenuPrice = RegExp(
      r'(?:\.{2,}|[-=]{2,}|[:\-=])\s*'
      r'(\d{1,6}(?:[.,]\d{1,3}))',
      multiLine: true,
    );
    for (final m in bareMenuPrice.allMatches(text)) {
      final numStr = m.group(1)!.trim();
      final candidate = '$numStr $assumedCurrency';
      if (_looksLikePrice(candidate, assumedCurrency)) prices.add(candidate);
    }

    // Entier seul apres deux-points/tiret en fin de ligne
    final bareInt = RegExp(r'[:\-=]\s*(\d{1,5})\s*$', multiLine: true);
    for (final m in bareInt.allMatches(text)) {
      final numStr = m.group(1)!.trim();
      final v = int.tryParse(numStr) ?? 0;
      if (v < 1 || v > 9999) continue;
      final candidate = '$numStr $assumedCurrency';
      if (_looksLikePrice(candidate, assumedCurrency)) prices.add(candidate);
    }

    return prices;
  }

  bool _looksLikePrice(String s, String assumedCurrency) {
    if (!s.contains(RegExp(r'\d'))) return false;
    final p = parsePrice(s, assumedCurrency: assumedCurrency);
    return p != null && p.amount > 0;
  }

  static List<String> _deduplicatePrices(
    List<String> rawPrices,
    String assumedCurrency,
  ) {
    final seen = <String>{};
    final unique = <String>[];
    for (final p in rawPrices) {
      final parsed = parsePrice(p, assumedCurrency: assumedCurrency);
      if (parsed == null || parsed.amount <= 0) continue;
      final key = '${parsed.amount.toStringAsFixed(3)}|${parsed.currency}';
      if (seen.add(key)) unique.add(p);
    }
    return unique;
  }

  Map<String, dynamic> _extractWithRegexOnly(
    String text,
    String assumedCurrency,
  ) {
    final result = <String, dynamic>{};
    final rawPrices = _extractPricesWithRegex(text, assumedCurrency);
    final prices = _deduplicatePrices(rawPrices, assumedCurrency);
    if (prices.isNotEmpty) result['prices'] = prices;
    final lineItems = _extractMenuLineItems(text, assumedCurrency);
    if (lineItems.isNotEmpty) result['lineItems'] = lineItems;
    final datePattern = RegExp(r'\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}');
    final dateMatches = datePattern.allMatches(text);
    if (dateMatches.isNotEmpty) {
      result['dates'] = dateMatches.map((m) => m.group(0)!).toList();
    }
    return result;
  }

  /// Parses OCR lines for menu-style price patterns.
  /// Handles:
  ///  - "Item Name   12.000"          (price at line end)
  ///  - "Item Name   12.000   عربي"   (Arabic follows price on same line)
  ///  - "Item Name ..... 12.000"      (dot/dash separator)
  ///  - standalone "12.000" line      (associates with previous item label)
  /// Returns list of "Label||priceString" entries, NO deduplication.
  List<String> _extractMenuLineItems(String text, String assumedCurrency) {
    final items = <String>[];
    final lines = text.split(RegExp(r'\r?\n'));

    // Matches Maghreb 3-decimal number anywhere (the price)
    final priceInLine = RegExp(r'(\d{1,3}[.,]\d{3})');
    // Matches a standalone number-only line (just a price, possibly with Arabic)
    final standalonePriceLine = RegExp(
      r'^\s*(\d{1,3}[.,]\d{3})\s*[\u0600-\u06FF\s]*$',
    );
    // Matches item name on left, then price (with optional Arabic after)
    // Patterns: 2+ spaces, dots, or dash separators
    final inlinePrice = RegExp(
      r'^(.+?)(?:\s{2,}|\.{3,}|[-=]{3,})(\d{1,3}[.,]\d{3})',
    );

    String? pendingLabel;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Skip lines that are purely Arabic (right-column of bilingual menus)
      if (RegExp(r'^[\u0600-\u06FF\s\(\)]+$').hasMatch(line)) {
        continue;
      }

      // Try inline pattern: "Item Name   15.000" or "Item Name   15.000   Arabic"
      final inlineMatch = inlinePrice.firstMatch(line);
      if (inlineMatch != null) {
        final rawLabel = inlineMatch.group(1)!.trim();
        final priceNum = inlineMatch.group(2)!.trim();
        final label = _cleanMenuLabel(rawLabel);
        if (label != null) {
          final candidate = '$priceNum $assumedCurrency';
          final parsed = parsePrice(
            candidate,
            assumedCurrency: assumedCurrency,
          );
          if (parsed != null && parsed.amount > 0 && parsed.amount < 99999) {
            items.add('$label||$candidate');
            pendingLabel = null;
            continue;
          }
        }
      }

      // Try standalone price line: "15.000" or "15.000   عربي"
      final standaloneMatch = standalonePriceLine.firstMatch(line);
      if (standaloneMatch != null) {
        final priceNum = standaloneMatch.group(1)!.trim();
        final candidate = '$priceNum $assumedCurrency';
        final parsed = parsePrice(candidate, assumedCurrency: assumedCurrency);
        if (parsed != null && parsed.amount > 0 && parsed.amount < 99999) {
          final label = pendingLabel ?? _tryExtractLabelFromPrev(lines, i);
          if (label != null) {
            items.add('$label||$candidate');
          } else {
            items.add('||$candidate');
          }
          pendingLabel = null;
          continue;
        }
      }

      // This line has no price — check if it could be a menu item label
      // A label line: has letters, no price digits that look like amounts
      if (!priceInLine.hasMatch(line)) {
        final possible = _cleanMenuLabel(line);
        if (possible != null) pendingLabel = possible;
      } else {
        pendingLabel = null;
      }
    }

    return items;
  }

  /// Looks back in lines for the nearest non-empty French label line
  String? _tryExtractLabelFromPrev(List<String> lines, int idx) {
    for (int j = idx - 1; j >= 0 && j >= idx - 3; j--) {
      final prev = lines[j].trim();
      if (prev.isEmpty) continue;
      if (RegExp(r'^[\u0600-\u06FF\s\(\)]+$').hasMatch(prev)) continue;
      // Must start with a letter and not be a pure number line
      if (RegExp(r'^[A-Za-zÀ-ÿ]').hasMatch(prev)) {
        return _cleanMenuLabel(prev);
      }
    }
    return null;
  }

  /// Cleans a menu item label: removes trailing descriptions in parentheses,
  /// ignores lines that are just parenthetical descriptions.
  String? _cleanMenuLabel(String raw) {
    // Remove parenthetical descriptions: "(gin+jus de ...)"
    String cleaned = raw.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    // Remove punctuation at start/end
    cleaned = cleaned.replaceAll(RegExp(r'^[^A-Za-zÀ-ÿ]+'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]+$'), '').trim();
    if (cleaned.length < 2) return null;
    // Reject if the cleaned label is all numbers
    if (RegExp(r'^\d+$').hasMatch(cleaned)) return null;
    return cleaned;
  }

  static const Map<String, String> _currencyAliases = {
    'DT': 'TND',
    'TND': 'TND',
    'MAD': 'MAD',
    'DH': 'MAD',
    'DZD': 'DZD',
    'DA': 'DZD',
    'EUR': 'EUR',
    'USD': 'USD',
    'GBP': 'GBP',
    'SAR': 'SAR',
    'AED': 'AED',
    'JPY': 'JPY',
    'CNY': 'CNY',
    'INR': 'INR',
    'CHF': 'CHF',
    'CAD': 'CAD',
    'AUD': 'AUD',
    'TRY': 'TRY',
  };

  static ({double amount, String currency})? parsePrice(
    String priceStr, {
    String assumedCurrency = 'TND',
  }) {
    if (priceStr.contains('\n') || priceStr.contains('\r')) return null;
    final cleaned = priceStr.trim();
    if (cleaned.isEmpty) return null;

    const symbolMap = {
      '\$': 'USD',
      '\u20AC': 'EUR',
      '\u00A3': 'GBP',
      '\u00A5': 'JPY',
      '\u20B9': 'INR',
      '\u20BA': 'TRY',
    };

    for (final entry in symbolMap.entries) {
      if (cleaned.contains(entry.key)) {
        final numStr = cleaned
            .replaceAll(entry.key, '')
            .replaceAll(' ', '')
            .replaceAll(',', '.')
            .trim();
        final amount = double.tryParse(numStr);
        if (amount != null && amount > 0) {
          return (amount: amount, currency: entry.value);
        }
      }
    }

    // Montant + code devise
    final codeAfterPat = RegExp(
      r'^(\d[\d ]*(?:[.,]\d+)?)\s*(DT|TND|MAD|DH|DZD|DA|EUR|USD|GBP|SAR|AED|JPY|CNY|INR|CHF|CAD|AUD|TRY)\b',
      caseSensitive: false,
    );
    var m = codeAfterPat.firstMatch(cleaned);
    if (m != null) {
      final amount = _parseMaghrebNumber(m.group(1)!);
      final currency =
          _currencyAliases[m.group(2)!.toUpperCase()] ??
          m.group(2)!.toUpperCase();
      if (amount != null && amount > 0)
        return (amount: amount, currency: currency);
    }

    // Code devise + montant
    final codeBeforePat = RegExp(
      r'^(DT|TND|MAD|DH|DZD|DA|EUR|USD|GBP|SAR|AED|JPY|CNY|INR|CHF|CAD|AUD|TRY)\s*(\d[\d ]*(?:[.,]\d+)?)',
      caseSensitive: false,
    );
    m = codeBeforePat.firstMatch(cleaned);
    if (m != null) {
      final amount = _parseMaghrebNumber(m.group(2)!);
      final currency =
          _currencyAliases[m.group(1)!.toUpperCase()] ??
          m.group(1)!.toUpperCase();
      if (amount != null && amount > 0)
        return (amount: amount, currency: currency);
    }

    // Nombre seul sans devise
    final bareNumPat = RegExp(r'^(\d[\d ]*(?:[.,]\d+)?)$');
    final bm = bareNumPat.firstMatch(cleaned);
    if (bm != null) {
      final amount = _parseMaghrebNumber(bm.group(1)!);
      if (amount != null && amount > 0) {
        return (amount: amount, currency: assumedCurrency);
      }
    }

    return null;
  }

  static double? _parseMaghrebNumber(String raw) {
    String s = raw.replaceAll(' ', '');
    if (s.contains(',') && s.contains('.')) {
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s);
  }

  void dispose() {
    _entityExtractor?.close();
  }

  // ─── Blind Amount Extraction ──────────────────────────────────────────────
  /// Extracts monetary amounts from [text] WITHOUT reading currency markers.
  /// Every number found is treated as being in [sourceCurrency].
  /// Returns a list of "Label||amount" strings (one per detected amount).
  // Words that are section titles, not item labels
  static const _titleWords = {
    'MENU',
    'CARTE',
    'LIST',
    'LISTE',
    'PRIX',
    'PRICE',
    'PRICES',
    'BOISSONS',
    'DRINKS',
    'FOOD',
    'DESSERTS',
    'ENTREES',
    'PLATS',
  };

  static List<String> extractAmountsBlind(String text, String sourceCurrency) {
    // Strip currency symbols and codes so they don't confuse label detection
    final stripped = text
        .replaceAll(
          RegExp(
            r'\b(DT|TND|MAD|DH|DZD|DA|EUR|USD|GBP|SAR|AED|JPY|CNY|INR|CHF|CAD|AUD|TRY)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'[\$\u20AC\u00A3\u00A5\u20B9\u20BA]'), '');

    final results = <String>[];
    final lines = stripped.split(RegExp(r'\r?\n'));

    // Matches decimal prices: 1,000 / 15.000 / 8,50
    final amountPat = RegExp(r'(\d{1,6}[.,]\d{1,3})');
    final intPat = RegExp(r'^\s*(\d{1,5})\s*$');

    // Queue of candidate labels from consecutive label-only lines.
    // Used to pair labels with a later block of prices (e.g. OCR that groups
    // all prices on one concatenated line after the item names).
    final labelQueue = <String>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Skip Arabic-only lines (right column of bilingual menus)
      if (RegExp(r'^[\u0600-\u06FF\s\(\)]+$').hasMatch(line)) continue;

      // Skip filename-like noise (e.g. "r596-menu-24-7jpg")
      if (RegExp(r'^\w[\w\-]*\.\w{2,5}$').hasMatch(line)) continue;

      final amountMatches = amountPat.allMatches(line).toList();

      if (amountMatches.isEmpty) {
        // Could be a standalone integer line
        final intMatch = intPat.firstMatch(line);
        if (intMatch != null) {
          final v = int.tryParse(intMatch.group(1)!) ?? 0;
          if (v >= 1 && v <= 99999) {
            final label = labelQueue.isNotEmpty ? labelQueue.removeAt(0) : null;
            final amount = v.toDouble();
            results.add(label != null ? '$label||$amount' : '||$amount');
            continue;
          }
        }
        // No price — capture as potential label (skip section titles)
        final possible = _extractLabel(line);
        if (possible != null) labelQueue.add(possible);
        continue;
      }

      // This line has prices — collect all valid amounts
      final amounts = <double>[];
      for (final am in amountMatches) {
        final amount = _parseMaghrebNumber(am.group(1)!);
        if (amount != null && amount > 0 && amount < 9999) {
          amounts.add(amount);
        }
      }
      if (amounts.isEmpty) continue;

      if (amounts.length == 1) {
        // Single price on this line.
        // Try to extract label from text before the number (e.g. "EXPRESSE .... 1,000").
        // If that fails (e.g. line is just dots+number), pop from the label queue.
        final beforeNum = line.substring(0, amountMatches.first.start).trim();
        String? label = _extractLabel(beforeNum);
        label ??= labelQueue.isNotEmpty ? labelQueue.removeAt(0) : null;
        results.add(
          label != null ? '$label||${amounts[0]}' : '||${amounts[0]}',
        );
      } else {
        // Multiple (possibly concatenated) prices on one line.
        // Pair with queued labels in order; use null label for extras.
        for (final amount in amounts) {
          final label = labelQueue.isNotEmpty ? labelQueue.removeAt(0) : null;
          results.add(label != null ? '$label||$amount' : '||$amount');
        }
      }
      // Labels used up — clear remainder for this block
      labelQueue.clear();
    }

    return results;
  }

  /// Extracts the cleanest label string from a line fragment.
  /// Returns null for section titles (MENU, CARTE, etc.) and pure numbers.
  static String? _extractLabel(String raw) {
    // Remove parenthetical descriptions
    String s = raw.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    // Remove leading/trailing non-letter chars
    s = s.replaceAll(RegExp(r'^[^A-Za-z\u00C0-\u024F]+'), '').trim();
    s = s.replaceAll(RegExp(r'[^A-Za-z\u00C0-\u024F]+$'), '').trim();
    if (s.length < 2) return null;
    if (RegExp(r'^\d+$').hasMatch(s)) return null;
    // Reject known section title words
    if (_titleWords.contains(s.toUpperCase())) return null;
    return s;
  }
}
