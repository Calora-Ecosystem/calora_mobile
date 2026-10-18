package ai.calora.steps

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener2
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import android.os.SystemClock

class StepSensor(
    context: Context,
    private val onReading: (value: Float, eventAt: Long) -> Unit,
) : SensorEventListener2 {

    private val manager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val handler = Handler(Looper.getMainLooper())
    private val flushWaiters = mutableListOf<() -> Unit>()
    private var sensor: Sensor? = null

    var isListening: Boolean = false
        private set

    val isAvailable: Boolean
        get() = resolve() != null

    private fun resolve(): Sensor? =
        manager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER, false)
            ?: manager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

    fun start(): Boolean {
        if (isListening) return true
        val target = resolve() ?: return false
        val latencyUs = if (target.isWakeUpSensor) WAKE_UP_LATENCY_US else BATCH_LATENCY_US
        isListening = manager.registerListener(this, target, SensorManager.SENSOR_DELAY_NORMAL, latencyUs, handler) ||
            manager.registerListener(this, target, SensorManager.SENSOR_DELAY_NORMAL, handler)
        if (isListening) sensor = target
        return isListening
    }

    fun stop() {
        if (!isListening) return
        manager.unregisterListener(this)
        isListening = false
        sensor = null
        drainFlushWaiters()
    }

    fun flush(timeoutMs: Long = FLUSH_TIMEOUT_MS, onDone: () -> Unit) {
        if (!isListening || !manager.flush(this)) {
            onDone()
            return
        }
        var finished = false
        val finish = {
            if (!finished) {
                finished = true
                onDone()
            }
        }
        flushWaiters += finish
        handler.postDelayed({
            if (flushWaiters.remove(finish)) finish()
        }, timeoutMs)
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_STEP_COUNTER || event.values.isEmpty()) return
        onReading(event.values[0], wallClockOf(event.timestamp))
    }

    override fun onFlushCompleted(sensor: Sensor?) = drainFlushWaiters()

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    private fun drainFlushWaiters() {
        val waiters = flushWaiters.toList()
        flushWaiters.clear()
        waiters.forEach { it() }
    }

    private fun wallClockOf(eventNanos: Long): Long {
        val now = System.currentTimeMillis()
        val ageMs = (SystemClock.elapsedRealtimeNanos() - eventNanos) / 1_000_000L
        return if (ageMs in 0..MAX_EVENT_AGE_MS) now - ageMs else now
    }

    companion object {
        private const val BATCH_LATENCY_US = 10_000_000
        private const val WAKE_UP_LATENCY_US = 300_000_000
        private const val FLUSH_TIMEOUT_MS = 1_500L
        private const val MAX_EVENT_AGE_MS = 7L * 24 * 60 * 60 * 1000
    }
}
