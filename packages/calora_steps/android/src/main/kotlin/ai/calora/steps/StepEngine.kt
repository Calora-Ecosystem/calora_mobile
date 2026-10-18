package ai.calora.steps

import android.Manifest
import android.annotation.SuppressLint
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.health.connect.client.permission.HealthPermission
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import java.time.Instant
import java.time.ZoneId
import java.util.concurrent.CopyOnWriteArraySet
import kotlin.coroutines.resume
import kotlin.math.roundToInt

@SuppressLint("StaticFieldLeak")
object StepEngine {

    private const val TAG = "CaloraSteps.Engine"
    private const val PERSIST_INTERVAL_MS = 15_000L
    private const val TICK_MS = 60_000L
    private const val REFRESH_GAP_MS = 20_000L
    private const val REFRESH_INTERACTIVE_MS = 120_000L
    private const val REFRESH_IDLE_MS = 15 * 60_000L
    private const val HISTORY_TTL_MS = 30 * 60_000L
    private const val HISTORY_DAYS = 30
    private const val RECORDING_DAYS = 10
    private const val NOTIFY_MIN_GAP_MS = 1_000L
    private const val DEFAULT_KCAL_PER_STEP = 0.04f
    private const val ACTION_MIDNIGHT = "ai.calora.steps.MIDNIGHT"
    private const val REQUEST_MIDNIGHT = 2111

    private lateinit var app: Context
    private lateinit var store: StepStore
    private lateinit var sensor: StepSensor
    lateinit var healthConnect: HealthConnectSource
        private set
    private lateinit var recording: RecordingSource
    private lateinit var notifier: StepNotifier

    private val main = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val listeners = CopyOnWriteArraySet<(Map<String, Any?>) -> Unit>()

    private var initialized = false
    private var state = CounterState()
    private var healthConnectToday: ExternalReading? = null
    private var recordingToday: ExternalReading? = null
    private var serviceRunning = false
    private var dirty = false
    private var lastPersistAt = 0L
    private var lastRefreshAt = 0L
    private var refreshJob: Job? = null
    private var historyJob: Job? = null
    private var lastNotifyAt = 0L
    private var notifyScheduled = false
    private var tickScheduled = false
    private var receiversRegistered = false
    private var resubscribedRecording = false
    private var updatedAt = 0L

    private val tick = object : Runnable {
        override fun run() {
            tickScheduled = false
            onTick()
            scheduleTick()
        }
    }

