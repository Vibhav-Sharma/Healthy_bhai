import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'daily_summary.dart';

/// HealthConnectService — Flutter-side bridge to the Kotlin Health Connect code.
///
/// Communicates via MethodChannel('com.healthybhai/health_connect') to call
/// the native HealthConnectManager methods in MainActivity.kt.
///
/// Usage:
///   final service = HealthConnectService();
///   final available = await service.isAvailable();
///   final granted = await service.requestPermissions();
///   final summary = await service.fetchDailySummary('patient123');
class HealthConnectService {
  static const MethodChannel _channel =
      MethodChannel('com.healthybhai/health_connect');

  // ─── Availability ──────────────────────────────────────────────

  /// Checks if Health Connect is available on this device.
  ///
  /// Returns one of: "Available", "NotInstalled", "NotSupported"
  /// Returns "NotSupported" on iOS or web.
  Future<String> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<String>('isAvailable');
      return result ?? 'NotSupported';
    } on PlatformException catch (e) {
      debugPrint('HealthConnect: availability check failed: ${e.message}');
      return 'NotSupported';
    } on MissingPluginException {
      // Running on a platform that doesn't have the native code (iOS/web)
      debugPrint('HealthConnect: platform not supported');
      return 'NotSupported';
    }
  }

  // ─── Permissions ───────────────────────────────────────────────

  /// Requests Health Connect permissions from the user.
  ///
  /// Returns true if all required permissions were granted.
  /// Returns false if the user denied any permission.
  Future<bool> requestPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('HealthConnect: permission request failed: ${e.message}');
      return false;
    } on MissingPluginException {
      debugPrint('HealthConnect: platform not supported');
      return false;
    }
  }

  /// Checks if all required permissions are currently granted.
  Future<bool> hasPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('HealthConnect: permission check failed: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  // ─── Data Fetching ─────────────────────────────────────────────

  /// Fetches today's aggregated health data from Health Connect.
  ///
  /// Returns a [DailySummary] containing steps, heart rate, sleep, and calories.
  /// The [hasData] field indicates whether any actual data was found.
  ///
  /// Throws [HealthConnectException] if the fetch fails for a reason
  /// other than missing data (e.g., permissions revoked, HC unavailable).
  Future<DailySummary> fetchDailySummary(String userId) async {
    try {
      final result = await _channel.invokeMethod<Map>(
        'fetchDailySummary',
        {'userId': userId},
      );

      if (result == null) {
        throw HealthConnectException('No data returned from Health Connect');
      }

      final map = Map<String, dynamic>.from(result);
      return DailySummary.fromMap(map);
    } on PlatformException catch (e) {
      debugPrint('HealthConnect: fetch failed: ${e.code} - ${e.message}');
      throw HealthConnectException(
        e.message ?? 'Failed to fetch health data',
        code: e.code,
      );
    } on MissingPluginException {
      throw HealthConnectException(
        'Health Connect is not available on this platform',
        code: 'PLATFORM_NOT_SUPPORTED',
      );
    }
  }
}

/// Exception type for Health Connect errors.
class HealthConnectException implements Exception {
  final String message;
  final String? code;

  HealthConnectException(this.message, {this.code});

  @override
  String toString() => 'HealthConnectException($code): $message';
}
