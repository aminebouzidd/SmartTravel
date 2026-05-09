import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

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

// ─── LoginScreen ──────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AnimationController _ctrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    const starts = [0.0, 0.10, 0.20, 0.32, 0.44, 0.56];
    _fades = starts
        .map(
          (s) => CurvedAnimation(
            parent: _ctrl,
            curve: Interval(
              s,
              (s + 0.45).clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          ),
        )
        .toList();
    _slides = starts
        .map(
          (s) => Tween<Offset>(begin: const Offset(0, 0.20), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _ctrl,
                  curve: Interval(
                    s,
                    (s + 0.45).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
        )
        .toList();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) => FadeTransition(
    opacity: _fades[i],
    child: SlideTransition(position: _slides[i], child: child),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      // Le StreamBuilder dans main.dart redirige automatiquement vers HomeScreen
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          message = 'Utilisateur inexistant ou identifiants incorrects.';
          break;
        case 'wrong-password':
          message = 'Vérifier votre mot de passe.';
          break;
        case 'invalid-email':
          message = 'Adresse e-mail invalide.';
          break;
        case 'too-many-requests':
          message = 'Trop de tentatives. Réessayez plus tard.';
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
                    // ── Back + brand header ────────────────────────────────
                    _reveal(
                      0,
                      Row(
                        children: [
                          if (Navigator.of(context).canPop())
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppPalette.surfaceRaised
                                      : AppPalette.parchmentCard,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? AppPalette.border
                                        : AppPalette.parchmentBorder,
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  size: 18,
                                  color: onSurface.withValues(alpha: 0.70),
                                ),
                              ),
                            ),
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

                    const SizedBox(height: 48),

                    // ── Title ──────────────────────────────────────────────
                    _reveal(
                      1,
                      Text(
                        'Bon retour,\nTraveler.',
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
                        'Connectez-vous pour reprendre votre voyage.',
                        style: AppFonts.outfit(
                          size: 13,
                          color: onSurface.withValues(alpha: 0.50),
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Section label ──────────────────────────────────────
                    _reveal(
                      2,
                      _SectionLabel(label: 'CONNEXION', accent: accent),
                    ),
                    const SizedBox(height: 14),

                    // ── Email ──────────────────────────────────────────────
                    _reveal(
                      2,
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
                      3,
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
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Champ requis' : null,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Forgot password ────────────────────────────────────
                    _reveal(
                      3,
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            // TODO: mot de passe oublié
                          },
                          child: Text(
                            'Mot de passe oublié ?',
                            style: AppFonts.outfit(
                              size: 12,
                              color: accent,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Submit button ──────────────────────────────────────
                    _reveal(
                      4,
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
                                  'SE CONNECTER',
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

                    const SizedBox(height: 28),

                    // ── Create account link ────────────────────────────────
                    _reveal(
                      5,
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: RichText(
                            text: TextSpan(
                              style: AppFonts.outfit(
                                size: 13,
                                color: onSurface.withValues(alpha: 0.50),
                              ),
                              children: [
                                const TextSpan(text: 'Pas encore de compte ? '),
                                TextSpan(
                                  text: "S'inscrire",
                                  style: AppFonts.outfit(
                                    size: 13,
                                    color: accent,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
