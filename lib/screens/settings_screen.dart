import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/translation_service.dart';
import '../services/exchange_rate_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_l10n.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final l10n = AppL10n.forLang(settings.appLanguage);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // â”€â”€ Appearance â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SettingSection(label: l10n.settingsAppearance, accent: accent),
          _SettingCard(
            isDark: isDark,
            child: _ToggleRow(
              label: l10n.settingsDarkMode,
              sublabel: settings.isDarkMode
                  ? l10n.settingsEnabled
                  : l10n.settingsDisabled,
              value: settings.isDarkMode,
              onChanged: (v) => notifier.setDarkMode(v),
              icon: settings.isDarkMode
                  ? Icons.nights_stay_rounded
                  : Icons.wb_sunny_rounded,
              accent: accent,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 24),

          // â”€â”€ App language â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SettingSection(label: l10n.settingsLanguage, accent: accent),
          _SettingCard(
            isDark: isDark,
            child: _LangPicker(
              selected: settings.appLanguage,
              onSelect: (v) => notifier.setAppLanguage(v),
              accent: accent,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 24),

          // â”€â”€ Translation language â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SettingSection(label: l10n.settingsTranslation, accent: accent),
          _SettingCard(
            isDark: isDark,
            child: DropdownButtonFormField<String>(
              value: settings.targetTranslationLang,
              decoration: InputDecoration(
                labelText: l10n.settingsTranslateTo,
                labelStyle: AppFonts.mono(
                  size: 11,
                  color: accent,
                  letterSpacing: 0.8,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              dropdownColor: isDark
                  ? AppPalette.surfaceRaised
                  : AppPalette.parchmentCard,
              style: AppFonts.outfit(
                size: 14,
                color: theme.colorScheme.onSurface,
              ),
              items: TranslationService.availableTargetLanguages
                  .map(
                    (lang) => DropdownMenuItem(
                      value: lang['code'],
                      child: Text(
                        '${lang['name']} (${lang['code']!.toUpperCase()})',
                        style: AppFonts.outfit(
                          size: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setTargetTranslationLang(v);
              },
            ),
          ),
          const SizedBox(height: 24),

          // â”€â”€ Target currency â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SettingSection(label: l10n.settingsCurrency, accent: accent),
          _SettingCard(
            isDark: isDark,
            child: DropdownButtonFormField<String>(
              value: settings.targetCurrency,
              decoration: InputDecoration(
                labelText: l10n.settingsConvertTo,
                labelStyle: AppFonts.mono(
                  size: 11,
                  color: accent,
                  letterSpacing: 0.8,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              dropdownColor: isDark
                  ? AppPalette.surfaceRaised
                  : AppPalette.parchmentCard,
              style: AppFonts.outfit(
                size: 14,
                color: theme.colorScheme.onSurface,
              ),
              items: ExchangeRateService.commonCurrencies
                  .map(
                    (c) => DropdownMenuItem(
                      value: c['code'],
                      child: Text(
                        '${c['symbol']} ${c['name']} (${c['code']})',
                        style: AppFonts.outfit(
                          size: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setTargetCurrency(v);
              },
            ),
          ),
          const SizedBox(height: 12),
          // ── Source (scanned) currency ─────────────────────────────────
          _SettingCard(
            isDark: isDark,
            child: DropdownButtonFormField<String>(
              value: settings.sourceCurrency,
              decoration: InputDecoration(
                labelText: l10n.settingsConvertFrom,
                labelStyle: AppFonts.mono(
                  size: 11,
                  color: accent,
                  letterSpacing: 0.8,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              dropdownColor: isDark
                  ? AppPalette.surfaceRaised
                  : AppPalette.parchmentCard,
              style: AppFonts.outfit(
                size: 14,
                color: theme.colorScheme.onSurface,
              ),
              items: ExchangeRateService.commonCurrencies
                  .map(
                    (c) => DropdownMenuItem(
                      value: c['code'],
                      child: Text(
                        '${c['symbol']} ${c['name']} (${c['code']})',
                        style: AppFonts.outfit(
                          size: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setSourceCurrency(v);
              },
            ),
          ),
          const SizedBox(height: 24),
          _SettingSection(label: l10n.settingsNotifs, accent: accent),
          _SettingCard(
            isDark: isDark,
            child: Column(
              children: [
                _ToggleRow(
                  label: 'Notifications',
                  sublabel: 'Push notifications',
                  value: settings.notificationsEnabled,
                  onChanged: (v) => notifier.setNotificationsEnabled(v),
                  icon: Icons.notifications_rounded,
                  accent: accent,
                  isDark: isDark,
                ),
                Divider(
                  height: 20,
                  color: isDark
                      ? AppPalette.border
                      : AppPalette.parchmentBorder,
                ),
                _ToggleRow(
                  label: 'Sons',
                  sublabel: 'Interface audio',
                  value: settings.soundEnabled,
                  onChanged: (v) => notifier.setSoundEnabled(v),
                  icon: Icons.volume_up_rounded,
                  accent: accent,
                  isDark: isDark,
                ),
                Divider(
                  height: 20,
                  color: isDark
                      ? AppPalette.border
                      : AppPalette.parchmentBorder,
                ),
                _ToggleRow(
                  label: 'Vibration',
                  sublabel: 'Retour haptique',
                  value: settings.vibrationEnabled,
                  onChanged: (v) => notifier.setVibrationEnabled(v),
                  icon: Icons.vibration_rounded,
                  accent: accent,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // â”€â”€ About â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SettingSection(label: l10n.settingsAbout, accent: accent),
          _SettingCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Travel Assistant',
                  style: AppFonts.playfair(
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'v1.0.0  Â·  ML Kit On-Device  Â·  Flutter',
                  style: AppFonts.mono(
                    size: 10,
                    color: accent,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Application intelligente pour touristes. OCR, détection de langue, traduction et extraction d\'entités — tout hors-ligne via Google ML Kit.',
                  style: AppFonts.outfit(
                    size: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Setting Section Label â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SettingSection extends StatelessWidget {
  final String label;
  final Color accent;
  const _SettingSection({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            color: accent,
            margin: const EdgeInsets.only(right: 8),
          ),
          Text(
            label,
            style: AppFonts.mono(
              size: 10,
              weight: FontWeight.w600,
              color: accent,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Setting Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SettingCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SettingCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppPalette.surface : AppPalette.parchmentCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: child,
    );
  }
}

// â”€â”€â”€ Toggle Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ToggleRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final Color accent;
  final bool isDark;

  const _ToggleRow({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: value
                ? accent.withValues(alpha: 0.12)
                : theme.colorScheme.outline.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 18,
            color: value
                ? accent
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppFonts.outfit(
                  size: 14,
                  weight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                sublabel,
                style: AppFonts.mono(
                  size: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

// â”€â”€â”€ Language Picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LangPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final Color accent;
  final bool isDark;

  const _LangPicker({
    required this.selected,
    required this.onSelect,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const langs = [
      ('fr', '🇫🇷', 'Français'),
      ('en', '🇬🇧', 'English'),
      ('ar', '🇸🇦', 'العربية'),
    ];
    return Row(
      children: langs.map((lang) {
        final isSelected = selected == lang.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(lang.$1),
            child: Container(
              margin: EdgeInsets.only(right: lang.$1 != 'ar' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? accent
                      : (isDark
                            ? AppPalette.border
                            : AppPalette.parchmentBorder),
                ),
              ),
              child: Column(
                children: [
                  Text(lang.$2, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    lang.$3,
                    style: AppFonts.mono(
                      size: 9,
                      color: isSelected
                          ? accent
                          : (isDark ? AppPalette.muted : AppPalette.inkMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
