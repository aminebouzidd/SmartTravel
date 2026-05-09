import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Centralise tous les retours sensoriels de l'application :
/// son (audioplayers) et vibration (HapticFeedback).
///
/// Chaque méthode accepte les flags [soundEnabled] et [vibrationEnabled]
/// lus depuis AppSettings, ce qui permet un contrôle fin sans couplage fort.
class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  // Un seul player réutilisé pour éviter les latences de création.
  final AudioPlayer _player = AudioPlayer();

  // ── Presets de sons ─────────────────────────────────────────────────────────

  /// Son de succès après un scan (bip court, tonalité haute)
  static const _kScanSuccessFreq = 1046.0; // Do6 — clair, bref
  static const _kScanSuccessDuration = 0.18;

  /// Son de confirmation ajout dépense (tonalité médium-douce)
  static const _kExpenseFreq = 698.0; // Fa5 — chaleureux
  static const _kExpenseDuration = 0.14;

  /// Petit clic neutre (toggle, etc.)
  static const _kClickFreq = 880.0; // La5
  static const _kClickDuration = 0.08;

  // ── API publique ─────────────────────────────────────────────────────────────

  /// Appelé quand le scan ML Kit réussit et qu'on navigue vers les résultats.
  Future<void> onScanSuccess({
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) async {
    if (vibrationEnabled) {
      await HapticFeedback.heavyImpact();
    }
    if (soundEnabled) {
      await _playBeep(
        frequency: _kScanSuccessFreq,
        duration: _kScanSuccessDuration,
        amplitude: 0.35,
      );
    }
  }

  /// Appelé quand une dépense est ajoutée dans le budget.
  Future<void> onExpenseAdded({
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) async {
    if (vibrationEnabled) {
      await HapticFeedback.mediumImpact();
    }
    if (soundEnabled) {
      await _playBeep(
        frequency: _kExpenseFreq,
        duration: _kExpenseDuration,
        amplitude: 0.28,
      );
    }
  }

  /// Retour léger pour les toggles/interactions UI.
  Future<void> onUiInteraction({
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) async {
    if (vibrationEnabled) {
      await HapticFeedback.lightImpact();
    }
    if (soundEnabled) {
      await _playBeep(
        frequency: _kClickFreq,
        duration: _kClickDuration,
        amplitude: 0.18,
      );
    }
  }

  // ── Implémentation interne ───────────────────────────────────────────────────

  /// Génère un bip WAV PCM en mémoire et le joue via audioplayers [BytesSource].
  /// Aucun fichier asset nécessaire — totalement hors-ligne et instantané.
  Future<void> _playBeep({
    required double frequency,
    required double duration,
    double amplitude = 0.3,
    int sampleRate = 22050,
  }) async {
    try {
      final bytes = _generateWav(
        frequency: frequency,
        durationSeconds: duration,
        amplitude: amplitude,
        sampleRate: sampleRate,
      );
      await _player.stop();
      await _player.play(BytesSource(bytes));
    } catch (_) {
      // Silencieux si audioplayers n'est pas disponible sur le device.
    }
  }

  /// Construit un fichier WAV 16-bit mono en mémoire à partir d'une onde
  /// sinusoïdale avec un fade-out exponentiel pour éviter les clics.
  static Uint8List _generateWav({
    required double frequency,
    required double durationSeconds,
    double amplitude = 0.3,
    int sampleRate = 22050,
  }) {
    final numSamples = (sampleRate * durationSeconds).round();
    final dataSize = numSamples * 2; // 16-bit = 2 octets/sample
    final buffer = ByteData(44 + dataSize);

    // ── En-tête RIFF ──────────────────────────────────────────────────────────
    _writeAscii(buffer, 0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    _writeAscii(buffer, 8, 'WAVE');
    _writeAscii(buffer, 12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little); // taille bloc fmt
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, 1, Endian.little); // mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // byteRate
    buffer.setUint16(32, 2, Endian.little); // blockAlign
    buffer.setUint16(34, 16, Endian.little); // bitsPerSample
    _writeAscii(buffer, 36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    // ── Données PCM avec fade-out exponentiel ─────────────────────────────────
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final env = math.exp(-4.0 * i / numSamples); // enveloppe naturelle
      final raw = amplitude * env * math.sin(2 * math.pi * frequency * t);
      final sample = (raw * 32767).round().clamp(-32768, 32767);
      buffer.setInt16(44 + i * 2, sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  static void _writeAscii(ByteData buf, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      buf.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  void dispose() => _player.dispose();
}