    private val systemEvents = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_ON, Intent.ACTION_USER_PRESENT -> refresh()
                Intent.ACTION_DATE_CHANGED -> onClockChanged()
            }
        }
    }

    fun init(context: Context) {
        if (initialized) return
        app = context.applicationContext
        store = StepStore(app)
        notifier = StepNotifier(app)
        healthConnect = HealthConnectSource(app)
        recording = RecordingSource(app, store)
        sensor = StepSensor(app, ::onReading)
        val clock = clock()
        state = store.loadState(clock)
        healthConnectToday = store.healthConnectToday(state.day)
        recordingToday = store.recordingToday(state.day)
        initialized = true
        rolloverIfNeeded(clock)
        if (store.enabled) resume()
    }

    val isEnabled: Boolean get() = initialized && store.enabled

    fun hasActivityPermission(): Boolean =
        ContextCompat.checkSelfPermission(app, Manifest.permission.ACTIVITY_RECOGNITION) ==
            PackageManager.PERMISSION_GRANTED

    fun startTracking(): Boolean {
        store.enabled = true
        resume()
        return ensureService()
    }

    fun stopTracking() {
        store.enabled = false
        persist(sync = true)
        sensor.stop()
        unregisterReceivers()
        cancelMidnight()
        main.removeCallbacks(tick)
        tickScheduled = false
        app.stopService(Intent(app, StepTrackingService::class.java))
        notifier.cancel()
        publish(force = true)
    }

    fun configure(goal: Int?, weightKg: Double?, kcalPerStep: Double?, labels: NotificationLabels?) {
        goal?.takeIf { it > 0 }?.let { store.goal = it }
        weightKg?.takeIf { it > 0 }?.let { store.weightKg = it.toFloat() }
        kcalPerStep?.takeIf { it > 0 && it < 1 }?.let { store.kcalPerStep = it.toFloat() }
        labels?.let { store.labels = it }
        publish(force = true)
    }

    fun ensureService(): Boolean {
        if (!store.enabled) return false
        if (!hasActivityPermission()) {
            publish(force = true)
            return false
        }
        if (serviceRunning) return true
        return try {
            ContextCompat.startForegroundService(app, Intent(app, StepTrackingService::class.java))
            true
        } catch (t: Throwable) {
            Log.w(TAG, "Foreground service start refused: ${t.message}")
            publish(force = true)
            false
        }
    }

    private fun resume() {
        if (hasActivityPermission()) sensor.start()
        registerReceivers()
        scheduleMidnight()
        scheduleTick()
        scope.launch { recording.ensureSubscribed() }
        refresh()
    }

    fun notification() = notifier.build(notificationContent())

    fun onServiceStarted() {
        serviceRunning = true
        resume()
        publish(force = true)
    }

    fun onServiceStopped() {
        serviceRunning = false
        persist(sync = true)
        if (!store.enabled) sensor.stop()
        publish(force = true)
    }

    fun persistNow() = persist(sync = true)

    fun addListener(listener: (Map<String, Any?>) -> Unit) {
        listeners += listener
        listener(snapshot())
    }

    fun removeListener(listener: (Map<String, Any?>) -> Unit) {
        listeners -= listener
    }

    private fun clock(): Clock {
        val now = System.currentTimeMillis()
        val boot = try {
            Settings.Global.getInt(app.contentResolver, Settings.Global.BOOT_COUNT)
        } catch (t: Throwable) {
            0
        }
        return Clock(now = now, zone = ZoneId.systemDefault(), boot = boot, bootAt = now - SystemClock.elapsedRealtime())
    }

    private fun onReading(value: Float, eventAt: Long) {
        val clock = clock()
        val transition = StepCounterMath.onReading(state, value, eventAt, clock) { day -> store.historyFor(day) }
        apply(transition, clock)
    }

    private fun apply(transition: Transition, clock: Clock) {
        transition.finalized?.let { finalized ->
            store.raiseHistory(finalized.day, finalized.steps)
            store.prune(clock.today)
            healthConnectToday = null
            recordingToday = null
        }
        transition.lateCredit?.let { store.addHistory(it.day, it.steps) }
        if (!transition.changed) return
        val visibleChange = transition.state.steps != state.steps || transition.state.day != state.day
        state = transition.state
        dirty = true
        if (transition.finalized != null || clock.now - lastPersistAt >= PERSIST_INTERVAL_MS) persist()
        if (visibleChange) {
            updatedAt = clock.now
            publish()
        }
    }

    private fun rolloverIfNeeded(clock: Clock = clock()) {
        if (state.day == clock.today) return
        apply(StepCounterMath.rollover(state, clock.today, store.historyFor(clock.today)), clock)
        persist()
        publish(force = true)
    }

    private fun onTick() {
        if (!store.enabled) return
        val clock = clock()
        rolloverIfNeeded(clock)
        apply(StepCounterMath.settleGap(state, clock), clock)
        if (dirty && clock.now - lastPersistAt >= PERSIST_INTERVAL_MS) persist()
        val interval = if (isInteractive()) REFRESH_INTERACTIVE_MS else REFRESH_IDLE_MS
        if (clock.now - lastRefreshAt >= interval) refresh()
    }

    private fun onClockChanged() {
        val clock = clock()
        rolloverIfNeeded(clock)
        scheduleMidnight()
        refresh(force = true)
    }

    fun onMidnightAlarm(onDone: () -> Unit) {
        scheduleMidnight()
        if (!store.enabled) {
            onDone()
            return
        }
        ensureService()
        sensor.flush {
            rolloverIfNeeded()
            publish(force = true)
            onDone()
        }
    }

    fun onSystemBroadcast(action: String?) {
        if (!store.enabled) return
        when (action) {
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED -> onClockChanged()
        }
        ensureService()
    }

    fun refresh(force: Boolean = false, onDone: (() -> Unit)? = null) {
        if (!initialized) {
            onDone?.invoke()
            return
        }
        val now = System.currentTimeMillis()
        val running = refreshJob?.isActive == true
        if (running || (!force && now - lastRefreshAt < REFRESH_GAP_MS)) {
            if (onDone == null) return
            val job = refreshJob
            if (job != null && job.isActive) {
                job.invokeOnCompletion { main.post(onDone) }
            } else {
                onDone()
            }
            return
        }
        lastRefreshAt = now
        refreshJob = scope.launch {
            try {
                readExternalToday()
            } catch (t: Throwable) {
                Log.w(TAG, "External refresh failed: ${t.message}")
            } finally {
                publish(force = true)
                onDone?.invoke()
            }
        }
        if (now - store.externalHistoryAt >= HISTORY_TTL_MS) refreshHistory(force = false)
    }

    private suspend fun readExternalToday() {
        awaitFlush()
        val before = clock()
        rolloverIfNeeded(before)
        val instant = Instant.ofEpochMilli(before.now)
        val (hcResult, recResult) = coroutineScope {
            val hc = async { healthConnect.today(before.zone, instant) }
            val rec = async { recording.today(before.zone, instant) }
            hc.await() to rec.await()
        }
        val after = clock()
        if (after.today != before.today) return
        rolloverIfNeeded(after)

        if (recResult != null) {
            recordingToday = ExternalReading(recResult, after.now)
            store.saveRecordingToday(after.today, recordingToday!!)
            apply(
                StepCounterMath.mergeExternal(
                    state,
                    after,
                    recResult,
                    CounterState.SOURCE_RECORDING,
                    coversWholeDay = recording.coversDay(after.startOfToday),
                ),
                after,
            )
            maybeResubscribeRecording(recResult)
        }
        if (hcResult != null) {
            healthConnectToday = ExternalReading(hcResult.steps, after.now)
            store.saveHealthConnectToday(after.today, healthConnectToday!!)
            if (hcResult.origins.isNotEmpty()) store.healthConnectOrigins = store.healthConnectOrigins + hcResult.origins
            apply(
                StepCounterMath.mergeExternal(
                    state,
                    after,
                    hcResult.steps,
                    CounterState.SOURCE_HEALTH_CONNECT,
                    coversWholeDay = hcResult.steps > 0,
                ),
                after,
            )
        }
        apply(StepCounterMath.settleGap(state, after), after)
        if (dirty) persist()
    }

    private suspend fun maybeResubscribeRecording(recordingSteps: Int) {
        if (resubscribedRecording || recordingSteps > 0 || state.sensorSteps < 1500) return
        if (System.currentTimeMillis() - store.recordingSubscribedAt < StepCounterMath.DAY_MS) return
        resubscribedRecording = true
        recording.resubscribe()
    }

    fun refreshHistory(force: Boolean, onDone: (() -> Unit)? = null) {
        if (!initialized) {
            onDone?.invoke()
            return
        }
        val running = historyJob
        if (running != null && running.isActive) {
            if (onDone != null) running.invokeOnCompletion { main.post(onDone) }
            return
        }
        if (!force && System.currentTimeMillis() - store.externalHistoryAt < HISTORY_TTL_MS) {
            onDone?.invoke()
            return
        }
        historyJob = scope.launch {
            try {
                val clock = clock()
                val (hcDays, recDays) = coroutineScope {
                    val hc = async { healthConnect.daily(clock.zone, clock.today, HISTORY_DAYS) }
                    val rec = async { recording.daily(clock.zone, clock.today, RECORDING_DAYS) }
                    hc.await() to rec.await()
                }
                val merged = HashMap<Int, Int>()
                listOfNotNull(hcDays, recDays).forEach { days ->
                    days.forEach { (day, steps) -> merged[day] = maxOf(merged[day] ?: 0, steps) }
                }
                merged.remove(clock.today)
                store.raiseExternal(merged)
                if (hcDays != null || recDays != null) store.externalHistoryAt = System.currentTimeMillis()
                healthConnect.recentOrigins(clock.zone, Instant.ofEpochMilli(clock.now), 7)?.let {
                    store.healthConnectOrigins = it
                }
            } catch (t: Throwable) {
                Log.w(TAG, "History refresh failed: ${t.message}")
            } finally {
                onDone?.invoke()
            }
        }
    }

    fun history(days: Int): Map<String, Int> {
        val clock = clock()
        rolloverIfNeeded(clock)
        val first = DayKeys.minusDays(clock.today, (days - 1).toLong().coerceAtLeast(0))
        val sensorDays = store.history()
        val externalDays = store.external()
        val out = HashMap<String, Int>()
        (sensorDays.keys + externalDays.keys).forEach { day ->
            if (day < first || day >= clock.today) return@forEach
            val steps = maxOf(sensorDays[day] ?: 0, externalDays[day] ?: 0)
            if (steps > 0) out[DayKeys.iso(day)] = steps
        }
        if (state.day == clock.today && state.steps > 0) out[DayKeys.iso(clock.today)] = state.steps
        return out
    }

    fun snapshot(): Map<String, Any?> {
        val today = if (initialized) clock().today else 0
        val current = state.day == today
        return mapOf(
            "day" to if (today == 0) null else DayKeys.iso(today),
            "steps" to if (current) state.steps else 0,
            "sensorSteps" to if (current) state.sensorSteps else 0,
            "pendingSteps" to if (current) state.pendingGap else 0,
            "healthConnectSteps" to healthConnectToday?.steps,
            "recordingSteps" to recordingToday?.steps,
            "source" to state.source,
            "enabled" to (initialized && store.enabled),
            "serviceRunning" to serviceRunning,
            "sensorListening" to (initialized && sensor.isListening),
            "issue" to issue(),
            "updatedAt" to updatedAt,
        )
    }

    private fun issue(): String? {
        if (!initialized || !store.enabled) return "disabled"
        val external = healthConnectToday != null || recordingToday != null
        if (!hasActivityPermission() && healthConnectToday == null) return "activity_permission"
        if (!sensor.isAvailable && !external) return "no_source"
        if (!serviceRunning) return "service_stopped"
        return null
    }

    suspend fun status(): Map<String, Any?> {
        val availability = healthConnect.availability()
        val granted = if (availability == HealthConnectAvailability.AVAILABLE) healthConnect.grantedPermissions() else emptySet()
        val connected = HealthConnectSource.READ_STEPS in granted
        val backgroundAvailable = connected && healthConnect.backgroundReadAvailable()
        val origins = if (connected) {
            healthConnect.recentOrigins(ZoneId.systemDefault(), Instant.now(), 7)?.also { store.healthConnectOrigins = it }
                ?: store.healthConnectOrigins
        } else {
            emptySet()
        }
        val trackers = TrackerApps.installed(app).map { tracker ->
            mapOf(
                "id" to tracker.app.id,
                "name" to tracker.app.name,
                "package" to tracker.packageName,
                "syncing" to tracker.app.packages.any { it in origins },
            )
        }
        return mapOf(
            "activityRecognition" to hasActivityPermission(),
            "notifications" to notifier.canPost(),
            "batteryUnrestricted" to DeviceCare.isIgnoringBatteryOptimizations(app),
            "autoStartScreen" to DeviceCare.hasAutoStartScreen(app),
            "sensorAvailable" to sensor.isAvailable,
            "recordingAvailable" to recording.isAvailable(),
            "healthConnect" to availability.wire,
            "healthConnectConnected" to connected,
            "healthConnectBackgroundAvailable" to backgroundAvailable,
            "healthConnectBackgroundGranted" to
                (HealthPermission.PERMISSION_READ_HEALTH_DATA_IN_BACKGROUND in granted),
            "phoneStepsInHealthConnect" to origins.any { it == "android" || it.startsWith("com.android.healthconnect") },
            "trackers" to trackers,
            "enabled" to store.enabled,
            "serviceRunning" to serviceRunning,
            "manufacturer" to Build.MANUFACTURER,
            "sdkInt" to Build.VERSION.SDK_INT,
        )
    }

    private fun persist(sync: Boolean = false) {
        if (!initialized) return
        store.saveState(state, sync)
        dirty = false
        lastPersistAt = System.currentTimeMillis()
    }

    private fun notificationContent(): NotificationContent {
        val today = clock().today
        val steps = if (state.day == today) state.steps else 0
        val perStep = store.kcalPerStep.takeIf { it > 0f } ?: (DEFAULT_KCAL_PER_STEP * store.weightKg / StepStore.DEFAULT_WEIGHT)
        return NotificationContent(
            steps = steps,
            goal = store.goal,
            kcal = (steps * perStep).roundToInt(),
            labels = store.labels,
        )
    }

    private fun publish(force: Boolean = false) {
        if (!initialized) return
        val snapshot = snapshot()
        listeners.forEach { listener ->
            try {
                listener(snapshot)
            } catch (t: Throwable) {
                Log.w(TAG, "Listener failed: ${t.message}")
            }
        }
        scheduleNotification(force)
    }

    private fun scheduleNotification(force: Boolean) {
        if (!store.enabled) return
        val now = SystemClock.elapsedRealtime()
        val wait = NOTIFY_MIN_GAP_MS - (now - lastNotifyAt)
        if (wait <= 0 || force) {
            postNotification()
            return
        }
        if (notifyScheduled) return
        notifyScheduled = true
        main.postDelayed({
            notifyScheduled = false
            postNotification()
        }, wait)
    }

    private fun postNotification() {
        if (!store.enabled) return
        lastNotifyAt = SystemClock.elapsedRealtime()
        if (!serviceRunning && healthConnectToday == null && recordingToday == null) {
            notifier.cancel()
            return
        }
        notifier.post(notificationContent())
    }

    private fun scheduleTick() {
        if (tickScheduled || !store.enabled) return
        tickScheduled = true
        main.postDelayed(tick, TICK_MS)
    }

    private fun isInteractive(): Boolean = try {
        (app.getSystemService(Context.POWER_SERVICE) as PowerManager).isInteractive
    } catch (t: Throwable) {
        true
    }

    private suspend fun awaitFlush() = suspendCancellableCoroutine { continuation ->
        sensor.flush { if (continuation.isActive) continuation.resume(Unit) }
    }

    private fun registerReceivers() {
        if (receiversRegistered) return
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
            addAction(Intent.ACTION_DATE_CHANGED)
        }
        try {
            ContextCompat.registerReceiver(app, systemEvents, filter, ContextCompat.RECEIVER_NOT_EXPORTED)
            receiversRegistered = true
        } catch (t: Throwable) {
            Log.w(TAG, "Receiver registration failed: ${t.message}")
        }
    }

    private fun unregisterReceivers() {
        if (!receiversRegistered) return
        try {
            app.unregisterReceiver(systemEvents)
        } catch (t: Throwable) {
            Log.w(TAG, "Receiver unregister failed: ${t.message}")
        }
        receiversRegistered = false
    }

    private fun midnightIntent(): PendingIntent = PendingIntent.getBroadcast(
        app,
        REQUEST_MIDNIGHT,
        Intent(app, StepAlarmReceiver::class.java).setAction(ACTION_MIDNIGHT),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    fun isMidnightAction(action: String?) = action == ACTION_MIDNIGHT

    private fun scheduleMidnight() {
        if (!store.enabled) return
        try {
            val alarms = app.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val clock = clock()
            val next = clock.startOfDay(DayKeys.minusDays(clock.today, -1)) + 2_000L
            val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()
            if (exact) {
                alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, midnightIntent())
            } else {
                alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, midnightIntent())
            }
        } catch (t: Throwable) {
            Log.w(TAG, "Midnight alarm failed: ${t.message}")
        }
    }

    private fun cancelMidnight() {
        try {
            (app.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(midnightIntent())
        } catch (t: Throwable) {
            Log.w(TAG, "Midnight alarm cancel failed: ${t.message}")
        }
    }
}
