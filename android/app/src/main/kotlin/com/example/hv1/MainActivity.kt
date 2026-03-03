package com.example.hv1

import android.os.Bundle
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.health.connect.client.PermissionController
import androidx.lifecycle.lifecycleScope
import com.example.flutter_application_1.HealthConnectManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL = "com.healthybhai/health_connect"
    }

    private lateinit var healthManager: HealthConnectManager
    private lateinit var permissionLauncher: ActivityResultLauncher<Set<String>>

    // Holds the MethodChannel result while waiting for the permission activity to return
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        healthManager = HealthConnectManager(this)

        // Register the permission launcher BEFORE the activity is STARTED
        val contract = PermissionController.createRequestPermissionResultContract()
        permissionLauncher = registerForActivityResult(contract) { granted ->
            lifecycleScope.launch {
                try {
                    val allGranted = healthManager.hasAllPermissions()
                    pendingPermissionResult?.success(allGranted)
                } catch (e: Exception) {
                    pendingPermissionResult?.error("PERMISSION_ERROR", e.message, null)
                }
                pendingPermissionResult = null
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> {
                        try {
                            val status = healthManager.checkAvailability()
                            result.success(status)
                        } catch (e: Exception) {
                            Log.e(TAG, "isAvailable error", e)
                            result.error("AVAILABILITY_ERROR", e.message, null)
                        }
                    }

                    "hasPermissions" -> {
                        lifecycleScope.launch {
                            try {
                                val has = healthManager.hasAllPermissions()
                                result.success(has)
                            } catch (e: Exception) {
                                Log.e(TAG, "hasPermissions error", e)
                                result.error("PERMISSION_ERROR", e.message, null)
                            }
                        }
                    }

                    "requestPermissions" -> {
                        try {
                            pendingPermissionResult = result
                            permissionLauncher.launch(HealthConnectManager.REQUIRED_PERMISSIONS)
                        } catch (e: Exception) {
                            Log.e(TAG, "requestPermissions error", e)
                            pendingPermissionResult = null
                            result.error("PERMISSION_ERROR", e.message, null)
                        }
                    }

                    "fetchDailySummary" -> {
                        val userId = call.argument<String>("userId") ?: ""
                        lifecycleScope.launch {
                            try {
                                val summary = healthManager.fetchDailySummary(userId)
                                result.success(summary)
                            } catch (e: Exception) {
                                Log.e(TAG, "fetchDailySummary error", e)
                                result.error("FETCH_ERROR", e.message, null)
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
