import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/budget_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ocr_service.dart';
import '../services/entity_service.dart';
import '../services/feedback_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_l10n.dart';

// ─── Arc Gauge Painter ────────────────────────────────────────────────────────
class _ArcGaugePainter extends CustomPainter {
  final double progress; // 0.0–1.0
  final Color trackColor;
  final Color fillColor;
  final Color? overBudgetColor;

  _ArcGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    this.overBudgetColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 16;
    const startAngle = math.pi * 0.75;
    const sweepTotal = math.pi * 1.5;
    const strokeWidth = 14.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = progress >= 1.0
          ? (overBudgetColor ?? AppPalette.errorRed)
          : fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // Fill
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepTotal * progress.clamp(0.0, 1.0),
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.fillColor != fillColor;
}

// ─── Budget Screen ────────────────────────────────────────────────────────────
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gaugeCtrl;
  late final Animation<double> _gaugeAnim;
  bool _isScanning = false;
  final _ocrService = OcrService();

  @override
  void initState() {
    super.initState();
    _gaugeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _gaugeAnim = CurvedAnimation(
      parent: _gaugeCtrl,
      curve: Curves.easeOutCubic,
    );
    _gaugeCtrl.forward();
  }

  @override
  void dispose() {
    _gaugeCtrl.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  // ─── Scan a ticket ────────────────────────────────────────────────────────
  Future<void> _scanTicket() async {
    final budget = ref.read(budgetProvider);
    if (budget.totalBudget <= 0) {
      _showSetBudgetSheet();
      return;
    }

    final settings = ref.read(appSettingsProvider);
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _SourceSheet(isDark: Theme.of(context).brightness == Brightness.dark),
    );
    if (source == null) return;

    XFile? img;
    try {
      img = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );
    } on PlatformException {
      return;
    }
    if (img == null) return;

    setState(() => _isScanning = true);
    try {
      final text = await _ocrService.extractTextFromImage(img.path);
      if (text.trim().isEmpty) {
        _showSnack('Aucun texte détecté dans l\'image');
        return;
      }

      final items = EntityService.extractAmountsBlind(
        text,
        settings.sourceCurrency,
      );

      if (items.isEmpty) {
        _showSnack('Aucun prix détecté sur ce ticket');
        return;
      }

      // Pick the largest amount — most likely the receipt total
      double maxAmount = 0;
      for (final item in items) {
        final sep = item.indexOf('||');
        if (sep < 0) continue;
        final amt = double.tryParse(item.substring(sep + 2).trim()) ?? 0;
        if (amt > maxAmount) maxAmount = amt;
      }

      if (maxAmount <= 0) {
        _showSnack('Aucun prix détecté sur ce ticket');
        return;
      }

      // Show confirm sheet
      if (!mounted) return;
      final confirmed = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _ConfirmExpenseSheet(
          amount: maxAmount,
          currency: settings.sourceCurrency,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      );

      if (confirmed != null) {
        final finalAmount = confirmed['amount'] as double;
        final finalLabel = confirmed['label'] as String;
        await ref
            .read(budgetProvider.notifier)
            .addExpense(finalAmount, finalLabel);
        _gaugeCtrl
          ..reset()
          ..forward();
        // Son + vibration selon les préférences utilisateur
        final settings = ref.read(appSettingsProvider);
        unawaited(
          FeedbackService.instance.onExpenseAdded(
            soundEnabled: settings.soundEnabled,
            vibrationEnabled: settings.vibrationEnabled,
          ),
        );
      }
    } catch (e) {
      _showSnack('Erreur lors du scan: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.errorRed,
      ),
    );
  }

  void _showSetBudgetSheet() {
    final budget = ref.read(budgetProvider);
    final settings = ref.read(appSettingsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SetBudgetSheet(
        initialAmount: budget.totalBudget > 0 ? budget.totalBudget : null,
        initialCurrency: budget.currency.isNotEmpty
            ? budget.currency
            : settings.sourceCurrency,
        isDark: Theme.of(context).brightness == Brightness.dark,
        onSave: (amount, currency) async {
          await ref.read(budgetProvider.notifier).setBudget(amount, currency);
          _gaugeCtrl
            ..reset()
            ..forward();
        },
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final budget = ref.watch(budgetProvider);
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppL10n.forLang(settings.appLanguage);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppPalette.violet;

    final isOverBudget = budget.remaining < 0 && budget.totalBudget > 0;
    final gaugeColor = isOverBudget ? AppPalette.errorRed : accent;
    final noBudget = budget.totalBudget <= 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.tileBudget.toUpperCase(),
          style: AppFonts.mono(
            size: 13,
            weight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            letterSpacing: 2.5,
          ),
        ),
        actions: [
          if (!noBudget)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: accent, size: 22),
              tooltip: 'Réinitialiser',
              onPressed: () => _confirmReset(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  // ── Gauge ─────────────────────────────────────────────
                  _GaugeSection(
                    budget: budget,
                    gaugeAnim: _gaugeAnim,
                    gaugeColor: gaugeColor,
                    accent: accent,
                    isDark: isDark,
                    noBudget: noBudget,
                    isOverBudget: isOverBudget,
                    onSetBudget: _showSetBudgetSheet,
                    theme: theme,
                  ),

                  const SizedBox(height: 28),

                  // ── Action buttons ────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.edit_rounded,
                          label: noBudget
                              ? 'Définir un budget'
                              : 'Modifier le budget',
                          color: accent,
                          isDark: isDark,
                          onTap: _showSetBudgetSheet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.document_scanner_rounded,
                          label: 'Scanner un ticket',
                          color: AppPalette.emerald,
                          isDark: isDark,
                          isLoading: _isScanning,
                          onTap: _scanTicket,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Expenses list ─────────────────────────────────────
                  if (budget.expenses.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          'DÉPENSES',
                          style: AppFonts.mono(
                            size: 10,
                            weight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${budget.expenses.length} ticket${budget.expenses.length > 1 ? 's' : ''}',
                          style: AppFonts.outfit(
                            size: 11,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...budget.expenses.map(
                      (e) => _ExpenseCard(
                        expense: e,
                        isDark: isDark,
                        accent: accent,
                        theme: theme,
                        onDelete: () => ref
                            .read(budgetProvider.notifier)
                            .removeExpense(e.id),
                      ),
                    ),
                  ] else if (!noBudget) ...[
                    _EmptyExpenses(isDark: isDark, accent: accent),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark
            ? AppPalette.surfaceRaised
            : AppPalette.parchmentCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Réinitialiser le budget ?',
          style: AppFonts.outfit(
            size: 16,
            weight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Toutes les dépenses et le budget défini seront supprimés.',
          style: AppFonts.outfit(
            size: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: AppFonts.outfit(size: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Réinitialiser',
              style: AppFonts.outfit(
                size: 13,
                weight: FontWeight.w700,
                color: AppPalette.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(budgetProvider.notifier).resetBudget();
      _gaugeCtrl
        ..reset()
        ..forward();
    }
  }
}

// ─── Gauge Section ────────────────────────────────────────────────────────────
class _GaugeSection extends StatelessWidget {
  final BudgetState budget;
  final Animation<double> gaugeAnim;
  final Color gaugeColor;
  final Color accent;
  final bool isDark;
  final bool noBudget;
  final bool isOverBudget;
  final VoidCallback onSetBudget;
  final ThemeData theme;

  const _GaugeSection({
    required this.budget,
    required this.gaugeAnim,
    required this.gaugeColor,
    required this.accent,
    required this.isDark,
    required this.noBudget,
    required this.isOverBudget,
    required this.onSetBudget,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? AppPalette.surface : AppPalette.parchmentCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gaugeColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: gaugeColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Arc gauge
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: gaugeAnim,
                  builder: (_, __) => CustomPaint(
                    size: const Size(220, 220),
                    painter: _ArcGaugePainter(
                      progress: noBudget
                          ? 0
                          : budget.percentUsed * gaugeAnim.value,
                      trackColor: gaugeColor.withValues(alpha: 0.12),
                      fillColor: gaugeColor,
                      overBudgetColor: AppPalette.errorRed,
                    ),
                  ),
                ),
                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (noBudget) ...[
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: accent.withValues(alpha: 0.5),
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: onSetBudget,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Définir\nle budget',
                            textAlign: TextAlign.center,
                            style: AppFonts.outfit(
                              size: 13,
                              weight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        isOverBudget ? 'DÉPASSÉ' : 'RESTANT',
                        style: AppFonts.mono(
                          size: 9,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        child: Text(
                          '${budget.remaining.abs().toStringAsFixed(2)}',
                          style: AppFonts.playfair(
                            size: 38,
                            color: isOverBudget
                                ? AppPalette.errorRed
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        budget.currency,
                        style: AppFonts.mono(
                          size: 11,
                          color: gaugeColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(budget.percentUsed * 100).toStringAsFixed(0)} % utilisé',
                        style: AppFonts.outfit(
                          size: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (!noBudget) ...[
            const SizedBox(height: 20),
            // Stats row
            Row(
              children: [
                _StatChip(
                  label: 'Budget',
                  value:
                      '${budget.totalBudget.toStringAsFixed(2)} ${budget.currency}',
                  color: accent,
                  isDark: isDark,
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Dépensé',
                  value:
                      '${budget.spent.toStringAsFixed(2)} ${budget.currency}',
                  color: isOverBudget
                      ? AppPalette.errorRed
                      : AppPalette.amberLight,
                  isDark: isDark,
                  theme: theme,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final ThemeData theme;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AppFonts.mono(
                size: 8,
                color: color.withValues(alpha: 0.7),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppFonts.mono(
                size: 12,
                weight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppFonts.outfit(
                  size: 12,
                  weight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Expense Card ─────────────────────────────────────────────────────────────
class _ExpenseCard extends StatelessWidget {
  final dynamic expense;
  final bool isDark;
  final Color accent;
  final ThemeData theme;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.isDark,
    required this.accent,
    required this.theme,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dt = expense.timestamp as DateTime;
    final timeStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: isDark ? AppPalette.surface : AppPalette.parchmentCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppPalette.amberLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppPalette.amberLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.label as String,
                  style: AppFonts.outfit(
                    size: 13,
                    weight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: AppFonts.mono(
                    size: 9,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '−${(expense.amount as double).toStringAsFixed(2)} ${expense.currency}',
            style: AppFonts.mono(
              size: 13,
              weight: FontWeight.w700,
              color: AppPalette.errorRed,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyExpenses extends StatelessWidget {
  final bool isDark;
  final Color accent;

  const _EmptyExpenses({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppPalette.surface : AppPalette.parchmentCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 40,
            color: accent.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 14),
          Text(
            'Aucune dépense enregistrée',
            style: AppFonts.outfit(
              size: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scannez un ticket pour déduire du budget',
            textAlign: TextAlign.center,
            style: AppFonts.outfit(
              size: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.28),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Image Source Bottom Sheet ────────────────────────────────────────────────
class _SourceSheet extends StatelessWidget {
  final bool isDark;

  const _SourceSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppPalette.surfaceRaised : AppPalette.parchmentCard;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choisir une source',
            style: AppFonts.outfit(
              size: 16,
              weight: FontWeight.w700,
              color: isDark ? AppPalette.cream : AppPalette.inkDark,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SheetOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Appareil photo',
                  color: AppPalette.emerald,
                  isDark: isDark,
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galerie',
                  color: AppPalette.violet,
                  isDark: isDark,
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppFonts.outfit(
                size: 12,
                weight: FontWeight.w600,
                color: isDark ? AppPalette.cream : AppPalette.inkDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Confirm Expense Sheet ────────────────────────────────────────────────────
class _ConfirmExpenseSheet extends StatefulWidget {
  final double amount;
  final String currency;
  final bool isDark;

  const _ConfirmExpenseSheet({
    required this.amount,
    required this.currency,
    required this.isDark,
  });

  @override
  State<_ConfirmExpenseSheet> createState() => _ConfirmExpenseSheetState();
}

class _ConfirmExpenseSheetState extends State<_ConfirmExpenseSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.amount.toStringAsFixed(3));
    _labelCtrl = TextEditingController(text: 'Ticket');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? AppPalette.surfaceRaised
        : AppPalette.parchmentCard;
    final accent = AppPalette.emerald;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Confirmer la dépense',
              style: AppFonts.outfit(
                size: 17,
                weight: FontWeight.w700,
                color: widget.isDark ? AppPalette.cream : AppPalette.inkDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Montant détecté sur le ticket. Vous pouvez le modifier.',
              style: AppFonts.outfit(
                size: 12,
                color: (widget.isDark ? AppPalette.cream : AppPalette.inkDark)
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            _InputField(
              label: 'Montant (${widget.currency})',
              controller: _amountCtrl,
              isDark: widget.isDark,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            _InputField(
              label: 'Description',
              controller: _labelCtrl,
              isDark: widget.isDark,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SheetButton(
                    label: 'Annuler',
                    color: Colors.grey,
                    isDark: widget.isDark,
                    onTap: () => Navigator.pop(context, null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SheetButton(
                    label: 'Déduire',
                    color: accent,
                    isDark: widget.isDark,
                    onTap: () {
                      final amount = double.tryParse(
                        _amountCtrl.text.replaceAll(',', '.'),
                      );
                      if (amount == null || amount <= 0) return;
                      Navigator.pop(context, <String, dynamic>{
                        'amount': amount,
                        'label': _labelCtrl.text.trim().isEmpty
                            ? 'Ticket'
                            : _labelCtrl.text.trim(),
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Set Budget Sheet ─────────────────────────────────────────────────────────
class _SetBudgetSheet extends StatefulWidget {
  final double? initialAmount;
  final String initialCurrency;
  final bool isDark;
  final Future<void> Function(double amount, String currency) onSave;

  const _SetBudgetSheet({
    this.initialAmount,
    required this.initialCurrency,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<_SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<_SetBudgetSheet> {
  late final TextEditingController _amountCtrl;
  late String _currency;
  bool _saving = false;

  static const _currencies = [
    'TND',
    'EUR',
    'USD',
    'GBP',
    'MAD',
    'DZD',
    'SAR',
    'AED',
    'JPY',
    'CNY',
    'INR',
    'CHF',
    'CAD',
    'AUD',
    'TRY',
  ];

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.initialAmount != null
          ? widget.initialAmount!.toStringAsFixed(2)
          : '',
    );
    _currency = widget.initialCurrency;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    await widget.onSave(amount, _currency);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? AppPalette.surfaceRaised
        : AppPalette.parchmentCard;
    final accent = AppPalette.violet;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Définir le budget',
              style: AppFonts.outfit(
                size: 17,
                weight: FontWeight.w700,
                color: widget.isDark ? AppPalette.cream : AppPalette.inkDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Entrez votre budget total pour ce voyage.',
              style: AppFonts.outfit(
                size: 12,
                color: (widget.isDark ? AppPalette.cream : AppPalette.inkDark)
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            _InputField(
              label: 'Montant du budget',
              controller: _amountCtrl,
              isDark: widget.isDark,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            // Currency picker
            Text(
              'DEVISE',
              style: AppFonts.mono(
                size: 9,
                color: (widget.isDark ? AppPalette.cream : AppPalette.inkDark)
                    .withValues(alpha: 0.4),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppPalette.surface
                    : AppPalette.parchment,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currency,
                  isExpanded: true,
                  dropdownColor: widget.isDark
                      ? AppPalette.surfaceRaised
                      : AppPalette.parchmentCard,
                  style: AppFonts.mono(
                    size: 13,
                    color: widget.isDark
                        ? AppPalette.cream
                        : AppPalette.inkDark,
                  ),
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _currency = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SheetButton(
              label: _saving ? '...' : 'Enregistrer',
              color: accent,
              isDark: widget.isDark,
              onTap: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Sheet Widgets ─────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final TextInputType? keyboardType;
  final bool autofocus;

  const _InputField({
    required this.label,
    required this.controller,
    required this.isDark,
    this.keyboardType,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppPalette.violet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppFonts.mono(
            size: 9,
            color: (isDark ? AppPalette.cream : AppPalette.inkDark).withValues(
              alpha: 0.4,
            ),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: keyboardType,
          style: AppFonts.mono(
            size: 14,
            color: isDark ? AppPalette.cream : AppPalette.inkDark,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppPalette.surface : AppPalette.parchment,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent.withValues(alpha: 0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _SheetButton({
    required this.label,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              label,
              style: AppFonts.outfit(
                size: 14,
                weight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
