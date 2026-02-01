package ai.calora.app

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import kotlin.math.roundToInt

class StepsFgService : Service() {

    companion object {
        const val CHANNEL_ID = "calora_steps_native_v2"
        const val CHANNEL_NAME = "Calora Steps"
        const val NOTIF_ID = 2110

        const val ACTION_START = "ai.calora.app.steps.START"
        const val ACTION_UPDATE = "ai.calora.app.steps.UPDATE"
        const val ACTION_STOP = "ai.calora.app.steps.STOP"

        const val EXTRA_STEPS = "steps"
        const val EXTRA_GOAL = "goal"

        fun start(context: Context, steps: Int = 0, goal: Int = 8000) {
            val i = Intent(context, StepsFgService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_STEPS, steps)
                putExtra(EXTRA_GOAL, goal)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) context.startForegroundService(i)
            else context.startService(i)
        }

        fun update(context: Context, steps: Int, goal: Int) {
            val i = Intent(context, StepsFgService::class.java).apply {
                action = ACTION_UPDATE
                putExtra(EXTRA_STEPS, steps)
                putExtra(EXTRA_GOAL, goal)
            }
            context.startService(i)
        }

        fun stop(context: Context) {
            val i = Intent(context, StepsFgService::class.java).apply { action = ACTION_STOP }
            context.startService(i)
        }
    }

    private var steps: Int = 0
    private var goal: Int = 8000

    override fun onCreate() {
        super.onCreate()
        ensureChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                steps = intent.getIntExtra(EXTRA_STEPS, 0)
                goal = intent.getIntExtra(EXTRA_GOAL, 8000)
                startForeground(NOTIF_ID, buildNotification())
            }

            ACTION_UPDATE -> {
                steps = intent.getIntExtra(EXTRA_STEPS, steps)
                goal = intent.getIntExtra(EXTRA_GOAL, goal)
                startForeground(NOTIF_ID, buildNotification())
            }

            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(): Notification {
        val rv = RemoteViews(packageName, R.layout.notif_steps)

        val safeGoal = if (goal <= 0) 1 else goal
        val kcal = (steps * 0.04).roundToInt()
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

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // xohlasangiz keyin almashtiramiz
            .setCustomContentView(rv)
            .setCustomBigContentView(rv)
            .setContentIntent(contentPI)

            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)

            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)

            // ✅ lockscreen
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(CHANNEL_ID) != null) return

            val ch = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            nm.createNotificationChannel(ch)
        }
    }
}
