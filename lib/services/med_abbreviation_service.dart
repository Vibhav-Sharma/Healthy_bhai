/// Maps medical prescription abbreviations and timing phrases to
/// concrete clock-time schedules for notification scheduling.
class MedAbbreviationService {
  /// A single scheduled time slot.
  /// [hour] and [minute] are in 24-hour format.
  /// [label] is a human-readable description like "Before Breakfast".
  static const List<_TimeSlot> _empty = [];

  // ─── ABBREVIATION → TIME SLOTS ───

  static final Map<String, List<_TimeSlot>> _abbreviationMap = {
    // ── Frequency-based ──
    'od':    [_TimeSlot(9, 0, 'Morning')],
    'om':    [_TimeSlot(9, 0, 'Morning')],
    'on':    [_TimeSlot(21, 0, 'Night')],
    'bd':    [_TimeSlot(9, 0, 'Morning'), _TimeSlot(21, 0, 'Night')],
    'bid':   [_TimeSlot(9, 0, 'Morning'), _TimeSlot(21, 0, 'Night')],
    'tds':   [_TimeSlot(8, 0, 'Morning'), _TimeSlot(14, 0, 'Afternoon'), _TimeSlot(20, 0, 'Night')],
    'tid':   [_TimeSlot(8, 0, 'Morning'), _TimeSlot(14, 0, 'Afternoon'), _TimeSlot(20, 0, 'Night')],
    'qid':   [_TimeSlot(6, 0, 'Early Morning'), _TimeSlot(12, 0, 'Noon'), _TimeSlot(18, 0, 'Evening'), _TimeSlot(22, 0, 'Night')],
    'qds':   [_TimeSlot(6, 0, 'Early Morning'), _TimeSlot(12, 0, 'Noon'), _TimeSlot(18, 0, 'Evening'), _TimeSlot(22, 0, 'Night')],

    // ── Bedtime ──
    'hs':    [_TimeSlot(22, 0, 'Bedtime')],
    'qhs':   [_TimeSlot(22, 0, 'Bedtime')],

    // ── Meal-relative ──
    'ac':    [_TimeSlot(7, 30, 'Before Breakfast'), _TimeSlot(12, 30, 'Before Lunch'), _TimeSlot(19, 0, 'Before Dinner')],
    'pc':    [_TimeSlot(8, 30, 'After Breakfast'), _TimeSlot(13, 30, 'After Lunch'), _TimeSlot(20, 0, 'After Dinner')],

    // ── Interval-based ──
    'q4h':   [_TimeSlot(6, 0, '6 AM'), _TimeSlot(10, 0, '10 AM'), _TimeSlot(14, 0, '2 PM'), _TimeSlot(18, 0, '6 PM'), _TimeSlot(22, 0, '10 PM')],
    'q6h':   [_TimeSlot(6, 0, '6 AM'), _TimeSlot(12, 0, '12 PM'), _TimeSlot(18, 0, '6 PM'), _TimeSlot(0, 0, '12 AM')],
    'q8h':   [_TimeSlot(6, 0, '6 AM'), _TimeSlot(14, 0, '2 PM'), _TimeSlot(22, 0, '10 PM')],
    'q12h':  [_TimeSlot(8, 0, '8 AM'), _TimeSlot(20, 0, '8 PM')],

    // ── As-needed / one-time (no scheduled alarm) ──
    'sos':   _empty,
    'prn':   _empty,
    'stat':  _empty,

    // ── Plain English timings ──
    'morning':          [_TimeSlot(9, 0, 'Morning')],
    'afternoon':        [_TimeSlot(14, 0, 'Afternoon')],
    'evening':          [_TimeSlot(18, 0, 'Evening')],
    'night':            [_TimeSlot(21, 0, 'Night')],
    'before breakfast': [_TimeSlot(6, 0, 'Before Breakfast')],
    'after breakfast':  [_TimeSlot(9, 0, 'After Breakfast')],
    'before lunch':     [_TimeSlot(12, 0, 'Before Lunch')],
    'after lunch':      [_TimeSlot(13, 30, 'After Lunch')],
    'before dinner':    [_TimeSlot(19, 0, 'Before Dinner')],
    'after dinner':     [_TimeSlot(21, 0, 'After Dinner')],
    'before meals':     [_TimeSlot(7, 30, 'Before Breakfast'), _TimeSlot(12, 30, 'Before Lunch'), _TimeSlot(19, 0, 'Before Dinner')],
    'after meals':      [_TimeSlot(8, 30, 'After Breakfast'), _TimeSlot(13, 30, 'After Lunch'), _TimeSlot(20, 0, 'After Dinner')],
    'with meals':       [_TimeSlot(8, 0, 'Breakfast'), _TimeSlot(13, 0, 'Lunch'), _TimeSlot(20, 0, 'Dinner')],
    'empty stomach':    [_TimeSlot(6, 0, 'Empty Stomach (Early Morning)')],
    'before bed':       [_TimeSlot(22, 0, 'Before Bed')],
    'at bedtime':       [_TimeSlot(22, 0, 'Bedtime')],
    'on waking':        [_TimeSlot(6, 0, 'On Waking')],
    'once daily':       [_TimeSlot(9, 0, 'Morning')],
    'twice daily':      [_TimeSlot(9, 0, 'Morning'), _TimeSlot(21, 0, 'Night')],
    'thrice daily':     [_TimeSlot(8, 0, 'Morning'), _TimeSlot(14, 0, 'Afternoon'), _TimeSlot(20, 0, 'Night')],
  };

