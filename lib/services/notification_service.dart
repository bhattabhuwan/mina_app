import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    // ✅ Changed: .initialize() now expects named parameters
    await _notifications.initialize(settings: settings);
  }

  static Future<void> showImmediateNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails('health_tips', 'Health Tips',
            importance: Importance.high, priority: Priority.high);
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    // ✅ Changed: .show() now uses named parameters
    await _notifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  static Future<void> scheduleDailyTips() async {
    await cancelAllNotifications();

    final tips = [
      'Drink 8 glasses of water today!',
      'Take a 10-minute walk after lunch.',
      'Stretch your neck and back every hour.',
      'Practice deep breathing for 5 minutes.',
      'Eat a colorful meal with vegetables.',
      'Get 7-8 hours of sleep tonight.',
      'Wash your hands frequently.',
      'Limit screen time before bed.',
    ];

    const List<int> hours = [9, 11, 13, 16, 19];
    final now = tz.TZDateTime.now(tz.local);
    final random = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < hours.length; i++) {
      final tipIndex = (random + i) % tips.length;
      final title = '🌿 Daily Health Tip';
      final body = tips[tipIndex];
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hours[i],
        0,
      );
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      await _scheduleNotification(i + 1, title, body, scheduledTime);
    }
  }

  static Future<void> _scheduleNotification(
      int id, String title, String body, tz.TZDateTime scheduledTime) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails('health_tips', 'Health Tips',
            importance: Importance.high, priority: Priority.high);
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    // ✅ Changed: .zonedSchedule() now uses named parameters, and uiLocalNotificationDateInterpretation is removed.
    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}