import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Convertit un id de ticket en identifiant de notification int32 valide.
  static int notificationIdForTicket(String ticketId) =>
      ticketId.hashCode & 0x7fffffff;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _setLocalTimezone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();

    _initialized = true;
  }

  static Future<void> _setLocalTimezone() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      // Si le fuseau n'est pas détecté, on garde tz.local (UTC par défaut).
      debugPrint('Erreur détection fuseau horaire: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  static Future<void> scheduleWarrantyNotification({
    required int id,
    required String productName,
    required String storeName,
    required DateTime warrantyEndDate,
  }) async {
    // Garantie déjà expirée : aucun rappel nécessaire.
    final now = DateTime.now();
    if (warrantyEndDate.isBefore(now)) return;

    // id limité à int32 (exigence Android) pour éviter les débordements
    final safeId = id & 0x7fffffff;
    final expiryText = DateFormat('dd/MM/yyyy').format(warrantyEndDate);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'warranty_channel',
          'Rappels de Garantie',
          channelDescription: 'Notifications pour les fins de garantie',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final title = 'Garantie bientôt expirée';
    final body =
        'La garantie pour "$productName" ($storeName) expire le $expiryText';

    // Rappel 30 jours avant la fin de garantie.
    final notificationDate = warrantyEndDate.subtract(const Duration(days: 30));

    if (notificationDate.isAfter(now)) {
      // La date du rappel est dans le futur : on programme hors connexion.
      await _notifications.zonedSchedule(
        safeId,
        title,
        body,
        tz.TZDateTime.from(notificationDate, tz.local),
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode
            .inexactAllowWhileIdle, // FIX: Utilise des alarmes inexactes pour éviter le plantage
      );
    } else {
      // La garantie est déjà à moins de 30 jours : on notifie immédiatement.
      // (zonedSchedule refuserait une date passée, on passe donc par show.)
      await _notifications.show(safeId, title, body, platformChannelSpecifics);
    }
  }

  static Future<void> cancelWarrantyNotification(String ticketId) async {
    await _notifications.cancel(notificationIdForTicket(ticketId));
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification cliquée: ${response.payload}');
  }
}
