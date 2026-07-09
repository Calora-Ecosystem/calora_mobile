package ai.calora.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat

/// Idempotent "make sure the step FG service is running" trigger.
/// Fires from the periodic WorkManager task in the Dart background
/// isolate — that isolate can't reach the MainActivity MethodChannel
/// (different Flutter engine), so a broadcast is the cross-isolate
/// primitive that works.
///
/// The service's `handleAutoRestart` path (empty-intent branch) just
/// re-asserts foreground when the service is alive, so this is safe to
/// broadcast on every WM tick.
class StepsWatchdogReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_KICK = "ai.calora.app.steps.WATCHDOG_KICK"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != ACTION_KICK) return
        try {
            val i = Intent(context, StepsFgService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(context, i)
            } else {
                context.startService(i)
            }
            Log.d("StepsWatchdogReceiver", "Kicked StepsFgService")
        } catch (t: Throwable) {
            Log.w("StepsWatchdogReceiver", "Kick failed: ${t.message}")
        }
    }
}
