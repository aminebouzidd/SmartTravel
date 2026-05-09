import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/scan_provider.dart';
import '../providers/settings_provider.dart';
import '../services/feedback_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_l10n.dart';
import 'result_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  final String mode; // 'full' | 'currency' | 'translate'
  const ScanScreen({super.key, this.mode = 'full'});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Reset le scan state quand on arrive sur l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scanProvider.notifier).reset();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.message}')));
      }
    }
  }

  Future<void> _processImage() async {
    if (_selectedImagePath == null) return;

    final settings = ref.read(appSettingsProvider);

    setState(() => _isProcessing = true);

    await ref.read(scanProvider.notifier).processImage(_selectedImagePath!);

    setState(() => _isProcessing = false);

    final scanState = ref.read(scanProvider);
    if (scanState.status == ScanStatus.done && mounted) {
      // Retour sensoriel (son + vibration) conditionné aux réglages utilisateur
      unawaited(
        FeedbackService.instance.onScanSuccess(
          soundEnabled: settings.soundEnabled,
          vibrationEnabled: settings.vibrationEnabled,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(mode: widget.mode)),
      );
    } else if (scanState.status == ScanStatus.error && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scanState.errorMessage ?? 'Une erreur est survenue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scanState = ref.watch(scanProvider);
    final accent = theme.colorScheme.primary;
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppL10n.forLang(settings.appLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.scanTitle,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image well ─────────────────────────────────────────────
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: isDark ? AppPalette.surface : AppPalette.parchmentCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedImagePath != null
                      ? accent
                      : theme.colorScheme.outline,
                  width: _selectedImagePath != null ? 1.5 : 1,
                ),
              ),
              child: _selectedImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(_selectedImagePath!),
                            fit: BoxFit.cover,
                          ),
                          // Gradient overlay at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.55),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 14,
                            left: 16,
                            child: Text(
                              'IMAGE SÉLECTIONNÉE',
                              style: AppFonts.mono(
                                size: 10,
                                color: Colors.white.withValues(alpha: 0.8),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Icon(
                            Icons.document_scanner_rounded,
                            size: 32,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'AUCUNE IMAGE',
                          style: AppFonts.mono(
                            size: 11,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.35,
                            ),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.scanSubtitle,
                          style: AppFonts.outfit(
                            size: 13,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // ── Source buttons ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: l10n.scanCamera,
                    accentColor: accent,
                    isDark: isDark,
                    enabled: !_isProcessing,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_rounded,
                    label: l10n.scanGallery,
                    accentColor: AppPalette.teal,
                    isDark: isDark,
                    enabled: !_isProcessing,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Processing pipeline ────────────────────────────────────
            if (_isProcessing) ...[
              _PipelineTracker(
                status: scanState.status,
                label: scanState.statusLabel,
                accent: accent,
                isDark: isDark,
                l10n: l10n,
              ),
              const SizedBox(height: 20),
            ],

            // ── Analyse button ─────────────────────────────────────────
            GestureDetector(
              onTap: (_selectedImagePath != null && !_isProcessing)
                  ? _processImage
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 58,
                decoration: BoxDecoration(
                  color: (_selectedImagePath != null && !_isProcessing)
                      ? accent
                      : theme.colorScheme.outline.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: (_selectedImagePath != null && !_isProcessing)
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isProcessing)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? AppPalette.bg : AppPalette.parchment,
                        ),
                      )
                    else
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 20,
                        color: (_selectedImagePath != null)
                            ? (isDark ? AppPalette.bg : AppPalette.parchment)
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                      ),
                    const SizedBox(width: 12),
                    Text(
                      _isProcessing ? '...' : l10n.scanAnalyze,
                      style: AppFonts.mono(
                        size: 13,
                        weight: FontWeight.w600,
                        color: (_selectedImagePath != null && !_isProcessing)
                            ? (isDark ? AppPalette.bg : AppPalette.parchment)
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                        letterSpacing: 1.0,
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
}

// ─── Source Button ────────────────────────────────────────────────────────────
class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool isDark;
  final bool enabled;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.isDark,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: enabled
              ? accentColor.withValues(alpha: 0.08)
              : theme.colorScheme.outline.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? accentColor.withValues(alpha: 0.35)
                : theme.colorScheme.outline,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled
                  ? accentColor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppFonts.mono(
                size: 11,
                weight: FontWeight.w600,
                color: enabled
                    ? accentColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pipeline Tracker ─────────────────────────────────────────────────────────
class _PipelineTracker extends StatelessWidget {
  final ScanStatus status;
  final String label;
  final Color accent;
  final bool isDark;
  final AppL10n l10n;

  const _PipelineTracker({
    required this.status,
    required this.label,
    required this.accent,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [
      (ScanStatus.processing, l10n.stepOcr),
      (ScanStatus.translating, l10n.stepTranslation),
      (ScanStatus.extracting, l10n.stepEntities),
      (ScanStatus.converting, l10n.stepCurrency),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppPalette.surface : AppPalette.parchmentCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              ),
              const SizedBox(width: 12),
              Text(
                label.toUpperCase(),
                style: AppFonts.mono(
                  size: 11,
                  weight: FontWeight.w600,
                  color: accent,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: steps.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value;
              final isActive = status == step.$1;
              final isDone = status.index > step.$1.index;
              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? AppPalette.emerald
                                : isActive
                                ? accent
                                : theme.colorScheme.outline,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.55),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          step.$2,
                          style: AppFonts.mono(
                            size: 8,
                            color: isDone || isActive
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.35,
                                  ),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 1,
                          margin: const EdgeInsets.only(bottom: 20),
                          color: isDone
                              ? AppPalette.emerald.withValues(alpha: 0.5)
                              : theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
