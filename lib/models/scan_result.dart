import 'dart:convert';

class ScanResult {
  final int? id;
  final String extractedText;
  final String detectedLanguage;
  final String translatedText;
  final String targetLanguage;
  final Map<String, dynamic> entities;
  final Map<String, double> convertedCurrency;
  final String timestamp;

  ScanResult({
    this.id,
    required this.extractedText,
    required this.detectedLanguage,
    required this.translatedText,
    required this.targetLanguage,
    this.entities = const {},
    this.convertedCurrency = const {},
    String? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'extractedText': extractedText,
      'detectedLanguage': detectedLanguage,
      'translatedText': translatedText,
      'targetLanguage': targetLanguage,
      'entities': jsonEncode(entities),
      'convertedCurrency': jsonEncode(convertedCurrency),
      'timestamp': timestamp,
    };
  }

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      id: map['id'] as int?,
      extractedText: map['extractedText'] as String? ?? '',
      detectedLanguage: map['detectedLanguage'] as String? ?? 'und',
      translatedText: map['translatedText'] as String? ?? '',
      targetLanguage: map['targetLanguage'] as String? ?? 'fr',
      entities: map['entities'] is String
          ? jsonDecode(map['entities'] as String) as Map<String, dynamic>
          : (map['entities'] as Map<String, dynamic>?) ?? {},
      convertedCurrency: map['convertedCurrency'] is String
          ? (jsonDecode(map['convertedCurrency'] as String)
                    as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, (v as num).toDouble()))
          : (map['convertedCurrency'] as Map<String, double>?) ?? {},
      timestamp:
          map['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ScanResult.fromJson(String source) =>
      ScanResult.fromMap(jsonDecode(source) as Map<String, dynamic>);

  ScanResult copyWith({
    int? id,
    String? extractedText,
    String? detectedLanguage,
    String? translatedText,
    String? targetLanguage,
    Map<String, dynamic>? entities,
    Map<String, double>? convertedCurrency,
    String? timestamp,
  }) {
    return ScanResult(
      id: id ?? this.id,
      extractedText: extractedText ?? this.extractedText,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      translatedText: translatedText ?? this.translatedText,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      entities: entities ?? this.entities,
      convertedCurrency: convertedCurrency ?? this.convertedCurrency,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'ScanResult(id: $id, lang: $detectedLanguage, text: ${extractedText.length > 30 ? '${extractedText.substring(0, 30)}...' : extractedText})';
  }
}
