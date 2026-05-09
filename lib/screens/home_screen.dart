import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_l10n.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'budget_screen.dart';

// ─── Dot Grid Background ──────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  final Color dotColor;
  _DotGridPainter(this.dotColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    const gap = 30.0;
    for (double x = gap; x < size.width; x += gap) {
      for (double y = gap; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.dotColor != dotColor;
}

// ─── HomeScreen ───────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _ctrl;
  // 6 staggered slots: logo · title · tagline · scan-btn · row1 cards · row2 cards
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    const starts = [0.0, 0.08, 0.16, 0.26, 0.38, 0.48];
    _fades = starts
        .map(
          (s) => CurvedAnimation(
            parent: _ctrl,
            curve: Interval(s, s + 0.38, curve: Curves.easeOut),
          ),
        )
        .toList();
    _slides = starts
        .map(
          (s) => Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _ctrl,
                  curve: Interval(s, s + 0.38, curve: Curves.easeOutCubic),
                ),
              ),
        )
        .toList();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) => FadeTransition(
    opacity: _fades[i],
    child: SlideTransition(position: _slides[i], child: child),
  );

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppL10n.forLang(settings.appLanguage);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final dotColor = isDark
        ? AppPalette.amber.withValues(alpha: 0.06)
        : AppPalette.amberLight.withValues(alpha: 0.12);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _AppDrawer(isDark: isDark, accent: accent),
      body: Stack(
        children: [
          // ── Dot grid texture ────────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter(dotColor)),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header row: brand word-mark + compass icon ──────
                        _reveal(
                          0,
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.explore_rounded,
                                  color: isDark
                                      ? AppPalette.bg
                                      : AppPalette.parchment,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SMART TRAVEL',
                                    style: AppFonts.mono(
                                      size: 11,
                                      weight: FontWeight.w600,
                                      color: accent,
                                      letterSpacing: 3.0,
                                    ),
                                  ),
                                  Text(
                                    l10n.fieldIntelligence,
                                    style: AppFonts.outfit(
                                      size: 12,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ── Hero title ────────────────────────────────────
                        _reveal(
                          1,
                          Text(
                            l10n.heroCTA,
                            style: AppFonts.playfair(
                              size: 38,
                              color: theme.colorScheme.onSurface,
                              height: 1.15,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Tagline ───────────────────────────────────────
                        _reveal(
                          2,
                          Text(
                            l10n.homeTagline,
                            style: AppFonts.outfit(
                              size: 14,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                              height: 1.6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Three action tiles ─────────────────────────
                        _reveal(
                          3,
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _ActionTile(
                                    icon: Icons.currency_exchange_rounded,
                                    title: l10n.tileCurrency,
                                    accentColor: accent,
                                    isDark: isDark,
                                    onTap: () => Navigator.push(
                                      context,
                                      _fadeRoute(
                                        const ScanScreen(mode: 'currency'),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ActionTile(
                                    icon: Icons.translate_rounded,
                                    title: l10n.tileTranslate,
                                    accentColor: AppPalette.emerald,
                                    isDark: isDark,
                                    onTap: () => Navigator.push(
                                      context,
                                      _fadeRoute(
                                        const ScanScreen(mode: 'translate'),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ActionTile(
                                    icon: Icons.account_balance_wallet_rounded,
                                    title: l10n.tileBudget,
                                    accentColor: AppPalette.violet,
                                    isDark: isDark,
                                    onTap: () => Navigator.push(
                                      context,
                                      _fadeRoute(const BudgetScreen()),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Historique wide tile ───────────────────────
                        _reveal(
                          5,
                          _WideTile(
                            icon: Icons.history_rounded,
                            title: l10n.tileHistory,
                            accentColor: AppPalette.violet,
                            isDark: isDark,
                            onTap: () => Navigator.push(
                              context,
                              _fadeRoute(const HistoryScreen()),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Custom bottom nav ──────────────────────────────────────
                _BottomNav(
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  onHistory: () => Navigator.push(
                    context,
                    _fadeRoute(const HistoryScreen()),
                  ),
                  onSettings: () => Navigator.push(
                    context,
                    _fadeRoute(const SettingsScreen()),
                  ),
                  isDark: isDark,
                  accent: accent,
                  l10n: l10n,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Route<T> _fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
    pageBuilder: (_, a, __) => page,
    transitionsBuilder: (_, a, __, child) =>
        FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 280),
  );
}

// ─── Wide Tile (full-width row) ───────────────────────────────────────────────
class _WideTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _WideTile({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? AppPalette.surface : AppPalette.parchmentCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: AppFonts.outfit(
                size: 15,
                weight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: accentColor.withValues(alpha: 0.6),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Tile ──────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppPalette.surface : AppPalette.parchmentCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
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
    );
  }
}

// ─── Custom Bottom Navigation ─────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final VoidCallback onMenu;
  final VoidCallback onHistory;
  final VoidCallback onSettings;
  final bool isDark;
  final Color accent;
  final AppL10n l10n;

  const _BottomNav({
    required this.onMenu,
    required this.onHistory,
    required this.onSettings,
    required this.isDark,
    required this.accent,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppPalette.surface : AppPalette.parchmentCard;
    final border = isDark ? AppPalette.border : AppPalette.parchmentBorder;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.menu_rounded,
                label: 'MENU',
                active: false,
                accent: accent,
                isDark: isDark,
                onTap: onMenu,
              ),
              _NavItem(
                icon: Icons.home_rounded,
                label: l10n.navHome,
                active: true,
                accent: accent,
                isDark: isDark,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: l10n.navHistory,
                active: false,
                accent: accent,
                isDark: isDark,
                onTap: onHistory,
              ),
              _NavItem(
                icon: Icons.tune_rounded,
                label: l10n.navSettings,
                active: false,
                accent: accent,
                isDark: isDark,
                onTap: onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = active
        ? accent
        : (isDark ? AppPalette.muted : AppPalette.inkMuted);
    final labelColor = active
        ? accent
        : (isDark
              ? AppPalette.muted.withValues(alpha: 0.6)
              : AppPalette.inkMuted.withValues(alpha: 0.6));
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              Container(
                width: 24,
                height: 2,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ] else
              const SizedBox(height: 8),
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppFonts.mono(
                size: 8,
                color: labelColor,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App Drawer ───────────────────────────────────────────────────────────────
class _AppDrawer extends ConsumerWidget {
  final bool isDark;
  final Color accent;

  const _AppDrawer({required this.isDark, required this.accent});

  static Route<T> _fade<T>(Widget page) => PageRouteBuilder<T>(
    pageBuilder: (_, a, __) => page,
    transitionsBuilder: (_, a, __, child) =>
        FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 260),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final onSurface = isDark ? AppPalette.cream : AppPalette.inkDark;
    final bg = isDark ? AppPalette.bg : AppPalette.parchment;
    final borderColor = isDark ? AppPalette.border : AppPalette.parchmentBorder;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final userEmail = firebaseUser?.email ?? '';
    // Préférer SharedPreferences → sinon Firebase displayName → sinon email
    final fbDisplayName = firebaseUser?.displayName ?? '';
    final rawNom = settings.userNom.isNotEmpty
        ? settings.userNom
        : (fbDisplayName.contains(' ')
              ? fbDisplayName.split(' ').skip(1).join(' ')
              : fbDisplayName);
    final rawPrenom = settings.userPrenom.isNotEmpty
        ? settings.userPrenom
        : (fbDisplayName.contains(' ') ? fbDisplayName.split(' ').first : '');
    final fullName = rawPrenom.isNotEmpty && rawNom.isNotEmpty
        ? '$rawPrenom $rawNom'
        : rawPrenom.isNotEmpty
        ? rawPrenom
        : rawNom.isNotEmpty
        ? rawNom
        : (userEmail.isNotEmpty ? userEmail.split('@').first : 'Voyageur');
    final initials = [
      if (rawPrenom.isNotEmpty) rawPrenom[0],
      if (rawNom.isNotEmpty) rawNom[0],
    ].join().toUpperCase();

    void go(Widget page) {
      Navigator.of(context).pop();
      Navigator.of(context).push(_fade(page));
    }

    return Drawer(
      backgroundColor: bg,
      width: 290,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.30),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.explore_rounded,
                          color: isDark ? AppPalette.bg : AppPalette.parchment,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SMART TRAVEL',
                        style: AppFonts.mono(
                          size: 10,
                          weight: FontWeight.w600,
                          color: accent,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Avatar circle with initials
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.40),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials.isNotEmpty ? initials : '?',
                        style: AppFonts.playfair(
                          size: 20,
                          color: accent,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    fullName,
                    style: AppFonts.playfair(
                      size: 20,
                      color: onSurface,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Smart Traveler',
                    style: AppFonts.mono(
                      size: 10,
                      color: accent,
                      letterSpacing: 1.4,
                    ),
                  ),
                  if (userEmail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: AppFonts.outfit(
                        size: 11,
                        color: onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Section label ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text(
                'FONCTIONNALITÉS',
                style: AppFonts.mono(
                  size: 9,
                  color: onSurface.withValues(alpha: 0.35),
                  letterSpacing: 2.0,
                ),
              ),
            ),

            // ── Nav items ───────────────────────────────────────────────────
            _DrawerItem(
              icon: Icons.camera_alt_rounded,
              label: 'Scanner',
              sublabel: 'Analyser une image',
              accent: accent,
              isDark: isDark,
              onTap: () => go(const ScanScreen()),
            ),
            _DrawerItem(
              icon: Icons.currency_exchange_rounded,
              label: 'Change de devise',
              sublabel: 'Convertir des montants',
              accent: accent,
              isDark: isDark,
              onTap: () => go(const ScanScreen(mode: 'currency')),
            ),
            _DrawerItem(
              icon: Icons.translate_rounded,
              label: 'Traduction',
              sublabel: 'Traduire du texte scanné',
              accentOverride: AppPalette.emerald,
              accent: accent,
              isDark: isDark,
              onTap: () => go(const ScanScreen(mode: 'translate')),
            ),
            _DrawerItem(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Budget',
              sublabel: 'Gérer vos dépenses',
              accentOverride: AppPalette.violet,
              accent: accent,
              isDark: isDark,
              onTap: () => go(const BudgetScreen()),
            ),
            _DrawerItem(
              icon: Icons.history_rounded,
              label: 'Historique',
              sublabel: 'Vos scans précédents',
              accentOverride: AppPalette.violet,
              accent: accent,
              isDark: isDark,
              onTap: () => go(const HistoryScreen()),
            ),

            const Spacer(),

            // ── Settings + Logout footer ────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 1)),
              ),
              child: Column(
                children: [
                  _DrawerItem(
                    icon: Icons.tune_rounded,
                    label: 'Réglages',
                    sublabel: 'Préférences de l\'app',
                    accent: accent,
                    isDark: isDark,
                    onTap: () => go(const SettingsScreen()),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      // Le StreamBuilder dans main.dart redirige automatiquement
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppPalette.errorRed.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: AppPalette.errorRed,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Se déconnecter',
                                  style: AppFonts.outfit(
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: AppPalette.errorRed,
                                  ),
                                ),
                                Text(
                                  'Retour à l\'écran de connexion',
                                  style: AppFonts.outfit(
                                    size: 11,
                                    color: AppPalette.errorRed.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppPalette.errorRed.withValues(alpha: 0.40),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Drawer Item ──────────────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color accent;
  final Color? accentOverride;
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.accent,
    required this.isDark,
    required this.onTap,
    this.accentOverride,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentOverride ?? accent;
    final onSurface = isDark ? AppPalette.cream : AppPalette.inkDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 20),
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
                      color: onSurface,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: AppFonts.outfit(
                      size: 11,
                      color: onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: onSurface.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }
}
