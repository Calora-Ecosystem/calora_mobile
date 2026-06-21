package ai.calora.app

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import kotlin.math.roundToInt

class StepsFgService : Service(), SensorEventListener {

    companion object {
        const val CHANNEL_ID = "calora_steps_native_notif"
        const val CHANNEL_NAME = "Calora Steps"
        const val NOTIF_ID = 2110

        const val ACTION_START = "ai.calora.app.steps.START"
        const val ACTION_UPDATE_GOAL = "ai.calora.app.steps.UPDATE_GOAL"
        const val ACTION_SYNC = "ai.calora.app.steps.SYNC"
        const val ACTION_STOP = "ai.calora.app.steps.STOP"
        const val ACTION_MIDNIGHT_RESET = "ai.calora.app.steps.MIDNIGHT_RESET"

        const val MIDNIGHT_REQUEST_CODE = 2111
        const val KEEPALIVE_REQUEST_CODE = 2112

        /// How often the self-heal keep-alive alarm re-asserts the service.
        /// Inexact + AllowWhileIdle, so Doze may stretch it, but it keeps
        /// the foreground service alive across low-memory kills that
        /// START_STICKY alone doesn't recover.
        const val KEEPALIVE_INTERVAL_MS = 30L * 60L * 1000L

        const val EXTRA_GOAL = "goal"
        const val EXTRA_STEPS = "steps"
        const val EXTRA_WEIGHT_KG = "weight_kg"
        const val EXTRA_MODE = "mode"

        /// Native sensor is the authority: the service counts steps from
        /// TYPE_STEP_COUNTER and drives the displayed value itself. Used
        /// for the pedometer fallback so counting survives the app being
        /// closed.
        const val MODE_SENSOR = "sensor"

        /// Flutter is the authority (Health Connect): the displayed value
        /// is whatever the last SYNC pushed; the sensor is NOT used to
        /// extrapolate the notification, so it can never drift away from
        /// the in-app number.
        const val MODE_MIRROR = "mirror"
    }

    private var goal: Int = 8000

    private var mode: String = MODE_SENSOR

    private var weightKg: Float = 70f

    private lateinit var sensorManager: SensorManager
    private var stepCounterSensor: Sensor? = null

    /// True when [stepCounterSensor] is the wake-up variant, which can
    /// deliver events while the CPU is asleep. When false we hold a
    /// partial wakelock instead so background counting still works.
    private var usingWakeUpSensor: Boolean = false
    private var wakeLock: PowerManager.WakeLock? = null

    /// Batch sensor delivery by up to this latency. With a wake-up
    /// sensor this lets the hardware FIFO wake the CPU periodically in
    /// Doze; in the foreground events still arrive well within a few
    /// seconds, which is plenty for a step counter.
    private val sensorMaxLatencyUs = 3_000_000

    private var lastSensorValue: Float? = null

    private var syncBaseSensorValue: Float? = null
    private var syncBaseSteps: Int = 0
    private var pendingSyncSteps: Int? = null

    private var shownSteps: Int = 0
    private var previousShownSteps: Int = -1

    private var lastNotifUpdateElapsed: Long = 0L
    private val notifUpdateMinIntervalMs = 1000L

    private val prefs: SharedPreferences by lazy {
        getSharedPreferences("calora_steps_native", MODE_PRIVATE)
    }

    private val KEY_DAY = "day_yyyymmdd"
    private val KEY_SYNC_BASE_SENSOR = "sync_base_sensor"
    private val KEY_SYNC_BASE_STEPS = "sync_base_steps"
    private val KEY_WEIGHT = "weight_kg"
    private val KEY_SHOWN_STEPS = "shown_steps"
    private val KEY_LAST_SENSOR = "last_sensor"
    private val KEY_GOAL = "goal"
    private val KEY_MODE = "mode"

