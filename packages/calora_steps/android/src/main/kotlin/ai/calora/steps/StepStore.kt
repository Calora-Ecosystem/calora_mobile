package ai.calora.steps

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit

data class NotificationLabels(
    val channel: String = "Qadamlar",
    val title: String = "{steps} qadam",
    val goal: String = "Maqsad: {goal}",
    val kcal: String = "{kcal} kkal",
    val goalReached: String = "Maqsad bajarildi!",
    val locale: String = "uz",
)

data class ExternalReading(val steps: Int, val at: Long)

class StepStore(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences(FILE_NAME, Context.MODE_PRIVATE)

    fun loadState(clock: Clock): CounterState {
        if (!prefs.getBoolean(KEY_SCHEMA_V2, false)) return migrateLegacy(clock)
        return CounterState(
            day = prefs.getInt(KEY_DAY, 0),
            steps = prefs.getInt(KEY_STEPS, 0).coerceAtLeast(0),
            sensorSteps = prefs.getInt(KEY_SENSOR_STEPS, 0).coerceAtLeast(0),
            lastSensor = prefs.getFloat(KEY_LAST_SENSOR, CounterState.NO_READING),
            lastSensorAt = prefs.getLong(KEY_LAST_SENSOR_AT, 0L),
            sensorBoot = prefs.getInt(KEY_SENSOR_BOOT, CounterState.UNKNOWN_BOOT),
            pendingGap = prefs.getInt(KEY_PENDING_GAP, 0).coerceAtLeast(0),
            pendingGapUntil = prefs.getLong(KEY_PENDING_GAP_UNTIL, 0L),
            source = prefs.getString(KEY_SOURCE, CounterState.SOURCE_SENSOR) ?: CounterState.SOURCE_SENSOR,
        )
    }

    fun saveState(state: CounterState, sync: Boolean = false) {
        prefs.edit(commit = sync) {
            putBoolean(KEY_SCHEMA_V2, true)
            putInt(KEY_DAY, state.day)
            putInt(KEY_STEPS, state.steps)
            putInt(KEY_SENSOR_STEPS, state.sensorSteps)
            putFloat(KEY_LAST_SENSOR, state.lastSensor)
            putLong(KEY_LAST_SENSOR_AT, state.lastSensorAt)
            putInt(KEY_SENSOR_BOOT, state.sensorBoot)
            putInt(KEY_PENDING_GAP, state.pendingGap)
            putLong(KEY_PENDING_GAP_UNTIL, state.pendingGapUntil)
            putString(KEY_SOURCE, state.source)
        }
    }

    private fun migrateLegacy(clock: Clock): CounterState {
        val day = prefs.getInt(KEY_DAY, 0)
        if (day == 0) return CounterState()
        val lastSensor = prefs.getFloat(KEY_LAST_SENSOR, CounterState.NO_READING)
        val state = CounterState(
            day = day,
            steps = prefs.getInt(KEY_STEPS, 0).coerceAtLeast(0),
            lastSensor = lastSensor,
            lastSensorAt = if (lastSensor >= 0f) clock.startOfDay(day) else 0L,
            sensorBoot = if (lastSensor >= 0f) CounterState.MIGRATED_BOOT else CounterState.UNKNOWN_BOOT,
        )
        prefs.edit {
            remove(LEGACY_SYNC_BASE_SENSOR)
            remove(LEGACY_SYNC_BASE_STEPS)
            remove(LEGACY_MODE)
        }
        saveState(state)
        return state
    }

    fun history(): Map<Int, Int> = readDayMap(PREFIX_HISTORY)

    fun historyFor(day: Int): Int = prefs.getInt(PREFIX_HISTORY + day, 0)

    fun raiseHistory(day: Int, steps: Int) {
        if (steps <= 0) return
        val current = historyFor(day)
        if (steps > current) prefs.edit { putInt(PREFIX_HISTORY + day, steps) }
    }

    fun addHistory(day: Int, steps: Int) {
        if (steps <= 0) return
        prefs.edit { putInt(PREFIX_HISTORY + day, historyFor(day) + steps) }
    }

    fun external(): Map<Int, Int> = readDayMap(PREFIX_EXTERNAL)

    fun raiseExternal(values: Map<Int, Int>) {
        if (values.isEmpty()) return
        prefs.edit {
            for ((day, steps) in values) {
                if (steps > prefs.getInt(PREFIX_EXTERNAL + day, 0)) putInt(PREFIX_EXTERNAL + day, steps)
            }
        }
    }

    fun prune(today: Int, keepDays: Long = KEEP_DAYS) {
        val cutoff = DayKeys.minusDays(today, keepDays)
        val stale = prefs.all.keys.filter { key ->
            val day = when {
                key.startsWith(PREFIX_HISTORY) -> key.removePrefix(PREFIX_HISTORY).toIntOrNull()
                key.startsWith(PREFIX_EXTERNAL) -> key.removePrefix(PREFIX_EXTERNAL).toIntOrNull()
                else -> null
            }
            day != null && day < cutoff
        }
        if (stale.isNotEmpty()) prefs.edit { stale.forEach(::remove) }
    }

    private fun readDayMap(prefix: String): Map<Int, Int> {
        val out = HashMap<Int, Int>()
        for ((key, value) in prefs.all) {
            if (!key.startsWith(prefix)) continue
            val day = key.removePrefix(prefix).toIntOrNull() ?: continue
            val steps = when (value) {
                is Int -> value
                is Long -> value.toInt()
                else -> continue
            }
            if (day > 0 && steps > 0) out[day] = steps
        }
        return out
    }

    var enabled: Boolean
        get() = prefs.getBoolean(KEY_ENABLED, prefs.contains(KEY_DAY))
        set(value) = prefs.edit { putBoolean(KEY_ENABLED, value) }

    var goal: Int
        get() = prefs.getInt(KEY_GOAL, DEFAULT_GOAL).coerceAtLeast(1)
        set(value) = prefs.edit { putInt(KEY_GOAL, value.coerceAtLeast(1)) }

    var weightKg: Float
        get() = prefs.getFloat(KEY_WEIGHT, DEFAULT_WEIGHT).coerceIn(30f, 300f)
        set(value) = prefs.edit { putFloat(KEY_WEIGHT, value.coerceIn(30f, 300f)) }

    var kcalPerStep: Float
        get() = prefs.getFloat(KEY_KCAL_PER_STEP, 0f)
        set(value) = prefs.edit { putFloat(KEY_KCAL_PER_STEP, value) }

    var labels: NotificationLabels
        get() {
            val fallback = NotificationLabels()
            return NotificationLabels(
                channel = prefs.getString(KEY_LABEL_CHANNEL, null) ?: fallback.channel,
                title = prefs.getString(KEY_LABEL_TITLE, null) ?: fallback.title,
                goal = prefs.getString(KEY_LABEL_GOAL, null) ?: fallback.goal,
                kcal = prefs.getString(KEY_LABEL_KCAL, null) ?: fallback.kcal,
                goalReached = prefs.getString(KEY_LABEL_GOAL_REACHED, null) ?: fallback.goalReached,
                locale = prefs.getString(KEY_LABEL_LOCALE, null) ?: fallback.locale,
            )
        }
        set(value) = prefs.edit {
            putString(KEY_LABEL_CHANNEL, value.channel)
            putString(KEY_LABEL_TITLE, value.title)
            putString(KEY_LABEL_GOAL, value.goal)
            putString(KEY_LABEL_KCAL, value.kcal)
            putString(KEY_LABEL_GOAL_REACHED, value.goalReached)
            putString(KEY_LABEL_LOCALE, value.locale)
        }

    fun healthConnectToday(day: Int): ExternalReading? = readExternalToday(KEY_HC_TODAY, day)

    fun recordingToday(day: Int): ExternalReading? = readExternalToday(KEY_REC_TODAY, day)

    fun saveHealthConnectToday(day: Int, reading: ExternalReading) = saveExternalToday(KEY_HC_TODAY, day, reading)

    fun saveRecordingToday(day: Int, reading: ExternalReading) = saveExternalToday(KEY_REC_TODAY, day, reading)

    private fun readExternalToday(key: String, day: Int): ExternalReading? {
        if (prefs.getInt("${key}_day", 0) != day) return null
        val steps = prefs.getInt(key, -1)
        if (steps < 0) return null
        return ExternalReading(steps, prefs.getLong("${key}_at", 0L))
    }

    private fun saveExternalToday(key: String, day: Int, reading: ExternalReading) {
        prefs.edit {
            putInt("${key}_day", day)
            putInt(key, reading.steps)
            putLong("${key}_at", reading.at)
        }
    }

    var healthConnectOrigins: Set<String>
        get() = prefs.getStringSet(KEY_HC_ORIGINS, emptySet()) ?: emptySet()
        set(value) = prefs.edit { putStringSet(KEY_HC_ORIGINS, value) }

    var recordingSubscribedAt: Long
        get() = prefs.getLong(KEY_REC_SUBSCRIBED_AT, 0L)
        set(value) = prefs.edit { putLong(KEY_REC_SUBSCRIBED_AT, value) }

    var externalHistoryAt: Long
        get() = prefs.getLong(KEY_EXT_HISTORY_AT, 0L)
        set(value) = prefs.edit { putLong(KEY_EXT_HISTORY_AT, value) }

    companion object {
        const val FILE_NAME = "calora_steps_native"
        const val KEEP_DAYS = 35L
        const val DEFAULT_GOAL = 8000
        const val DEFAULT_WEIGHT = 70f

        private const val KEY_SCHEMA_V2 = "schema_v2"
        private const val KEY_DAY = "day_yyyymmdd"
        private const val KEY_STEPS = "shown_steps"
        private const val KEY_SENSOR_STEPS = "sensor_steps"
        private const val KEY_LAST_SENSOR = "last_sensor"
        private const val KEY_LAST_SENSOR_AT = "last_sensor_at"
        private const val KEY_SENSOR_BOOT = "sensor_boot"
        private const val KEY_PENDING_GAP = "pending_gap"
        private const val KEY_PENDING_GAP_UNTIL = "pending_gap_until"
        private const val KEY_SOURCE = "source"
        private const val KEY_ENABLED = "enabled"
        private const val KEY_GOAL = "goal"
        private const val KEY_WEIGHT = "weight_kg"
        private const val KEY_KCAL_PER_STEP = "kcal_per_step"
        private const val KEY_LABEL_CHANNEL = "label_channel"
        private const val KEY_LABEL_TITLE = "label_title"
        private const val KEY_LABEL_GOAL = "label_goal"
        private const val KEY_LABEL_KCAL = "label_kcal"
        private const val KEY_LABEL_GOAL_REACHED = "label_goal_reached"
        private const val KEY_LABEL_LOCALE = "label_locale"
        private const val KEY_HC_TODAY = "hc_today"
        private const val KEY_REC_TODAY = "rec_today"
        private const val KEY_HC_ORIGINS = "hc_origins"
        private const val KEY_REC_SUBSCRIBED_AT = "rec_subscribed_at"
        private const val KEY_EXT_HISTORY_AT = "external_history_at"
        private const val PREFIX_HISTORY = "hist_"
        private const val PREFIX_EXTERNAL = "ext_"
        private const val LEGACY_SYNC_BASE_SENSOR = "sync_base_sensor"
        private const val LEGACY_SYNC_BASE_STEPS = "sync_base_steps"
        private const val LEGACY_MODE = "mode"
    }
}
