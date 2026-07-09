package ai.calora.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat

/// Brings the step foreground service back up on boot, package-replace,
/// and vendor "quick boot" broadcasts. Without this, a reboot leaves the
/// service dead and the AlarmManager midnight-reset trigger cleared, so
/// counting only resumes when the user next opens the app — which is
/// exactly the multi-day-idle failure mode.
///
/// The service's own onCreate handles state restore (KEY_DAY, shown_steps,
/// last_sensor) and re-arms the midnight AlarmManager, so this receiver's
/// only responsibility is to start it.
class StepsBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val evt = intent?.action ?: return
        val shouldStart = when (evt) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> true
            else -> false
        }
        if (!shouldStart) return

        try {
            val start = Intent(context, StepsFgService::class.java).apply {
                action = StepsFgService.ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(context, start)
            } else {
                context.startService(start)
            }
            Log.i("StepsBootReceiver", "Started StepsFgService on $evt")
        } catch (t: Throwable) {
            Log.w("StepsBootReceiver", "Boot start failed: ${t.message}")
        }
    }
}
