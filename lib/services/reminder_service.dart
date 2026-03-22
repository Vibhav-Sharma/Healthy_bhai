import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'med_abbreviation_service.dart';

class ReminderService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // SharedPreferences keys
  static const _keyMedicationReminders = 'pref_medication_reminders';
  static const _keyAppointmentReminders = 'pref_appointment_reminders';

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

  // ─── PREFERENCES ───

  /// Check if medication reminders are enabled (default: true).
  static Future<bool> isMedicationRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMedicationReminders) ?? true;
  }

  /// Toggle medication reminders on/off.
  static Future<void> setMedicationRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMedicationReminders, enabled);
    if (!enabled) {
      await cancelAllReminders();
    }
  }

  /// Check if appointment reminders are enabled (default: true).
  static Future<bool> isAppointmentRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAppointmentReminders) ?? true;
  }

  /// Toggle appointment reminders on/off.
  static Future<void> setAppointmentRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAppointmentReminders, enabled);
  }

  // ─── SMART SCHEDULING (using MedAbbreviationService) ───

  /// Schedule medicine reminders using raw prescription data.
  ///
  /// [frequency] — the medical abbreviation (e.g., "BD", "TDS", "Q6H")
  /// [timingContext] — meal context (e.g., "AC", "PC", "empty stomach")
  /// [fallbackTimings] — legacy Morning/Afternoon/Night list as fallback
  /// [endDate] — if provided, skip scheduling if medicine is already expired
  static Future<void> scheduleMedicineReminder({
    required int id,
    required String medicineName,
    required String dosage,
    String frequency = '',
    String timingContext = '',
    List<String> fallbackTimings = const [],
    DateTime? endDate,
  }) async {
    // Skip if medicine is already expired
    if (endDate != null && endDate.isBefore(DateTime.now())) return;

    // Check if medication reminders are enabled
    if (!await isMedicationRemindersEnabled()) return;

    // 1. Try to resolve from frequency abbreviation
    List<ScheduleTime> schedule = MedAbbreviationService.resolve(frequency);

    // 2. If frequency is SOS/PRN/STAT → no scheduled reminder
    if (MedAbbreviationService.isAsNeeded(frequency)) return;

    // 3. If timing context provides additional/override times, merge them
    if (timingContext.isNotEmpty) {
      final contextTimes = MedAbbreviationService.resolve(timingContext);
      if (schedule.isEmpty) {
        schedule = contextTimes;
      }
      // If we have both frequency and context, context refines the times
      // e.g., BD + AC → use the AC times (before meals) instead of generic BD
      if (contextTimes.isNotEmpty && frequency.isNotEmpty) {
        schedule = contextTimes;
      }
    }

    // 4. Fallback to legacy Morning/Afternoon/Night
    if (schedule.isEmpty && fallbackTimings.isNotEmpty) {
      for (final timing in fallbackTimings) {
        final resolved = MedAbbreviationService.resolve(timing);
        for (final t in resolved) {
          if (!schedule.any((s) => s.hour == t.hour && s.minute == t.minute)) {
            schedule.add(t);
          }
        }
      }
    }

    // 5. Ultimate fallback: Morning 9 AM
    if (schedule.isEmpty) {
      schedule = [const ScheduleTime(hour: 9, minute: 0, label: 'Morning')];
    }

    // 6. Schedule each alarm
    for (int i = 0; i < schedule.length; i++) {
      final time = schedule[i];
      final int notificationId = id * 10 + i; // Unique per medicine per time slot

      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: '💊 Medicine Reminder',
        body: 'Time to take $medicineName ($dosage)',
        scheduledDate: _nextInstanceOfTime(time.hour, time.minute),
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
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
    }
  }

  /// Schedule appointment reminder notification.
  static Future<void> scheduleAppointmentReminder({
    required int id,
    required String doctorName,
    required DateTime appointmentTime,
  }) async {
    if (!await isAppointmentRemindersEnabled()) return;

    // Remind 30 minutes before
    final reminderTime = appointmentTime.subtract(const Duration(minutes: 30));
    if (reminderTime.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: '🗓️ Upcoming Appointment',
      body: 'Your appointment with Dr. $doctorName is in 30 minutes.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_channel',
          'Appointment Reminders',
          channelDescription: 'Reminders for upcoming appointments',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
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

  /// Cancel a specific medicine's reminders (up to 10 time slots).
  static Future<void> cancelRemindersForMedicine(int baseId) async {
    for (int i = 0; i < 10; i++) {
      await _notificationsPlugin.cancel(id: baseId * 10 + i);
    }
  }
}
