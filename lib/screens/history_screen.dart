import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scan_provider.dart';
import '../providers/settings_provider.dart';
import '../models/scan_result.dart';
import '../services/language_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_l10n.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<ScanResult> _scans = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final db = ref.read(historyDbProvider);
    final scans = await db.getAllScans();
    setState(() {
      _scans = scans;
      _isLoading = false;
    });
  }

  Future<void> _searchHistory(String query) async {
    setState(() => _searchQuery = query);
    final db = ref.read(historyDbProvider);
    final scans = query.isEmpty
        ? await db.getAllScans()
        : await db.searchScans(query);
    setState(() => _scans = scans);
  }

  Future<void> _deleteScan(int id) async {
    final db = ref.read(historyDbProvider);
    await db.deleteScan(id);
    await _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Scan supprimÃ©')));
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer tout ?'),
        content: const Text(
          'Voulez-vous vraiment supprimer tout l\'historique ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final db = ref.read(historyDbProvider);
      await db.clearHistory();
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppL10n.forLang(settings.appLanguage);

    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.historyTitle,
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
          if (_scans.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'TOUT VIDER',
                style: AppFonts.mono(
                  size: 10,
                  color: AppPalette.errorRed,
                  letterSpacing: 1.2,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // â”€â”€ Search bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: _searchHistory,
              style: AppFonts.outfit(
                size: 14,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Rechercherâ€¦',
                hintStyle: AppFonts.outfit(size: 14, color: AppPalette.muted),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppPalette.muted,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
          ),

          // â”€â”€ Count label â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (_scans.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Text(
                    '${_scans.length} RAPPORT${_scans.length > 1 ? 'S' : ''}',
                    style: AppFonts.mono(
                      size: 10,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.35,
                      ),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 10),

          // â”€â”€ List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: accent))
                : _scans.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.historyEmpty,
                          style: AppFonts.playfair(
                            size: 26,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? l10n.historyEmptySub
                              : '"$_searchQuery" — ${l10n.historyNoResults}',
                          style: AppFonts.mono(
                            size: 11,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: accent,
                    onRefresh: _loadHistory,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _scans.length,
                      separatorBuilder: (_, __) => Divider(
                        color: theme.colorScheme.outline.withValues(alpha: 0.4),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final scan = _scans[index];
                        return _DispatchEntry(
                          scan: scan,
                          accent: accent,
                          isDark: isDark,
                          onTap: () => _showScanDetail(scan),
                          onDelete: () => _deleteScan(scan.id!),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showScanDetail(ScanResult scan) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppPalette.surface : AppPalette.parchmentCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppPalette.border
                        : AppPalette.parchmentBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Language badge + timestamp
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      scan.detectedLanguage.toUpperCase(),
                      style: AppFonts.mono(
                        size: 11,
                        weight: FontWeight.w700,
                        color: isDark ? AppPalette.bg : AppPalette.parchment,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    LanguageService.getLanguageName(scan.detectedLanguage),
                    style: AppFonts.outfit(
                      size: 14,
                      color: isDark ? AppPalette.muted : AppPalette.inkMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(scan.timestamp),
                    style: AppFonts.mono(
                      size: 10,
                      color: isDark ? AppPalette.muted : AppPalette.inkMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Sections
              _SheetSection(
                label: 'TEXTE OCR',
                content: scan.extractedText,
                accentColor: AppPalette.teal,
                isDark: isDark,
              ),
              _SheetSection(
                label: 'TRADUCTION (${scan.targetLanguage.toUpperCase()})',
                content: scan.translatedText,
                accentColor: AppPalette.emerald,
                isDark: isDark,
              ),
              if (scan.convertedCurrency.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'CONVERSIONS',
                  style: AppFonts.mono(
                    size: 10,
                    weight: FontWeight.w600,
                    color: accent,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: accent.withValues(alpha: 0.25)),
                const SizedBox(height: 10),
                ...scan.convertedCurrency.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.key,
                          style: AppFonts.mono(
                            size: 11,
                            color: isDark
                                ? AppPalette.muted
                                : AppPalette.inkMuted,
                          ),
                        ),
                        Text(
                          e.value.toStringAsFixed(2),
                          style: AppFonts.mono(
                            size: 13,
                            weight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return timestamp;
    }
  }
}

// â”€â”€â”€ Dispatch Entry (list item) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DispatchEntry extends StatelessWidget {
  final ScanResult scan;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DispatchEntry({
    required this.scan,
    required this.accent,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Lang badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  scan.detectedLanguage.isEmpty
                      ? '?'
                      : scan.detectedLanguage.toUpperCase(),
                  style: AppFonts.mono(
                    size: 12,
                    weight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.extractedText.length > 70
                        ? '${scan.extractedText.substring(0, 70)}â€¦'
                        : scan.extractedText,
                    style: AppFonts.outfit(
                      size: 13,
                      weight: FontWeight.w500,
                      color: isDark ? AppPalette.cream : AppPalette.inkDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(scan.timestamp),
                    style: AppFonts.mono(
                      size: 10,
                      color: isDark ? AppPalette.muted : AppPalette.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppPalette.errorRed.withValues(alpha: 0.5),
              ),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return 'IL Y A ${diff.inMinutes} MIN';
      if (diff.inHours < 24) return 'IL Y A ${diff.inHours}H';
      if (diff.inDays < 7) return 'IL Y A ${diff.inDays} JOURS';
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return timestamp;
    }
  }
}

// â”€â”€â”€ Sheet Section (bottom sheet detail) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SheetSection extends StatelessWidget {
  final String label;
  final String content;
  final Color accentColor;
  final bool isDark;

  const _SheetSection({
    required this.label,
    required this.content,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
          const SizedBox(height: 6),
          Container(height: 1, color: accentColor.withValues(alpha: 0.2)),
          const SizedBox(height: 10),
          Text(
            content,
            style: AppFonts.outfit(
              size: 14,
              color: isDark ? AppPalette.cream : AppPalette.inkDark,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
