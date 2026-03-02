package com.example.flutter_application_1

import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * MainActivity — Flutter host activity with Health Connect MethodChannel.
 *
 * Extends FlutterFragmentActivity (not FlutterActivity) because
 * registerForActivityResult() requires ComponentActivity, which
 * FlutterFragmentActivity inherits from via FragmentActivity.
 *
 * Bridges Flutter ↔ Kotlin via MethodChannel("com.healthybhai/health_connect").
 *
 * Supported methods:
 *   - "isAvailable" → returns availability status string
 *   - "requestPermissions" → launches permission request UI, returns bool
 *   - "hasPermissions" → checks current permission state, returns bool
 *   - "fetchDailySummary" → fetches & returns aggregated health data map
 */
class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val CHANNEL = "com.healthybhai/health_connect"
        private const val TAG = "MainActivity"
    }

    private lateinit var healthConnectManager: HealthConnectManager
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // Pending MethodChannel result for permission request callback
    private var pendingPermissionResult: MethodChannel.Result? = null

    // Health Connect permission launcher using the modern Activity Result API
    private val healthPermissionLauncher = registerForActivityResult(
        androidx.health.connect.client.PermissionController.createRequestPermissionResultContract()
    ) { grantedPermissions: Set<String> ->
        val allGranted = HealthConnectManager.REQUIRED_PERMISSIONS.all { it in grantedPermissions }
        pendingPermissionResult?.success(allGranted)
        pendingPermissionResult = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        healthConnectManager = HealthConnectManager(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> handleIsAvailable(result)
                "requestPermissions" -> handleRequestPermissions(result)
                "hasPermissions" -> handleHasPermissions(result)
                "fetchDailySummary" -> handleFetchDailySummary(call.argument("userId"), result)
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Check if Health Connect is available on this device.
     */
    private fun handleIsAvailable(result: MethodChannel.Result) {
        try {
            val status = healthConnectManager.checkAvailability()
            result.success(status)
        } catch (e: Exception) {
            Log.e(TAG, "Error checking availability", e)
            result.error("AVAILABILITY_ERROR", e.message, null)
        }
    }

    /**
     * Request Health Connect permissions using the Health Connect permission launcher.
     */
    private fun handleRequestPermissions(result: MethodChannel.Result) {
        try {
            pendingPermissionResult = result
            healthPermissionLauncher.launch(HealthConnectManager.REQUIRED_PERMISSIONS)
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting permissions", e)
            pendingPermissionResult = null
            result.error("PERMISSION_ERROR", e.message, null)
        }
    }

    /**
     * Check if all required Health Connect permissions are currently granted.
     */
    private fun handleHasPermissions(result: MethodChannel.Result) {
        scope.launch {
            try {
                val granted = healthConnectManager.hasAllPermissions()
                result.success(granted)
            } catch (e: Exception) {
                Log.e(TAG, "Error checking permissions", e)
                result.error("PERMISSION_ERROR", e.message, null)
            }
        }
    }

    /**
     * Fetch today's aggregated health data and return as a Map.
     */
    private fun handleFetchDailySummary(userId: String?, result: MethodChannel.Result) {
        if (userId == null) {
            result.error("INVALID_ARGUMENT", "userId is required", null)
            return
        }
        scope.launch {
            try {
                val summary = healthConnectManager.fetchDailySummary(userId)
                result.success(summary)
            } catch (e: Exception) {
                Log.e(TAG, "Error fetching daily summary", e)
                result.error("FETCH_ERROR", e.message, null)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }
}
