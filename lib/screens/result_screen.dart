import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scan_provider.dart';
import '../providers/settings_provider.dart';
import '../services/language_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_l10n.dart';

class ResultScreen extends ConsumerWidget {
  final String mode; // 'full' | 'currency' | 'translate'
  const ResultScreen({super.key, this.mode = 'full'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppL10n.forLang(settings.appLanguage);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final showTranslation = mode == 'full' || mode == 'translate';
    final showEntities = mode == 'full';
    final showCurrency = mode == 'full' || mode == 'currency';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.resultTitle,
          style: AppFonts.mono(
            size: 13,
            weight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            letterSpacing: 2.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.copy_rounded, color: accent, size: 20),
            onPressed: () {
              final buffer = StringBuffer();
              if (scanState.extractedText.isNotEmpty) {
                buffer.writeln(l10n.resultOcrLabel);
                buffer.writeln(scanState.extractedText);
                buffer.writeln();
              }
              if (scanState.detectedLanguage.isNotEmpty) {
                buffer.writeln(
                  'LANGUE: ${scanState.detectedLanguage.toUpperCase()} – ${LanguageService.getLanguageName(scanState.detectedLanguage)}',
                );
                buffer.writeln();
              }
              if (scanState.translatedText.isNotEmpty) {
                buffer.writeln(l10n.resultTransLabel);
                buffer.writeln(scanState.translatedText);
                buffer.writeln();
              }
              if (scanState.convertedCurrency.isNotEmpty) {
                buffer.writeln(l10n.resultCurrencyLabel);
                for (final entry in scanState.convertedCurrency.entries) {
                  buffer.writeln(
                    '${entry.key} = ${entry.value.toStringAsFixed(2)}',
                  );
                }
              }
              Clipboard.setData(ClipboardData(text: buffer.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.resultCopied,
                    style: AppFonts.outfit(size: 13, color: AppPalette.cream),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // â”€â”€ Image thumbnail â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (scanState.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: Image.file(
                        File(scanState.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 16,
                      child: Row(
                        children: [
                          if (scanState.detectedLanguage.isNotEmpty &&
                              scanState.detectedLanguage != 'und') ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                scanState.detectedLanguage.toUpperCase(),
                                style: AppFonts.mono(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: isDark
                                      ? AppPalette.bg
                                      : AppPalette.parchment,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            LanguageService.getLanguageName(
                              scanState.detectedLanguage,
                            ),
                            style: AppFonts.outfit(
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // â”€â”€ Translation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (showTranslation &&
                scanState.translatedText.isNotEmpty &&
                scanState.translatedText != scanState.extractedText) ...[
              _DispatchSection(
                label: l10n.resultTransLabel,
                icon: Icons.translate_rounded,
                accentColor: AppPalette.emerald,
                isDark: isDark,
                child: SelectableText(
                  scanState.translatedText,
                  style: AppFonts.outfit(
                    size: 15,
                    color: theme.colorScheme.onSurface,
                    height: 1.65,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Entities ─────────────────────────────────────────────────────────────
            if (showEntities &&
                scanState.entities.entries
                    .where((e) => e.key != 'prices')
                    .isNotEmpty) ...[
              _DispatchSection(
                label: l10n.resultEntitiesLabel,
                icon: Icons.label_rounded,
                accentColor: AppPalette.violet,
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: scanState.entities.entries
                      .where((e) => e.key != 'prices')
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppPalette.violet.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getEntityLabel(entry.key).toUpperCase(),
                                  style: AppFonts.mono(
                                    size: 9,
                                    color: AppPalette.violet,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.value is List
                                      ? (entry.value as List).join(', ')
                                      : entry.value.toString(),
                                  style: AppFonts.outfit(
                                    size: 13,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Currency conversion ────────────────────────────────────────────────
            if (showCurrency)
              _DispatchSection(
                label: l10n.resultCurrencyLabel,
                icon: Icons.currency_exchange_rounded,
                accentColor: accent,
                isDark: isDark,
                child: scanState.convertedCurrency.isEmpty
                    ? Text(
                        l10n.resultNoPrices,
                        style: AppFonts.outfit(
                          size: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      )
                    : Column(
                        children: scanState.convertedCurrency.entries.map((
                          entry,
                        ) {
                          // Key is the source amount string e.g. "1.000 TND"
                          // Strip trailing duplicate suffix like " (2)"
                          final sourceLabel = entry.key.replaceAll(
                            RegExp(r'\s*\(\d+\)$'),
                            '',
                          );
                          final convertedLabel =
                              '${entry.value.toStringAsFixed(2)} ${settings.targetCurrency}';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sourceLabel,
                                    style: AppFonts.mono(
                                      size: 14,
                                      weight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                        color: accent.withValues(alpha: 0.7),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: accent.withValues(
                                              alpha: 0.28,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          convertedLabel,
                                          style: AppFonts.mono(
                                            size: 14,
                                            weight: FontWeight.w700,
                                            color: accent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),

            const SizedBox(height: 32),

            // â”€â”€ New scan button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? AppPalette.surface : AppPalette.parchmentCard,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded, color: accent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      l10n.resultNewScan,
                      style: AppFonts.mono(
                        size: 12,
                        weight: FontWeight.w600,
                        color: accent,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEntityLabel(String key) {
    switch (key) {
      case 'dates':
        return 'Dates';
      case 'addresses':
        return 'Adresses';
      case 'phones':
        return 'Téléphones';
      case 'emails':
        return 'E-mails';
      case 'urls':
        return 'Liens';
      case 'prices':
        return 'Prix';
      default:
        return key;
    }
  }
}

// â”€â”€â”€ Dispatch Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DispatchSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isDark;
  final Widget child;

  const _DispatchSection({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: accentColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.mono(
                size: 10,
                weight: FontWeight.w600,
                color: accentColor,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: accentColor.withValues(alpha: 0.25)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: accentColor),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppPalette.surface
                          : AppPalette.parchmentCard,
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
