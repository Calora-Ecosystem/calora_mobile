package ai.calora.steps

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.HealthConnectFeatures
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateGroupByPeriodRequest
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.Instant
import java.time.LocalDateTime
import java.time.Period
import java.time.ZoneId

enum class HealthConnectAvailability(val wire: String) {
    AVAILABLE("available"),
    UPDATE_REQUIRED("update_required"),
    NOT_INSTALLED("not_installed"),
    UNSUPPORTED("unsupported"),
}

data class HealthConnectToday(val steps: Int, val origins: Set<String>)

class HealthConnectSource(private val context: Context) {

    private var client: HealthConnectClient? = null

    fun availability(): HealthConnectAvailability = when (sdkStatus()) {
        HealthConnectClient.SDK_AVAILABLE -> HealthConnectAvailability.AVAILABLE
        HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> HealthConnectAvailability.UPDATE_REQUIRED
        else -> if (isProviderInstallable()) HealthConnectAvailability.NOT_INSTALLED else HealthConnectAvailability.UNSUPPORTED
    }

    private fun sdkStatus(): Int = try {
        HealthConnectClient.getSdkStatus(context, PROVIDER_PACKAGE)
    } catch (t: Throwable) {
        HealthConnectClient.SDK_UNAVAILABLE
    }

    private fun isProviderInstallable(): Boolean =
        android.os.Build.VERSION.SDK_INT in android.os.Build.VERSION_CODES.P..android.os.Build.VERSION_CODES.TIRAMISU &&
            isPlayStoreInstalled()

    private fun isPlayStoreInstalled(): Boolean = try {
        context.packageManager.getPackageInfo(PLAY_STORE_PACKAGE, 0)
        true
    } catch (t: Throwable) {
        false
    }

    private fun clientOrNull(): HealthConnectClient? {
        if (sdkStatus() != HealthConnectClient.SDK_AVAILABLE) return null
        return client ?: try {
            HealthConnectClient.getOrCreate(context, PROVIDER_PACKAGE).also { client = it }
        } catch (t: Throwable) {
            Log.w(TAG, "Health Connect client unavailable: ${t.message}")
            null
        }
    }

    fun requiredPermissions(): Set<String> {
        val permissions = mutableSetOf(READ_STEPS)
        if (backgroundReadAvailable()) permissions += HealthPermission.PERMISSION_READ_HEALTH_DATA_IN_BACKGROUND
        return permissions
    }

    fun backgroundReadAvailable(): Boolean = try {
        clientOrNull()?.features?.getFeatureStatus(HealthConnectFeatures.FEATURE_READ_HEALTH_DATA_IN_BACKGROUND) ==
            HealthConnectFeatures.FEATURE_STATUS_AVAILABLE
    } catch (t: Throwable) {
        false
    }

    suspend fun grantedPermissions(): Set<String> {
        val hc = clientOrNull() ?: return emptySet()
        return try {
            hc.permissionController.getGrantedPermissions()
        } catch (t: Throwable) {
            Log.w(TAG, "getGrantedPermissions failed: ${t.message}")
            emptySet()
        }
    }

    suspend fun isConnected(): Boolean = READ_STEPS in grantedPermissions()

    suspend fun today(zone: ZoneId, now: Instant): HealthConnectToday? {
        val hc = clientOrNull() ?: return null
        if (!isConnected()) return null
        val start = now.atZone(zone).toLocalDate().atStartOfDay(zone).toInstant()
        if (!now.isAfter(start)) return HealthConnectToday(0, emptySet())
        return try {
            val result = hc.aggregate(
                AggregateRequest(
                    metrics = setOf(StepsRecord.COUNT_TOTAL),
                    timeRangeFilter = TimeRangeFilter.between(start, now),
                ),
            )
            HealthConnectToday(
                steps = (result[StepsRecord.COUNT_TOTAL] ?: 0L).coerceIn(0L, Int.MAX_VALUE.toLong()).toInt(),
                origins = result.dataOrigins.map { it.packageName }.toSet(),
            )
        } catch (t: Throwable) {
            Log.w(TAG, "Health Connect today read failed: ${t.message}")
            null
        }
    }

    suspend fun daily(zone: ZoneId, today: Int, days: Int): Map<Int, Int>? {
        val hc = clientOrNull() ?: return null
        if (!isConnected()) return null
        val todayDate = DayKeys.toDate(today)
        val start = todayDate.minusDays((days - 1).toLong()).atStartOfDay()
        val end = LocalDateTime.now(zone)
        if (!end.isAfter(start)) return emptyMap()
        return try {
            val buckets = hc.aggregateGroupByPeriod(
                AggregateGroupByPeriodRequest(
                    metrics = setOf(StepsRecord.COUNT_TOTAL),
                    timeRangeFilter = TimeRangeFilter.between(start, end),
                    timeRangeSlicer = Period.ofDays(1),
                ),
            )
            buildMap {
                for (bucket in buckets) {
                    val steps = bucket.result[StepsRecord.COUNT_TOTAL] ?: continue
                    if (steps <= 0) continue
                    put(DayKeys.of(bucket.startTime.toLocalDate()), steps.coerceAtMost(Int.MAX_VALUE.toLong()).toInt())
                }
            }
        } catch (t: Throwable) {
            Log.w(TAG, "Health Connect history read failed: ${t.message}")
            null
        }
    }

    suspend fun recentOrigins(zone: ZoneId, now: Instant, days: Long): Set<String>? {
        val hc = clientOrNull() ?: return null
        if (!isConnected()) return null
        val start = now.atZone(zone).toLocalDate().minusDays(days).atStartOfDay(zone).toInstant()
        return try {
            hc.aggregate(
                AggregateRequest(
                    metrics = setOf(StepsRecord.COUNT_TOTAL),
                    timeRangeFilter = TimeRangeFilter.between(start, now),
                ),
            ).dataOrigins.map { it.packageName }.toSet()
        } catch (t: Throwable) {
            Log.w(TAG, "Health Connect origins read failed: ${t.message}")
            null
        }
    }

    fun settingsIntent(): Intent? {
        val intent = Intent(HealthConnectClient.ACTION_HEALTH_CONNECT_SETTINGS)
        return if (intent.resolveActivity(context.packageManager) != null) intent else null
    }

    fun manageDataIntent(): Intent? = try {
        HealthConnectClient.getHealthConnectManageDataIntent(context, PROVIDER_PACKAGE)
    } catch (t: Throwable) {
        null
    }

    fun storeIntent(): Intent = Intent(Intent.ACTION_VIEW).apply {
        setPackage(PLAY_STORE_PACKAGE)
        data = Uri.parse("market://details?id=$PROVIDER_PACKAGE&url=healthconnect%3A%2F%2Fonboarding")
        putExtra("overlay", true)
        putExtra("callerId", context.packageName)
    }

    companion object {
        private const val TAG = "CaloraSteps.HC"
        const val PROVIDER_PACKAGE = "com.google.android.apps.healthdata"
        const val PLAY_STORE_PACKAGE = "com.android.vending"
        val READ_STEPS: String = HealthPermission.getReadPermission(StepsRecord::class)
    }
}
