import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

// ─── Dot Grid (shared pattern) ────────────────────────────────────────────────
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

// ─── SignupScreen ─────────────────────────────────────────────────────────────
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  DateTime? _selectedDob;

  late final AnimationController _ctrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    const starts = [0.0, 0.08, 0.16, 0.24, 0.32, 0.42, 0.50, 0.58];
    _fades = starts
        .map(
          (s) => CurvedAnimation(
            parent: _ctrl,
            curve: Interval(s, s + 0.40, curve: Curves.easeOut),
          ),
        )
        .toList();
    _slides = starts
        .map(
          (s) => Tween<Offset>(begin: const Offset(0, 0.20), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _ctrl,
                  curve: Interval(s, s + 0.40, curve: Curves.easeOutCubic),
                ),
              ),
        )
        .toList();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _dobCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) => FadeTransition(
    opacity: _fades[i],
    child: SlideTransition(position: _slides[i], child: child),
  );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 5),
      locale: const Locale('fr'),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: isDark ? AppPalette.amber : AppPalette.amberLight,
              onPrimary: isDark ? AppPalette.bg : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobCtrl.text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Créer le compte Firebase
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      // Mettre à jour le displayName
      await FirebaseAuth.instance.currentUser?.updateDisplayName(
        '${_prenomCtrl.text.trim()} ${_nomCtrl.text.trim()}',
      );

      // Sauvegarder nom & prénom localement
      await ref
          .read(appSettingsProvider.notifier)
          .setUserName(_nomCtrl.text.trim(), _prenomCtrl.text.trim());

      // Le StreamBuilder dans main.dart redirige automatiquement vers HomeScreen
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email déjà existant.';
          break;
        case 'weak-password':
          message = 'Mot de passe trop faible (minimum 6 caractères).';
          break;
        case 'invalid-email':
          message = 'Adresse e-mail invalide.';
          break;
        default:
          message = e.message ?? 'Une erreur est survenue.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppFonts.outfit(size: 13, color: AppPalette.cream),
          ),
          backgroundColor: AppPalette.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final dotColor = isDark
        ? AppPalette.amber.withValues(alpha: 0.06)
        : AppPalette.amberLight.withValues(alpha: 0.12);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter(dotColor)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Brand header ───────────────────────────────────────
                    _reveal(
                      0,
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.explore_rounded,
                              color: isDark
                                  ? AppPalette.bg
                                  : AppPalette.parchment,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                'Field Intelligence',
                                style: AppFonts.outfit(
                                  size: 11,
                                  color: onSurface.withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Title ──────────────────────────────────────────────
                    _reveal(
                      1,
                      Text(
                        'Créer un\ncompte.',
                        style: AppFonts.playfair(
                          size: 36,
                          color: onSurface,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _reveal(
                      1,
                      Text(
                        'Rejoignez la communauté des Smart Travelers.',
                        style: AppFonts.outfit(
                          size: 13,
                          color: onSurface.withValues(alpha: 0.50),
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Section label ──────────────────────────────────────
                    _reveal(
                      2,
                      _SectionLabel(label: 'IDENTITÉ', accent: accent),
                    ),
                    const SizedBox(height: 12),

                    // ── Nom & Prénom row ───────────────────────────────────
                    _reveal(
                      2,
                      Row(
                        children: [
                          Expanded(
                            child: _AuthField(
                              controller: _nomCtrl,
                              label: 'Nom',
                              icon: Icons.badge_outlined,
                              isDark: isDark,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Champ requis'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AuthField(
                              controller: _prenomCtrl,
                              label: 'Prénom',
                              icon: Icons.person_outline_rounded,
                              isDark: isDark,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Champ requis'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Date de naissance ──────────────────────────────────
                    _reveal(
                      2,
                      _AuthField(
                        controller: _dobCtrl,
                        label: 'Date de naissance',
                        icon: Icons.cake_outlined,
                        isDark: isDark,
                        readOnly: true,
                        onTap: _pickDate,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Veuillez sélectionner votre date de naissance'
                            : null,
                        suffixIcon: Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Section label ──────────────────────────────────────
                    _reveal(
                      3,
                      _SectionLabel(label: 'CONNEXION', accent: accent),
                    ),
                    const SizedBox(height: 12),

                    // ── Email ──────────────────────────────────────────────
                    _reveal(
                      3,
                      _AuthField(
                        controller: _emailCtrl,
                        label: 'Adresse e-mail',
                        icon: Icons.alternate_email_rounded,
                        isDark: isDark,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Champ requis';
                          }
                          if (!RegExp(
                            r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$',
                          ).hasMatch(v.trim())) {
                            return 'Adresse e-mail invalide';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Mot de passe ───────────────────────────────────────
                    _reveal(
                      4,
                      _AuthField(
                        controller: _passwordCtrl,
                        label: 'Mot de passe',
                        icon: Icons.lock_outline_rounded,
                        isDark: isDark,
                        obscureText: _obscurePassword,
                        suffixIcon: GestureDetector(
                          onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: onSurface.withValues(alpha: 0.35),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Champ requis';
                          if (v.length < 8) {
                            return 'Minimum 8 caractères';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Confirmer mot de passe ─────────────────────────────
                    _reveal(
                      4,
                      _AuthField(
                        controller: _confirmCtrl,
                        label: 'Confirmer le mot de passe',
                        icon: Icons.lock_outline_rounded,
                        isDark: isDark,
                        obscureText: _obscureConfirm,
                        suffixIcon: GestureDetector(
                          onTap: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                          child: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: onSurface.withValues(alpha: 0.35),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Champ requis';
                          if (v != _passwordCtrl.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Submit button ──────────────────────────────────────
                    _reveal(
                      5,
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: isDark
                                ? AppPalette.bg
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark
                                        ? AppPalette.bg
                                        : Colors.white,
                                  ),
                                )
                              : Text(
                                  "S'INSCRIRE",
                                  style: AppFonts.mono(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    letterSpacing: 2.0,
                                    color: isDark
                                        ? AppPalette.bg
                                        : Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Divider ────────────────────────────────────────────
                    _reveal(
                      6,
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: onSurface.withValues(alpha: 0.12),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OU',
                              style: AppFonts.mono(
                                size: 10,
                                color: onSurface.withValues(alpha: 0.35),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: onSurface.withValues(alpha: 0.12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Already have account ───────────────────────────────
                    _reveal(
                      7,
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Vous êtes déjà un Smart Traveler ?',
                              style: AppFonts.outfit(
                                size: 13,
                                color: onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: accent.withValues(alpha: 0.50),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  foregroundColor: accent,
                                ),
                                child: Text(
                                  'SE CONNECTER',
                                  style: AppFonts.mono(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: accent,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable auth field ──────────────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.validator,
    this.onTap,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTap: onTap,
      validator: validator,
      style: AppFonts.outfit(size: 14, color: onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppFonts.outfit(
          size: 13,
          color: onSurface.withValues(alpha: 0.45),
        ),
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
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
    );
  }
}