    override fun onCreate() {
        super.onCreate()
        Log.d("StepsFgService", "onCreate")
        ensureChannel()

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepCounterSensor = resolveStepSensor()

        restoreSyncIfSameDay()
        restoreShownStateIfSameDay()

        weightKg = prefs.getFloat(KEY_WEIGHT, 70f).coerceAtLeast(30f)
        goal = prefs.getInt(KEY_GOAL, 8000).coerceAtLeast(1)
        mode = prefs.getString(KEY_MODE, MODE_SENSOR) ?: MODE_SENSOR
    }

    private fun persistMode(value: String) {
        mode = value
        prefs.edit().putString(KEY_MODE, value).apply()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("StepsFgService", "onStartCommand, action: ${intent?.action}")
        when (intent?.action) {
            ACTION_START -> handleStart(intent)
            ACTION_UPDATE_GOAL -> handleUpdateGoal(intent)
            ACTION_SYNC -> handleSync(intent)
            ACTION_STOP -> handleStop()
            ACTION_MIDNIGHT_RESET -> handleMidnightReset()
            else -> handleAutoRestart()
        }
        return START_STICKY
    }

    private fun handleAutoRestart() {
        Log.i("StepsFgService", "Auto-restart: re-attaching foreground (shown=$shownSteps)")
        try {
            startForeground(NOTIF_ID, buildNotification(shownSteps))
        } catch (e: Exception) {
            Log.e("StepsFgService", "Auto-restart startForeground failed", e)
            return
        }
        scheduleMidnightReset()
        scheduleKeepAlive()
        if (!hasActivityPermission()) return
        if (stepCounterSensor == null) {
            stepCounterSensor = resolveStepSensor()
        }
        registerStepSensor()
    }

    private fun handleStart(intent: Intent) {
        intent.getStringExtra(EXTRA_MODE)?.let { persistMode(it) }

        goal = intent.getIntExtra(EXTRA_GOAL, goal).coerceAtLeast(1)
        prefs.edit().putInt(KEY_GOAL, goal).apply()

        val w = intent.getFloatExtra(EXTRA_WEIGHT_KG, weightKg).coerceAtLeast(30f)
        weightKg = w
        prefs.edit().putFloat(KEY_WEIGHT, weightKg).apply()

        val computed = computeDisplayedSteps()
        if (computed != null) {
            shownSteps = computed
            previousShownSteps = shownSteps
            persistShown(shownSteps)
        }

        try {
            Log.d("StepsFgService", "Attempting to call startForeground...")
            startForeground(NOTIF_ID, buildNotification(shownSteps))
            Log.i("StepsFgService", "startForeground OK. goal=$goal shown=$shownSteps weightKg=$weightKg")
        } catch (e: Exception) {
            Log.e("StepsFgService", "!!! FAILED to call startForeground !!!", e)
        }

        scheduleMidnightReset()
        scheduleKeepAlive()

        if (!hasActivityPermission()) {
            Log.w("StepsService", "ACTIVITY_RECOGNITION permission yo'q")
            return
        }

        stepCounterSensor = resolveStepSensor()
        if (stepCounterSensor == null) {
            Log.e("StepsService", "TYPE_STEP_COUNTER sensor mavjud emas!")
            return
        }

        registerStepSensor()
    }

    private fun handleUpdateGoal(intent: Intent) {
        goal = intent.getIntExtra(EXTRA_GOAL, goal).coerceAtLeast(1)
        prefs.edit().putInt(KEY_GOAL, goal).apply()
        Log.i("StepsService", "Goal updated: $goal")
        updateNotification(force = true)
    }

    private fun handleSync(intent: Intent) {
        intent.getStringExtra(EXTRA_MODE)?.let { persistMode(it) }

        val steps = intent.getIntExtra(EXTRA_STEPS, 0).coerceAtLeast(0)

        val w = intent.getFloatExtra(EXTRA_WEIGHT_KG, weightKg).coerceAtLeast(30f)
        if (w != weightKg) {
            weightKg = w
            prefs.edit().putFloat(KEY_WEIGHT, weightKg).apply()
        }

        if (isNewDay()) {
            clearSync()
        }

        val sensorNow = lastSensorValue
        if (sensorNow == null) {
            pendingSyncSteps = steps
            syncBaseSteps = steps
            shownSteps = steps
            previousShownSteps = steps
            saveDay()
            persistShown(steps)
            updateNotification(force = true)
            Log.i("StepsService", "SYNC pending (no sensor yet). steps=$steps weightKg=$weightKg")
            return
        }

        syncBaseSensorValue = sensorNow
        syncBaseSteps = steps
        pendingSyncSteps = null

        persistSync(sensorNow, steps)
        shownSteps = steps
        previousShownSteps = steps
        persistShown(steps)
        persistLastSensor(sensorNow)
        updateNotification(force = true)

        Log.i("StepsService", "SYNC applied. steps=$steps sensorBase=$sensorNow weightKg=$weightKg")
    }

