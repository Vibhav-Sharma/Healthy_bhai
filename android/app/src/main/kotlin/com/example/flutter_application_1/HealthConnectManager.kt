package com.example.flutter_application_1

import android.content.Context
import android.os.Build
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.TotalCaloriesBurnedRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter

/**
 * HealthConnectManager — handles all Health Connect interactions.
 *
 * Uses suspend functions throughout for coroutine-based usage.
 * Provides methods to:
 *   - Check Health Connect availability
 *   - Get required permissions
 *   - Fetch today's steps, heart rate, sleep, and calories
 *   - Aggregate everything into a DailySummary map
 */
class HealthConnectManager(private val context: Context) {

    companion object {
        private const val TAG = "HealthConnectManager"

        /** All permissions this app needs from Health Connect */
        val REQUIRED_PERMISSIONS = setOf(
            HealthPermission.getReadPermission(StepsRecord::class),
            HealthPermission.getReadPermission(HeartRateRecord::class),
            HealthPermission.getReadPermission(SleepSessionRecord::class),
            HealthPermission.getReadPermission(TotalCaloriesBurnedRecord::class),
        )
    }

    private var healthConnectClient: HealthConnectClient? = null

    // ─── Availability ────────────────────────────────────────────────

    /**
     * Checks if Health Connect is available on this device.
     * Returns one of: "Available", "NotInstalled", "NotSupported"
     */
    fun checkAvailability(): String {
        val status = HealthConnectClient.getSdkStatus(context)
        return when (status) {
            HealthConnectClient.SDK_AVAILABLE -> {
                healthConnectClient = HealthConnectClient.getOrCreate(context)
                "Available"
            }
            HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> "NotInstalled"
            else -> "NotSupported"
        }
    }

    /**
     * Returns the HealthConnectClient, initializing it if needed.
     * Throws IllegalStateException if Health Connect is not available.
     */
    private fun getClient(): HealthConnectClient {
        if (healthConnectClient == null) {
            val status = checkAvailability()
            if (status != "Available") {
                throw IllegalStateException("Health Connect is not available: $status")
            }
        }
        return healthConnectClient!!
    }

    // ─── Permissions ─────────────────────────────────────────────────

    /**
     * Checks whether all required permissions have been granted.
     */
    suspend fun hasAllPermissions(): Boolean {
        return try {
            val client = getClient()
            val granted = client.permissionController.getGrantedPermissions()
            REQUIRED_PERMISSIONS.all { it in granted }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking permissions", e)
            false
        }
    }

    // ─── Data Fetching ───────────────────────────────────────────────

    /**
     * Fetches today's total step count using aggregation.
     * Returns null if no data is available.
     */
    suspend fun fetchTodaysSteps(): Long? {
        return try {
            val client = getClient()
            val now = Instant.now()
            val startOfDay = LocalDate.now()
                .atStartOfDay(ZoneId.systemDefault())
                .toInstant()

            val response = client.aggregate(
                AggregateRequest(
                    metrics = setOf(StepsRecord.COUNT_TOTAL),
                    timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                )
            )
            response[StepsRecord.COUNT_TOTAL]
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching steps", e)
            null
        }
    }

    /**
     * Fetches today's average heart rate by reading all HeartRateRecords
     * and computing the mean of all samples.
     * Returns null if no data is available.
     */
    suspend fun fetchTodaysAvgHeartRate(): Double? {
        return try {
            val client = getClient()
            val now = Instant.now()
            val startOfDay = LocalDate.now()
                .atStartOfDay(ZoneId.systemDefault())
                .toInstant()

            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = HeartRateRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                )
            )

            val allSamples = response.records.flatMap { record ->
                record.samples.map { it.beatsPerMinute }
            }

            if (allSamples.isEmpty()) {
                null
            } else {
                allSamples.average()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching heart rate", e)
            null
        }
    }

    /**
     * Fetches last night's sleep duration.
     *
     * Looks for SleepSessionRecords that overlap the window from
     * yesterday 6 PM to today 12 PM (noon), which covers typical
     * overnight sleep patterns.
     *
     * Returns sleep duration in hours (e.g., 7.5), or null if no data.
     */
    suspend fun fetchLastNightSleep(): Double? {
        return try {
            val client = getClient()
            val zone = ZoneId.systemDefault()
            val today = LocalDate.now()

            // Sleep window: yesterday 6 PM → today 12 PM
            val sleepWindowStart = today.minusDays(1)
                .atTime(18, 0)
                .atZone(zone)
                .toInstant()
            val sleepWindowEnd = today
                .atTime(12, 0)
                .atZone(zone)
                .toInstant()

            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = SleepSessionRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(sleepWindowStart, sleepWindowEnd)
                )
            )

            if (response.records.isEmpty()) {
                null
            } else {
                // Sum all sleep session durations
                var totalSleepMillis = 0L
                for (session in response.records) {
                    val start = session.startTime
                    val end = session.endTime
                    totalSleepMillis += (end.toEpochMilli() - start.toEpochMilli())
                }
                // Convert to hours with 1 decimal place precision
                val hours = totalSleepMillis / (1000.0 * 60.0 * 60.0)
                Math.round(hours * 10.0) / 10.0
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching sleep", e)
            null
        }
    }

    /**
     * Fetches today's total calories burned using aggregation.
     * Returns null if no data is available.
     */
    suspend fun fetchTodaysCalories(): Double? {
        return try {
            val client = getClient()
            val now = Instant.now()
            val startOfDay = LocalDate.now()
                .atStartOfDay(ZoneId.systemDefault())
                .toInstant()

            val response = client.aggregate(
                AggregateRequest(
                    metrics = setOf(TotalCaloriesBurnedRecord.ENERGY_TOTAL),
                    timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                )
            )

            response[TotalCaloriesBurnedRecord.ENERGY_TOTAL]?.inKilocalories
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching calories", e)
            null
        }
    }

    // ─── Aggregated Daily Summary ────────────────────────────────────

    /**
     * Fetches all health data and aggregates it into a DailySummary map.
     *
     * @param userId The patient/user ID to include in the summary.
     * @return A Map<String, Any?> containing the daily summary data,
     *         ready to be sent across the MethodChannel.
     */
    suspend fun fetchDailySummary(userId: String): Map<String, Any?> {
        val steps = fetchTodaysSteps()
        val heartRate = fetchTodaysAvgHeartRate()
        val sleep = fetchLastNightSleep()
        val calories = fetchTodaysCalories()

        val today = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)
        val syncedAt = ZonedDateTime.now().format(DateTimeFormatter.ISO_OFFSET_DATE_TIME)

        val hasAnyData = steps != null || heartRate != null || sleep != null || calories != null

        return mapOf(
            "userId" to userId,
            "date" to today,
            "totalSteps" to (steps ?: 0L),
            "avgHeartRate" to (heartRate?.let { Math.round(it * 10.0) / 10.0 } ?: 0.0),
            "sleepHours" to (sleep ?: 0.0),
            "calories" to (calories?.let { Math.round(it * 10.0) / 10.0 } ?: 0.0),
            "syncedAt" to syncedAt,
            "hasData" to hasAnyData,
        )
    }
}
