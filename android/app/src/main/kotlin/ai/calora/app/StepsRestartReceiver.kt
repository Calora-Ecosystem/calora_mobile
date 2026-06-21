package ai.calora.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat

/// Restarts [StepsFgService] in every situation where Android has torn it
/// down but the user expects step counting to keep going:
///
///  • Device reboot (`BOOT_COMPLETED` / vendor "quickboot").  The hardware
///    `TYPE_STEP_COUNTER` resets to 0 on boot, so getting the service back
///    up promptly is what stops a multi-day gap when the user hasn't opened
///    the app in a week or two.
///  • App update (`MY_PACKAGE_REPLACED`) — the process is killed on update.
///  • Keep-alive alarm (`ACTION_KEEPALIVE`) — a periodic self-heal armed by
///    the service itself, so a low-memory kill that START_STICKY didn't
///    recover gets repaired within ~30 min while the device is still awake.
///
/// All of these contexts (boot broadcast, app-update broadcast, and an
/// `AllowWhileIdle` alarm) place the app on the temporary power allowlist,
/// which is what permits starting a foreground service from the background
/// on Android 12+. We pass [StepsFgService.ACTION_START] so the service
/// re-asserts its foreground notification AND re-registers the sensor; the
/// service restores goal/weight/baseline from its own prefs in onCreate, so
/// no extras are required and the persisted day total is preserved.
class StepsRestartReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_KEEPALIVE = "ai.calora.app.steps.KEEPALIVE"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val reason = intent?.action ?: "unknown"
        Log.i("StepsRestartReceiver", "Restart trigger: $reason")
        try {
            val i = Intent(context, StepsFgService::class.java).apply {
                action = StepsFgService.ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(context, i)
            } else {
                context.startService(i)
            }
        } catch (t: Throwable) {
            // Background-start refusal is non-fatal: START_STICKY, the next
            // keep-alive alarm, or the next app open will recover counting.
            Log.w("StepsRestartReceiver", "restart failed ($reason): ${t.message}")
        }
    }
}
