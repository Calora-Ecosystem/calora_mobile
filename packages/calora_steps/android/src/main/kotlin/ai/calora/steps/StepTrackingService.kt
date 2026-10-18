package ai.calora.steps

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.ServiceCompat

class StepTrackingService : Service() {

    override fun onCreate() {
        super.onCreate()
        StepEngine.init(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        StepEngine.init(this)
        if (!enterForeground()) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (!StepEngine.isEnabled) {
            stopSelf()
            return START_NOT_STICKY
        }
        StepEngine.onServiceStarted()
        return START_STICKY
    }

    private fun enterForeground(): Boolean = try {
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
        } else {
            0
        }
        if (type == 0) {
            startForeground(StepNotifier.NOTIFICATION_ID, StepEngine.notification())
        } else {
            ServiceCompat.startForeground(this, StepNotifier.NOTIFICATION_ID, StepEngine.notification(), type)
        }
        true
    } catch (t: Throwable) {
        Log.w(TAG, "startForeground failed: ${t.message}")
        false
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        StepEngine.persistNow()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        StepEngine.onServiceStopped()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private companion object {
        const val TAG = "CaloraSteps.Service"
    }
}
