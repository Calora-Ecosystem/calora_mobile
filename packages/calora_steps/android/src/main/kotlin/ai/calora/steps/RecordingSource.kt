package ai.calora.steps

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.content.ContextCompat
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.fitness.FitnessLocal
import com.google.android.gms.fitness.LocalRecordingClient
import com.google.android.gms.fitness.data.LocalDataType
import com.google.android.gms.fitness.data.LocalField
import com.google.android.gms.fitness.request.LocalDataReadRequest
import kotlinx.coroutines.tasks.await
import java.time.Instant
import java.time.ZoneId
import java.util.concurrent.TimeUnit

class RecordingSource(private val context: Context, private val store: StepStore) {

    private val client: LocalRecordingClient? by lazy {
        try {
            FitnessLocal.getLocalRecordingClient(context)
        } catch (t: Throwable) {
            Log.w(TAG, "Recording API unavailable: ${t.message}")
            null
        }
    }

    fun isAvailable(): Boolean = try {
        GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(
            context,
            LocalRecordingClient.LOCAL_RECORDING_CLIENT_MIN_VERSION_CODE,
        ) == ConnectionResult.SUCCESS
    } catch (t: Throwable) {
        false
    }

    private fun hasPermission(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACTIVITY_RECOGNITION) ==
            PackageManager.PERMISSION_GRANTED

    val isSubscribed: Boolean get() = store.recordingSubscribedAt > 0L

    suspend fun ensureSubscribed(): Boolean {
        if (isSubscribed) return true
        return subscribe()
    }

    suspend fun resubscribe(): Boolean = subscribe()

    private suspend fun subscribe(): Boolean {
        if (!hasPermission() || !isAvailable()) return false
        val recording = client ?: return false
        return try {
            recording.subscribe(LocalDataType.TYPE_STEP_COUNT_DELTA).await()
            store.recordingSubscribedAt = System.currentTimeMillis()
            true
        } catch (t: Throwable) {
            Log.w(TAG, "Recording API subscribe failed: ${t.message}")
            false
        }
    }

    fun coversDay(startOfDay: Long): Boolean = store.recordingSubscribedAt in 1..startOfDay

    suspend fun today(zone: ZoneId, now: Instant): Int? {
        val start = now.atZone(zone).toLocalDate().atStartOfDay(zone).toInstant()
        if (!now.isAfter(start)) return 0
        return read(start, now)?.values?.sum()
    }

    suspend fun daily(zone: ZoneId, today: Int, days: Int): Map<Int, Int>? {
        val now = Instant.now()
        val start = DayKeys.toDate(today).minusDays((days - 1).toLong()).atStartOfDay(zone).toInstant()
        val buckets = read(start, now) ?: return null
        return buckets.entries
            .associate { (bucketStart, steps) ->
                DayKeys.of(Instant.ofEpochMilli(bucketStart).atZone(zone).toLocalDate()) to steps
            }
            .filterValues { it > 0 }
    }

    private suspend fun read(start: Instant, end: Instant): Map<Long, Int>? {
        if (!hasPermission() || !ensureSubscribed()) return null
        val recording = client ?: return null
        val request = LocalDataReadRequest.Builder()
            .aggregate(LocalDataType.TYPE_STEP_COUNT_DELTA)
            .bucketByTime(1, TimeUnit.DAYS)
            .setTimeRange(start.epochSecond, end.epochSecond, TimeUnit.SECONDS)
            .build()
        return try {
            val response = recording.readData(request).await()
            buildMap {
                for (bucket in response.buckets) {
                    var steps = 0
                    for (dataSet in bucket.dataSets) {
                        for (point in dataSet.dataPoints) {
                            steps += point.getValue(LocalField.FIELD_STEPS).asInt()
                        }
                    }
                    put(bucket.getStartTime(TimeUnit.MILLISECONDS), steps)
                }
            }
        } catch (t: Throwable) {
            Log.w(TAG, "Recording API read failed: ${t.message}")
            null
        }
    }

    companion object {
        private const val TAG = "CaloraSteps.Recording"
    }
}
