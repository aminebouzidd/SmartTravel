import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/global_params.dart';
import 'firebase_options.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/signup_screen.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';
import 'utils/app_l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Déjà initialisé (hot restart) — on ignore
    }
  }

  // Lire le mode (Jour/Nuit) depuis Firebase Realtime Database
  bool firebaseDarkMode = false;
  try {
    final modeSnapshot = await FirebaseDatabase.instance
        .ref()
        .child('mode')
        .get()
        .timeout(const Duration(seconds: 5));
    firebaseDarkMode =
        modeSnapshot.exists && modeSnapshot.value.toString() == 'Nuit';
  } catch (_) {
    // Timeout ou pas de connexion → on garde la valeur par défaut false
  }

  // Initialiser le service de notifications et programmer le rappel si activé
  await NotificationService.instance.initialize();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  final prefs = await SharedPreferences.getInstance();
  // Appliquer le mode lu depuis Firebase (priorité sur SharedPreferences)
  await prefs.setBool('isDarkMode', firebaseDarkMode);
  // Initialiser GlobalParams avec le mode Firebase
  GlobalParams.themeActuel.setMode(firebaseDarkMode ? 'Nuit' : 'Jour');
  // Programmer la notification si elle était activée lors de la dernière session
  final notifEnabled = prefs.getBool('notificationsEnabled') ?? true;
  if (notifEnabled) {
    await NotificationService.instance.requestPermission();
    await NotificationService.instance.scheduleDailyReminder();
  }
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SmartTravelApp(),
    ),
  );
}

class SmartTravelApp extends ConsumerStatefulWidget {
  const SmartTravelApp({super.key});

  @override
  ConsumerState<SmartTravelApp> createState() => _SmartTravelAppState();
}

class _SmartTravelAppState extends ConsumerState<SmartTravelApp> {
  @override
  void initState() {
    super.initState();
    // S'abonner au ChangeNotifier pour reconstruire quand le thème change
    GlobalParams.themeActuel.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppL10n.forLang(settings.appLanguage);
    return MaterialApp(
      title: l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(settings.appLanguage),
      supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const SignupScreen();
        },
      ),
    );
  }
}
