import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'med_abbreviation_service.dart';

/// Adds medication reminder events to the patient's Google Calendar.
///
/// Uses the Google Calendar REST API with the OAuth token obtained
/// from the existing Google Sign-In session.
class CalendarService {
  static const _calendarApiBase = 'https://www.googleapis.com/calendar/v3';

  /// Get an authenticated HTTP client using Google Sign-In.
  /// Requests the calendar scope so we can create events.
  static Future<Map<String, String>?> _getAuthHeaders() async {
    try {
      final googleSignIn = GoogleSignIn(scopes: [
        'https://www.googleapis.com/auth/calendar.events',
      ]);

      // Try silent sign-in first (user already signed in)
      GoogleSignInAccount? account = await googleSignIn.signInSilently();

      // If not silently available, prompt interactive sign-in
      account ??= await googleSignIn.signIn();

      if (account == null) return null; // User cancelled

      final auth = await account.authentication;
      final accessToken = auth.accessToken;

      if (accessToken == null) return null;

      return {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };
    } catch (e) {
      debugPrint('CalendarService auth error: $e');
      return null;
    }
  }

  /// Add a recurring daily medicine event to Google Calendar.
  ///
  /// [medicineName] — Name of the medicine
  /// [dosage] — Dosage information
  /// [scheduleTime] — When to schedule (from MedAbbreviationService)
  /// [durationDays] — How many days the recurrence should last (default 7)
  static Future<bool> addMedicineEvent({
    required String medicineName,
    required String dosage,
    required ScheduleTime scheduleTime,
    int durationDays = 7,
  }) async {
    final headers = await _getAuthHeaders();
    if (headers == null) {
      throw Exception('Google Sign-In failed. Please sign in with Google to add calendar events.');
    }

    final now = DateTime.now();
    // Start date: today or tomorrow if time already passed
    DateTime startDate = DateTime(now.year, now.month, now.day, scheduleTime.hour, scheduleTime.minute);
    if (startDate.isBefore(now)) {
      startDate = startDate.add(const Duration(days: 1));
    }

    // End date for recurrence
    final endRecurrence = startDate.add(Duration(days: durationDays));

    // Event start and end (15 minute event)
    final eventEnd = startDate.add(const Duration(minutes: 15));

    // Format dates for Google Calendar API
    final startIso = startDate.toIso8601String();
    final endIso = eventEnd.toIso8601String();
    final untilDate = '${endRecurrence.year}${endRecurrence.month.toString().padLeft(2, '0')}${endRecurrence.day.toString().padLeft(2, '0')}T235959Z';

    final eventBody = {
      'summary': '💊 Take $medicineName ($dosage)',
      'description': '${scheduleTime.label}: Take $medicineName $dosage\n\n'
          'Set by Healthy Bhai app from your scanned prescription.',
      'start': {
        'dateTime': startIso,
        'timeZone': 'Asia/Kolkata',
      },
      'end': {
        'dateTime': endIso,
        'timeZone': 'Asia/Kolkata',
      },
      'recurrence': [
        'RRULE:FREQ=DAILY;UNTIL=$untilDate',
      ],
      'reminders': {
        'useDefault': false,
        'overrides': [
          {'method': 'popup', 'minutes': 5},
        ],
      },
      'colorId': '2', // Sage green
    };

    try {
      final response = await http.post(
        Uri.parse('$_calendarApiBase/calendars/primary/events'),
        headers: headers,
        body: jsonEncode(eventBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('CalendarService: Created event for $medicineName at ${scheduleTime.formatted}');
        return true;
      } else {
        debugPrint('CalendarService error: ${response.statusCode} ${response.body}');
        throw Exception('Failed to create calendar event (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('CalendarService error: $e');
      rethrow;
    }
  }

  /// Parse a duration string like "5 days", "1 week", "2 weeks", "1 month"
  /// into total number of days. Defaults to 7 days if unrecognized.
  static int parseDurationToDays(String duration) {
    if (duration.isEmpty) return 7;

    final lower = duration.toLowerCase().trim();

    // Try to extract a number
    final numMatch = RegExp(r'(\d+)').firstMatch(lower);
    final num = numMatch != null ? int.tryParse(numMatch.group(1)!) ?? 1 : 1;

    if (lower.contains('day')) return num;
    if (lower.contains('week')) return num * 7;
    if (lower.contains('month')) return num * 30;
    if (lower.contains('year')) return num * 365;

    return 7; // Default
  }
}