    private fun handleStop() {
        Log.i("StepsService", "Stopping service")
        cancelMidnightReset()
        cancelKeepAlive()
        releaseWakeLock()
        unregisterStepSensor()
        stopForeground(true)
        stopSelf()
    }

    // ===== Midnight notification reset =====

    /// Snaps the notification to 0 for the new day. Triggered by the
    /// AlarmManager at (around) local midnight so the user never sees
    /// yesterday's count before taking their first step of the day.
    private fun handleMidnightReset() {
        // The alarm may have cold-started us — re-assert foreground.
        try {
            startForeground(NOTIF_ID, buildNotification(shownSteps))
        } catch (e: Exception) {
            Log.e("StepsService", "midnight startForeground failed", e)
        }

        val sensorNow = lastSensorValue
        if (sensorNow != null) {
            // We know the cumulative sensor value — rebase cleanly so the
            // next sensor event simply continues counting today from 0.
            syncBaseSensorValue = sensorNow
            syncBaseSteps = 0
            pendingSyncSteps = null
            shownSteps = 0
            previousShownSteps = 0
            persistSync(sensorNow, 0)   // writes KEY_DAY = today
            persistShown(0)
        } else {
            // No sensor reading yet — just blank the notification to 0 and
            // leave the day marker so the next sensor event's handleNewDay
            // re-establishes the baseline.
            shownSteps = 0
            previousShownSteps = 0
        }
        updateNotification(force = true)

        // Make sure the sensor is listening (we may have been cold-started).
        if (hasActivityPermission()) {
            if (stepCounterSensor == null) stepCounterSensor = resolveStepSensor()
            registerStepSensor()
        }

        scheduleMidnightReset() // arm for the next midnight
        Log.i("StepsService", "Midnight reset fired (sensorNow=$sensorNow)")
    }

    private fun midnightPendingIntent(): PendingIntent {
        val intent = Intent(this, MidnightResetReceiver::class.java)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        return PendingIntent.getBroadcast(this, MIDNIGHT_REQUEST_CODE, intent, flags)
    }

