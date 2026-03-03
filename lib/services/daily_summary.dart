/// DailySummary — data model for aggregated health data from Health Connect.
///
/// Contains a day's worth of health metrics fetched from the smartwatch
/// via Google Fit → Health Connect pipeline.
class DailySummary {
  final String userId;
  final String date;
  final int totalSteps;
  final double avgHeartRate;
  final double sleepHours;
  final double calories;
  final String syncedAt;
  final bool hasData;

  DailySummary({
    required this.userId,
    required this.date,
    required this.totalSteps,
    required this.avgHeartRate,
    required this.sleepHours,
    required this.calories,
    required this.syncedAt,
    required this.hasData,
  });

  /// Create from the Map returned by the Kotlin MethodChannel.
  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      userId: map['userId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      totalSteps: (map['totalSteps'] as num?)?.toInt() ?? 0,
      avgHeartRate: (map['avgHeartRate'] as num?)?.toDouble() ?? 0.0,
      sleepHours: (map['sleepHours'] as num?)?.toDouble() ?? 0.0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      syncedAt: map['syncedAt'] as String? ?? '',
      hasData: map['hasData'] as bool? ?? false,
    );
  }

  /// Convert to a Map for Firestore upload.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date,
      'totalSteps': totalSteps,
      'avgHeartRate': avgHeartRate,
      'sleepHours': sleepHours,
      'calories': calories,
      'syncedAt': syncedAt,
    };
  }

  @override
  String toString() {
    return 'DailySummary(date: $date, steps: $totalSteps, hr: $avgHeartRate, '
        'sleep: ${sleepHours}h, cal: $calories, hasData: $hasData)';
  }
}
