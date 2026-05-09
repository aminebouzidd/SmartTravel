import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  // One recognizer per script — instantiated lazily
  final TextRecognizer _latin = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  final TextRecognizer _chinese = TextRecognizer(
    script: TextRecognitionScript.chinese,
  );
  final TextRecognizer _japanese = TextRecognizer(
    script: TextRecognitionScript.japanese,
  );
  final TextRecognizer _korean = TextRecognizer(
    script: TextRecognitionScript.korean,
  );

  /// Strategy: prefer the Latin result when it has content (works for most
  /// Western / Arabic / numbers menus). Only fall back to CJK recognizers
  /// when Latin produces nothing, because CJK recognizers often hallucinate
  /// characters on non-CJK images that produce a longer-but-wrong result.
  Future<String> extractTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    // Always run Latin first; run CJK only if Latin comes back empty.
    final latinResult = await _latin.processImage(inputImage);
    print('[OCR] Latin result: ${latinResult.text.length} chars');
    if (latinResult.text.trim().length >= 10) {
      return latinResult.text;
    }
    // Latin found nothing — try CJK recognizers in parallel.
    final cjkResults = await Future.wait([
      _chinese.processImage(inputImage),
      _japanese.processImage(inputImage),
      _korean.processImage(inputImage),
    ]);
    final best = cjkResults.reduce(
      (a, b) => a.text.length >= b.text.length ? a : b,
    );
    print('[OCR] CJK best result: ${best.text.length} chars');
    // If CJK also found nothing, return whatever Latin had.
    return best.text.trim().isEmpty ? latinResult.text : best.text;
  }

  Future<String> extractTextFromFile(File file) async {
    return extractTextFromImage(file.path);
  }

  Future<RecognizedText> extractDetailedText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final latinResult = await _latin.processImage(inputImage);
    if (latinResult.text.trim().length >= 10) return latinResult;
    final cjkResults = await Future.wait([
      _chinese.processImage(inputImage),
      _japanese.processImage(inputImage),
      _korean.processImage(inputImage),
    ]);
    final best = cjkResults.reduce(
      (a, b) => a.text.length >= b.text.length ? a : b,
    );
    return best.text.trim().isEmpty ? latinResult : best;
  }

  void dispose() {
    _latin.close();
    _chinese.close();
    _japanese.close();
    _korean.close();
  }
}