    private fun scheduleMidnightReset() {
        try {
            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            // Next local 00:00:05 (a few seconds past midnight so the
            // device's calendar day has definitely flipped).
            val next = java.util.Calendar.getInstance().apply {
                add(java.util.Calendar.DAY_OF_YEAR, 1)
                set(java.util.Calendar.HOUR_OF_DAY, 0)
                set(java.util.Calendar.MINUTE, 0)
                set(java.util.Calendar.SECOND, 5)
                set(java.util.Calendar.MILLISECOND, 0)
            }.timeInMillis

            val pi = midnightPendingIntent()
            val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                am.canScheduleExactAlarms()
            if (canExact) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pi)
                Log.i("StepsService", "Midnight reset scheduled (exact) for $next")
            } else {
                // No exact-alarm permission — inexact while-idle alarm,
                // which may fire a few minutes late but still resets.
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pi)
                Log.i("StepsService", "Midnight reset scheduled (inexact) for $next")
            }
        } catch (t: Throwable) {
            Log.w("StepsService", "scheduleMidnightReset failed: ${t.message}")
        }
    }

    private fun cancelMidnightReset() {
        try {
            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(midnightPendingIntent())
        } catch (t: Throwable) {
            Log.w("StepsService", "cancelMidnightReset failed: ${t.message}")
        }
    }

    // ===== Keep-alive self-heal =====

    private fun keepAlivePendingIntent(): PendingIntent {
        val intent = Intent(this, StepsRestartReceiver::class.java).apply {
            action = StepsRestartReceiver.ACTION_KEEPALIVE
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        return PendingIntent.getBroadcast(this, KEEPALIVE_REQUEST_CODE, intent, flags)
    }

    /// Arms a single inexact while-idle alarm ~30 min out. It re-arms
    /// itself each time it fires (via StepsRestartReceiver → ACTION_START →
    /// handleStart/handleAutoRestart → here), giving us a periodic
    /// self-heal without an exact-alarm permission. Inexact + while-idle is
    /// battery-friendly and survives Doze.
    private fun scheduleKeepAlive() {
        try {
            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val triggerAt = System.currentTimeMillis() + KEEPALIVE_INTERVAL_MS
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, keepAlivePendingIntent())
        } catch (t: Throwable) {
            Log.w("StepsService", "scheduleKeepAlive failed: ${t.message}")
        }
    }

    private fun cancelKeepAlive() {
        try {
            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(keepAlivePendingIntent())
        } catch (t: Throwable) {
            Log.w("StepsService", "cancelKeepAlive failed: ${t.message}")
        }
    }

    override fun onDestroy() {
        releaseWakeLock()
        unregisterStepSensor()
        Log.i("StepsService", "Destroyed")
        super.onDestroy()
    }

    /// The user swiped the app out of recents. START_STICKY alone is
    /// unreliable on aggressive OEMs (Samsung/Xiaomi), so explicitly
    /// re-launch the foreground service to keep counting in the
    /// background. Guarded — a background-start refusal is non-fatal.
    override fun onTaskRemoved(rootIntent: Intent?) {
        try {
            val restart = Intent(applicationContext, StepsFgService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_GOAL, goal)
                putExtra(EXTRA_WEIGHT_KG, weightKg)
                putExtra(EXTRA_MODE, mode)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(applicationContext, restart)
            } else {
                startService(restart)
            }
        } catch (t: Throwable) {
            Log.w("StepsService", "onTaskRemoved restart failed: ${t.message}")
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /// Prefer the wake-up step counter (delivers events while the CPU is
    /// asleep). Falls back to the normal sensor, in which case
    /// [registerStepSensor] holds a wakelock so background delivery keeps
    /// working.
    private fun resolveStepSensor(): Sensor? {
        val wake = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER, true)
        if (wake != null) {
            usingWakeUpSensor = true
            return wake
        }
        usingWakeUpSensor = false
        return sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
    }

    private fun registerStepSensor() {
        val s = stepCounterSensor ?: run {
            Log.e("StepsService", "registerStepSensor: sensor null")
            return
        }

        // Batched registration so the hardware FIFO keeps accumulating
        // (and, for a wake-up sensor, wakes the CPU to deliver) while the
        // app is in the background / the screen is off.
        var registered = sensorManager.registerListener(
            this, s, SensorManager.SENSOR_DELAY_NORMAL, sensorMaxLatencyUs
        )
        if (!registered) {
            // Some devices reject batching — retry without it.
            registered = sensorManager.registerListener(
                this, s, SensorManager.SENSOR_DELAY_NORMAL
            )
        }
        if (!registered) {
            Log.e("StepsService", "Sensor register failed!")
            return
        }
        Log.i("StepsService", "Sensor registered (wakeUp=$usingWakeUpSensor)")

        // Without a wake-up sensor the CPU must stay awake to receive
        // step events in the background — hold a partial wakelock.
        if (!usingWakeUpSensor) acquireWakeLock()
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "calora:steps").apply {
                setReferenceCounted(false)
                acquire()
            }
            Log.i("StepsService", "WakeLock acquired (non-wake-up sensor)")
        } catch (t: Throwable) {
            Log.w("StepsService", "WakeLock acquire failed: ${t.message}")
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) wakeLock?.release()
        } catch (t: Throwable) {
            Log.w("StepsService", "WakeLock release failed: ${t.message}")
        }
        wakeLock = null
    }

    private fun unregisterStepSensor() {
        try {
            sensorManager.unregisterListener(this)
        } catch (t: Throwable) {
            Log.w("StepsService", "unregister error: ${t.message}")
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_STEP_COUNTER) return

        val currentSensor = event.values[0]

        val base = syncBaseSensorValue
        if (base != null && currentSensor + 1f < base) {
            syncBaseSensorValue = currentSensor
            syncBaseSteps = shownSteps
            persistSync(currentSensor, shownSteps)
            Log.i("StepsService", "Sensor rollback (reboot) detected. rebased base=$currentSensor steps=$shownSteps")
        }

        // Capture the prior reading BEFORE overwriting it — used as the
        // day-boundary baseline so steps right after midnight aren't lost.
        val prevSensor = lastSensorValue
            ?: prefs.getFloat(KEY_LAST_SENSOR, -1f).takeIf { it >= 0f }

        lastSensorValue = currentSensor
        persistLastSensor(currentSensor)

        if (isNewDay()) {
            handleNewDay(currentSensor, prevSensor)
            return
        }

        val p = pendingSyncSteps
        if (p != null) {
            syncBaseSensorValue = currentSensor
            syncBaseSteps = p
            pendingSyncSteps = null
            persistSync(currentSensor, p)
            shownSteps = p
            previousShownSteps = p
            persistShown(p)
            updateNotification(force = true)
            Log.i("StepsService", "Pending SYNC applied on first sensor event. steps=$p base=$currentSensor")
            return
        }

        // In MIRROR mode (Health Connect is the authority) the displayed
        // value is whatever the last SYNC pushed. We keep the sensor
        // baseline warm above so a later switch to SENSOR mode is
        // seamless, but we must NOT move the notification from the raw
        // sensor here — that is exactly what makes the notification drift
        // away from the in-app number.
        if (mode == MODE_MIRROR) return

        val displayed = computeDisplayedSteps()
        if (displayed != null && displayed != previousShownSteps) {
            previousShownSteps = displayed
            shownSteps = displayed
            persistShown(displayed)
            updateNotification(force = false)
        }
    }

    /// Midnight rollover. Rebase so today's count starts fresh. The old
    /// path nulled the baseline (clearSync) and never re-established it in
    /// SENSOR mode, which is exactly why counting died after midnight.
    private fun handleNewDay(currentSensor: Float, prevSensor: Float?) {
        val baseline = prevSensor ?: currentSensor
        syncBaseSensorValue = baseline
        syncBaseSteps = 0
        pendingSyncSteps = null

        if (mode == MODE_MIRROR) {
            // Health Connect owns the value — reset to 0 and let Flutter
            // sync the new day's total. Baseline stays warm for a later
            // switch to SENSOR mode.
            shownSteps = 0
            previousShownSteps = 0
            persistSync(baseline, 0)   // also writes KEY_DAY = today
            persistShown(0)
            updateNotification(force = true)
            Log.i("StepsService", "New-day rollover (mirror): reset to 0")
            return
        }

        val displayed = (currentSensor - baseline).roundToInt().coerceAtLeast(0)
        shownSteps = displayed
        previousShownSteps = displayed
        persistSync(baseline, 0)       // also writes KEY_DAY = today
        persistShown(displayed)
        updateNotification(force = true)
        Log.i("StepsService", "New-day rollover (sensor): baseline=$baseline displayed=$displayed")
    }

    private fun computeDisplayedSteps(): Int? {
        val baseSensor = syncBaseSensorValue ?: return null
        val sensorNow = lastSensorValue ?: return null
        val delta = (sensorNow - baseSensor).roundToInt().coerceAtLeast(0)
        return (syncBaseSteps + delta).coerceAtLeast(0)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    private fun updateNotification(force: Boolean) {
        val now = SystemClock.elapsedRealtime()
        if (!force && (now - lastNotifUpdateElapsed) < notifUpdateMinIntervalMs) return
        lastNotifUpdateElapsed = now

        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIF_ID, buildNotification(shownSteps))
    }

    private fun buildNotification(steps: Int): Notification {
        val rv = RemoteViews(packageName, R.layout.notif_steps)

        val safeGoal = if (goal <= 0) 1 else goal

        val kcalPerStep = 0.04f * (weightKg / 70f)
        val kcal = (steps * kcalPerStep).roundToInt()

        val pct = ((steps.toFloat() / safeGoal) * 100f).coerceIn(0f, 100f).roundToInt()

        rv.setTextViewText(R.id.tv_steps, steps.toString())
        rv.setTextViewText(R.id.tv_kcal, kcal.toString())
        rv.setProgressBar(R.id.progress, 100, pct, false)

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentPI = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val notif = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCustomContentView(rv)
            .setCustomBigContentView(rv)
            .setContentIntent(contentPI)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
        notif.flags = notif.flags or
                Notification.FLAG_NO_CLEAR or
                Notification.FLAG_ONGOING_EVENT or
                Notification.FLAG_FOREGROUND_SERVICE
        return notif
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(CHANNEL_ID) != null) return

            val ch = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_LOW).apply {
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            nm.createNotificationChannel(ch)
        }
    }

    private fun hasActivityPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return true
        return ContextCompat.checkSelfPermission(this, Manifest.permission.ACTIVITY_RECOGNITION) ==
                PackageManager.PERMISSION_GRANTED
    }

    // ===== Day & persistence =====

    private fun yyyymmdd(): Int {
        val c = java.util.Calendar.getInstance()
        val y = c.get(java.util.Calendar.YEAR)
        val m = c.get(java.util.Calendar.MONTH) + 1
        val d = c.get(java.util.Calendar.DAY_OF_MONTH)
        return y * 10000 + (m * 100) + d
    }

    private fun isNewDay(): Boolean {
        val savedDay = prefs.getInt(KEY_DAY, 0)
        return savedDay != yyyymmdd()
    }

    private fun saveDay() {
        prefs.edit().putInt(KEY_DAY, yyyymmdd()).apply()
    }

    private fun persistSync(sensorBase: Float, stepsBase: Int) {
        prefs.edit()
            .putInt(KEY_DAY, yyyymmdd())
            .putFloat(KEY_SYNC_BASE_SENSOR, sensorBase)
            .putInt(KEY_SYNC_BASE_STEPS, stepsBase)
            .apply()
    }

    private fun restoreSyncIfSameDay() {
        val savedDay = prefs.getInt(KEY_DAY, 0)
        if (savedDay != yyyymmdd()) return

        val s = prefs.getFloat(KEY_SYNC_BASE_SENSOR, -1f)
        val steps = prefs.getInt(KEY_SYNC_BASE_STEPS, -1)
        if (s > 0f && steps >= 0) {
            syncBaseSensorValue = s
            syncBaseSteps = steps
        }
    }

    private fun restoreShownStateIfSameDay() {
        val savedDay = prefs.getInt(KEY_DAY, 0)
        if (savedDay != yyyymmdd()) return

        shownSteps = prefs.getInt(KEY_SHOWN_STEPS, 0).coerceAtLeast(0)
        previousShownSteps = shownSteps

        val ls = prefs.getFloat(KEY_LAST_SENSOR, -1f)
        if (ls >= 0f) lastSensorValue = ls
    }

    private fun persistShown(steps: Int) {
        prefs.edit()
            .putInt(KEY_SHOWN_STEPS, steps)
            .putInt(KEY_DAY, yyyymmdd())
            .apply()
    }

    private fun persistLastSensor(value: Float) {
        prefs.edit().putFloat(KEY_LAST_SENSOR, value).apply()
    }

    private fun clearSync() {
        syncBaseSensorValue = null
        syncBaseSteps = 0
        pendingSyncSteps = null
        lastSensorValue = null
        saveDay()
        prefs.edit()
            .remove(KEY_SYNC_BASE_SENSOR)
            .remove(KEY_SYNC_BASE_STEPS)
            .remove(KEY_SHOWN_STEPS)
            .remove(KEY_LAST_SENSOR)
            .apply()
        shownSteps = 0
        previousShownSteps = -1
        updateNotification(force = true)
    }
}
