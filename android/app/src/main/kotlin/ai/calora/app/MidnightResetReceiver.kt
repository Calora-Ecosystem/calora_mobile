package ai.calora.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat

/// Fires at (around) local midnight from the AlarmManager and tells the
/// step foreground service to snap its notification to 0 for the new day.
///
/// When an exact/while-idle alarm fires, the app is briefly placed on the
/// temporary power allowlist, which permits starting a foreground service
/// even from the background.
class MidnightResetReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        try {
            val i = Intent(context, StepsFgService::class.java).apply {
                action = StepsFgService.ACTION_MIDNIGHT_RESET
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(context, i)
            } else {
                context.startService(i)
            }
        } catch (t: Throwable) {
            Log.w("MidnightResetReceiver", "failed to deliver reset: ${t.message}")
        }
    }
}
