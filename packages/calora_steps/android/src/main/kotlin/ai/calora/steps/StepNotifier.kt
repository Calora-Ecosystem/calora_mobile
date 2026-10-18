package ai.calora.steps

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import java.text.NumberFormat
import java.util.Locale
import kotlin.math.roundToInt

data class NotificationContent(
    val steps: Int,
    val goal: Int,
    val kcal: Int,
    val labels: NotificationLabels,
)

class StepNotifier(private val context: Context) {

    private val manager = NotificationManagerCompat.from(context)
    private var channelName: String? = null
    private var lastPosted: NotificationContent? = null

    fun canPost(): Boolean {
        if (!manager.areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    fun ensureChannel(labels: NotificationLabels) {
        if (channelName == labels.channel) return
        val system = context.getSystemService(NotificationManager::class.java) ?: return
        try {
            system.deleteNotificationChannel(LEGACY_CHANNEL_ID)
            val channel = NotificationChannel(CHANNEL_ID, labels.channel, NotificationManager.IMPORTANCE_LOW).apply {
                setShowBadge(false)
                enableVibration(false)
                enableLights(false)
                setSound(null, null)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            system.createNotificationChannel(channel)
            channelName = labels.channel
        } catch (t: Throwable) {
            Log.w(TAG, "Notification channel setup failed: ${t.message}")
        }
    }

    fun build(content: NotificationContent): Notification {
        ensureChannel(content.labels)
        val labels = content.labels
        val format = NumberFormat.getIntegerInstance(Locale.forLanguageTag(labels.locale))
        val goal = content.goal.coerceAtLeast(1)
        val percent = ((content.steps.toDouble() / goal) * 100).roundToInt().coerceIn(0, 100)
        val reached = content.steps >= goal
        val stepsTitle = labels.title.replace("{steps}", format.format(content.steps))
        val title = if (reached) "$stepsTitle · ${labels.goalReached}" else stepsTitle
        val goalText = labels.goal.replace("{goal}", format.format(goal))
        val kcalText = labels.kcal.replace("{kcal}", format.format(content.kcal))
        val text = "$kcalText · $goalText · $percent%"

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.calora_steps_ic_stat)
            .setColor(ACCENT_COLOR)
            .setContentTitle(title)
            .setContentText(text)
            .setProgress(100, percent, false)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setShowWhen(false)
            .setLocalOnly(true)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setContentIntent(openAppIntent())
            .build()
    }

    fun post(content: NotificationContent, force: Boolean = false) {
        if (!force && content == lastPosted) return
        if (!canPost()) return
        try {
            manager.notify(NOTIFICATION_ID, build(content))
            lastPosted = content
        } catch (e: SecurityException) {
            Log.w(TAG, "Notification post denied: ${e.message}")
        }
    }

    fun cancel() {
        manager.cancel(NOTIFICATION_ID)
        lastPosted = null
    }

    private fun openAppIntent(): PendingIntent? {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(
            context,
            REQUEST_OPEN_APP,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        private const val TAG = "CaloraSteps.Notifier"
        const val CHANNEL_ID = "calora_steps_live"
        const val NOTIFICATION_ID = 2110
        private const val LEGACY_CHANNEL_ID = "calora_steps_native_notif"
        private const val REQUEST_OPEN_APP = 2112
        private const val ACCENT_COLOR = 0xFF46A758.toInt()
    }
}
