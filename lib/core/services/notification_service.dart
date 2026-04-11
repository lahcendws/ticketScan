import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Initialiser le service de notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialiser les fuseaux horaires
    tz.initializeTimeZones();

    // Configuration Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS
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

    // Demander les permissions
    await _requestPermissions();

    _initialized = true;
  }

  // Demander les permissions de notification
  static Future<void> _requestPermissions() async {
    // Android 13+ nécessite une permission explicite
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  // Afficher une notification immédiate
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'ticketscan_channel',
      'TicketScan Notifications',
      channelDescription: 'Notifications pour la gestion des tickets',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Programmer une notification pour la fin de garantie
  static Future<void> scheduleWarrantyNotification({
    required int id,
    required String productName,
    required String storeName,
    required DateTime warrantyEndDate,
  }) async {
    // Notifier 30 jours avant la fin de garantie
    final notificationDate = warrantyEndDate.subtract(const Duration(days: 30));
    final now = DateTime.now();

    // Si la date de notification est dans le passé, ne pas programmer
    if (notificationDate.isBefore(now)) {
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'warranty_channel',
      'Notifications de Garantie',
      channelDescription: 'Rappels de fin de garantie',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.zonedSchedule(
      id,
      'Garantie bientôt expirée',
      'La garantie pour "$productName" ($storeName) expire dans 30 jours',
      tz.TZDateTime.from(notificationDate, tz.local),
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Programmer une notification de rappel quotidien
  static Future<void> scheduleDailyWarrantyCheck() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'warranty_check_channel',
      'Vérification Quotidienne',
      channelDescription: 'Vérification quotidienne des garanties',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
      presentSound: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Programmer pour tous les jours à 9h du matin
    await _notifications.zonedSchedule(
      999,
      null,
      null,
      _nextInstanceOf9AM(),
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Calculer la prochaine occurrence de 9h du matin
  static tz.TZDateTime _nextInstanceOf9AM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Annuler une notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Annuler toutes les notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Obtenir les notifications programmées
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Gérer le clic sur une notification
  static void _onNotificationTapped(NotificationResponse response) {
    // Gérer la navigation vers la page appropriée
    print('Notification tapped: ${response.payload}');
  }

  // Afficher une notification de test
  static Future<void> showTestNotification() async {
    await showNotification(
      id: 0,
      title: 'TicketScan Test',
      body: 'Les notifications fonctionnent correctement!',
    );
  }
}
