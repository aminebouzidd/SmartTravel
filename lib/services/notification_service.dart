import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Gère les notifications locales périodiques de rappel.
///
/// Stratégie : une notification quotidienne à 10h invitant l'utilisateur
/// à scanner ses documents du jour (menus, reçus, panneaux).
/// Elle est annulée dès que l'utilisateur désactive les notifications
/// dans les paramètres.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _kDailyReminderId = 42;
  static const String _kChannelId = 'smart_travel_reminders';
  static const String _kChannelName = 'Rappels de voyage';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Initialisation ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialiser les fuseaux horaires (requis pour zonedSchedule)
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
    debugPrint('[NOTIF] NotificationService initialisé');
  }

  // ── API publique ─────────────────────────────────────────────────────────────

  /// Demande la permission système (Android 13+ / iOS).
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// Programme la notification quotidienne de rappel.
  /// Appelé quand l'utilisateur active les notifications dans les paramètres.
  Future<void> scheduleDailyReminder() async {
    await initialize();
    // Annuler l'éventuelle ancienne avant de reprogrammer
    await _plugin.cancel(_kDailyReminderId);

    final androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: 'Rappels quotidiens pour utiliser Smart Travel',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      styleInformation: const BigTextStyleInformation(
        'Scannez vos menus, reçus et panneaux pour profiter pleinement de votre voyage ✈️',
      ),
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledTime = _nextInstanceOf(hour: 10, minute: 0);

    await _plugin.zonedSchedule(
      _kDailyReminderId,
      'Smart Travel 🌍',
      'Prêt à explorer ? Scannez vos documents du jour !',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('[NOTIF] Rappel quotidien programmé à 10h00');
  }

  /// Annule toutes les notifications programmées.
  /// Appelé quand l'utilisateur désactive les notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[NOTIF] Toutes les notifications annulées');
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Retourne le prochain [hour]h[minute] dans le fuseau local.
  tz.TZDateTime _nextInstanceOf({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[NOTIF] Notification tapée: ${response.payload}');
    // Navigation possible ici via un GlobalKey<NavigatorState> si besoin.
  }
}
