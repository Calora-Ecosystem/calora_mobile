package ai.calora.app

import android.Manifest
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

        const val EXTRA_GOAL = "goal"
        const val EXTRA_STEPS = "steps"
        const val EXTRA_WEIGHT_KG = "weight_kg"
    }

    private var goal: Int = 8000

    private var weightKg: Float = 70f

    private lateinit var sensorManager: SensorManager
    private var stepCounterSensor: Sensor? = null

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

    override fun onCreate() {
        super.onCreate()
        Log.d("StepsFgService", "onCreate")
        ensureChannel()

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepCounterSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

        restoreSyncIfSameDay()
        restoreShownStateIfSameDay()

        weightKg = prefs.getFloat(KEY_WEIGHT, 70f).coerceAtLeast(30f)
        goal = prefs.getInt(KEY_GOAL, 8000).coerceAtLeast(1)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("StepsFgService", "onStartCommand, action: ${intent?.action}")
        when (intent?.action) {
            ACTION_START -> handleStart(intent)
            ACTION_UPDATE_GOAL -> handleUpdateGoal(intent)
            ACTION_SYNC -> handleSync(intent)
            ACTION_STOP -> handleStop()
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
        if (!hasActivityPermission()) return
        if (stepCounterSensor == null) {
            stepCounterSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        }
        registerStepSensor()
    }

    private fun handleStart(intent: Intent) {
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

        if (!hasActivityPermission()) {
            Log.w("StepsService", "ACTIVITY_RECOGNITION permission yo'q")
            return
        }

        stepCounterSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
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
        unregisterStepSensor()
        stopForeground(true)
        stopSelf()
    }

    override fun onDestroy() {
        unregisterStepSensor()
        Log.i("StepsService", "Destroyed")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun registerStepSensor() {
        val s = stepCounterSensor ?: run {
            Log.e("StepsService", "registerStepSensor: sensor null")
            return
        }

        val registered = sensorManager.registerListener(this, s, SensorManager.SENSOR_DELAY_NORMAL)
        if (!registered) Log.e("StepsService", "Sensor register bo'lmadi!")
        else Log.i("StepsService", "Sensor registered")
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

        lastSensorValue = currentSensor
        persistLastSensor(currentSensor)

        if (isNewDay()) {
            clearSync()
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

        val displayed = computeDisplayedSteps()
        if (displayed != null && displayed != previousShownSteps) {
            previousShownSteps = displayed
            shownSteps = displayed
            persistShown(displayed)
            updateNotification(force = false)
        }
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
