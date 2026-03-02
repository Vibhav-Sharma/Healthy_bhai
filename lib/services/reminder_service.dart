import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Initialize timezone data for scheduled notifications
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if needed
      },
    );

    // Request permissions on Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  /// Schedule daily medicine reminders.
  /// [timings] is a list that can contain "Morning", "Afternoon", and/or "Night".
  static Future<void> scheduleMedicineReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required List<String> timings,
  }) async {
    for (String timing in timings) {
      int hour = 9; // Default Morning 9 AM
      int minute = 0;

      if (timing.toLowerCase().contains('afternoon')) {
        hour = 14; // 2 PM
      } else if (timing.toLowerCase().contains('night')) {
        hour = 20; // 8 PM
      }

      // Generate a somewhat unique ID for each timeline
      final int notificationId = id + hour;

      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'Medicine Reminder',
        body: 'Time to take $medicineName ($dosage)',
        scheduledDate: _nextInstanceOfTime(hour, minute),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_channel',
            'Medicine Reminders',
            channelDescription: 'Daily reminders to take medication',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
      );
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Cancels all scheduled notifications
  static Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }
}
