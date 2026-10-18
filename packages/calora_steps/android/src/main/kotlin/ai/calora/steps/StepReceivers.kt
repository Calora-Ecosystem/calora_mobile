package ai.calora.steps

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class StepSystemReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        StepEngine.init(context)
        StepEngine.onSystemBroadcast(intent.action)
    }
}

class StepAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        StepEngine.init(context)
        if (!StepEngine.isMidnightAction(intent.action)) return
        val pending = goAsync()
        StepEngine.onMidnightAlarm { pending.finish() }
    }
}