  /// Given a raw frequency/timing string from a prescription, returns a list
  /// of [ScheduleTime]s (hour, minute, label) for notification scheduling.
  ///
  /// Example inputs: "BD", "TDS AC", "After meals", "Morning, Night", "Q6H"
  /// Returns an empty list for SOS/PRN/STAT (no scheduled reminder).
  static List<ScheduleTime> resolve(String rawText) {
    if (rawText.trim().isEmpty) return [];

    final lower = rawText.trim().toLowerCase();

    // 1. Check direct exact match first
    if (_abbreviationMap.containsKey(lower)) {
      return _abbreviationMap[lower]!
          .map((s) => ScheduleTime(hour: s.hour, minute: s.minute, label: s.label))
          .toList();
    }

    // 2. Try splitting by comma, space, '+', '/' and resolve each token
    final tokens = lower.split(RegExp(r'[,+/\s]+'));
    final Set<String> seenKeys = {};
    final List<ScheduleTime> result = [];

    for (final token in tokens) {
      final trimmed = token.trim();
      if (trimmed.isEmpty || seenKeys.contains(trimmed)) continue;
      seenKeys.add(trimmed);

      if (_abbreviationMap.containsKey(trimmed)) {
        for (final slot in _abbreviationMap[trimmed]!) {
          final st = ScheduleTime(hour: slot.hour, minute: slot.minute, label: slot.label);
          if (!result.any((r) => r.hour == st.hour && r.minute == st.minute)) {
            result.add(st);
          }
        }
      }
    }

    // 3. Also try multi-word phrase matching (e.g., "before breakfast")
    if (result.isEmpty) {
      for (final entry in _abbreviationMap.entries) {
        if (lower.contains(entry.key)) {
          for (final slot in entry.value) {
            final st = ScheduleTime(hour: slot.hour, minute: slot.minute, label: slot.label);
            if (!result.any((r) => r.hour == st.hour && r.minute == st.minute)) {
              result.add(st);
            }
          }
        }
      }
    }

    // 4. Sort by time
    result.sort((a, b) {
      final cmp = a.hour.compareTo(b.hour);
      return cmp != 0 ? cmp : a.minute.compareTo(b.minute);
    });

    return result;
  }

  /// Returns a human-readable description of the abbreviation, or null if not recognized.
  static String? describe(String rawText) {
    final lower = rawText.trim().toLowerCase();
    const descriptions = {
      'od': 'Once Daily',
      'bd': 'Twice Daily',
      'bid': 'Twice Daily',
      'tds': 'Three Times Daily',
      'tid': 'Three Times Daily',
      'qid': 'Four Times Daily',
      'qds': 'Four Times Daily',
      'hs': 'At Bedtime',
      'qhs': 'At Bedtime',
      'ac': 'Before Meals',
      'pc': 'After Meals',
      'sos': 'As Needed',
      'prn': 'As Needed',
      'stat': 'Immediately (One Time)',
      'q4h': 'Every 4 Hours',
      'q6h': 'Every 6 Hours',
      'q8h': 'Every 8 Hours',
      'q12h': 'Every 12 Hours',
      'om': 'Every Morning',
      'on': 'Every Night',
    };
    return descriptions[lower];
  }

  /// Whether this abbreviation means "as needed" (no scheduled reminder).
  static bool isAsNeeded(String rawText) {
    final lower = rawText.trim().toLowerCase();
    return lower == 'sos' || lower == 'prn' || lower == 'stat';
  }
}

/// Internal helper class for the static map.
class _TimeSlot {
  final int hour;
  final int minute;
  final String label;
  const _TimeSlot(this.hour, this.minute, this.label);
}

/// A resolved schedule time for notifications / calendar events.
class ScheduleTime {
  final int hour;
  final int minute;
  final String label;
  const ScheduleTime({required this.hour, required this.minute, required this.label});

  String get formatted {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  String toString() => '$label ($formatted)';
}
