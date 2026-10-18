package ai.calora.steps

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlin.math.roundToInt

data class CounterState(
    val day: Int = 0,
    val steps: Int = 0,
    val sensorSteps: Int = 0,
    val lastSensor: Float = NO_READING,
    val lastSensorAt: Long = 0L,
    val sensorBoot: Int = UNKNOWN_BOOT,
    val pendingGap: Int = 0,
    val pendingGapUntil: Long = 0L,
    val source: String = SOURCE_SENSOR,
) {
    val hasReading: Boolean get() = lastSensor >= 0f

    companion object {
        const val NO_READING = -1f
        const val UNKNOWN_BOOT = -1
        const val MIGRATED_BOOT = -2
        const val SOURCE_SENSOR = "sensor"
        const val SOURCE_HEALTH_CONNECT = "health_connect"
        const val SOURCE_RECORDING = "recording"
    }
}

data class Clock(
    val now: Long,
    val zone: ZoneId,
    val boot: Int,
    val bootAt: Long,
) {
    val today: Int get() = dayOf(now)
    val startOfToday: Long get() = startOfDay(today)

    fun dayOf(epochMs: Long): Int = DayKeys.of(Instant.ofEpochMilli(epochMs).atZone(zone).toLocalDate())

    fun startOfDay(day: Int): Long = DayKeys.toDate(day).atStartOfDay(zone).toInstant().toEpochMilli()
}

data class FinalizedDay(val day: Int, val steps: Int)

data class LateCredit(val day: Int, val steps: Int)

data class Transition(
    val state: CounterState,
    val changed: Boolean,
    val finalized: FinalizedDay? = null,
    val lateCredit: LateCredit? = null,
)

object DayKeys {
    fun of(date: LocalDate): Int = date.year * 10_000 + date.monthValue * 100 + date.dayOfMonth

    fun toDate(day: Int): LocalDate = LocalDate.of(day / 10_000, (day / 100) % 100, day % 100)

    fun iso(day: Int): String = "%04d-%02d-%02d".format(day / 10_000, (day / 100) % 100, day % 100)

    fun minusDays(day: Int, days: Long): Int = of(toDate(day).minusDays(days))
}

object StepCounterMath {
    const val DAY_MS = 86_400_000L
    const val MAX_STEPS_PER_SECOND = 4.0
    const val CADENCE_SLACK = 250
    const val SHORT_WINDOW_MS = 3 * 60 * 60 * 1000L
    const val GAP_GRACE_MS = 90_000L

    fun rollover(state: CounterState, targetDay: Int, resumeSteps: Int): Transition {
        if (state.day == targetDay) return Transition(state, changed = false)
        val finalized = if (state.day != 0 && state.steps + state.pendingGap > 0) {
            FinalizedDay(state.day, state.steps + state.pendingGap)
        } else {
            null
        }
        val next = state.copy(
            day = targetDay,
            steps = resumeSteps.coerceAtLeast(0),
            sensorSteps = 0,
            pendingGap = 0,
            pendingGapUntil = 0L,
            source = CounterState.SOURCE_SENSOR,
        )
        return Transition(next, changed = true, finalized = finalized)
    }

    fun onReading(
        state: CounterState,
        value: Float,
        eventAt: Long,
        clock: Clock,
        resumeStepsFor: (Int) -> Int,
    ): Transition {
        if (value < 0f || value.isNaN()) return Transition(state, changed = false)

        val window = windowFor(state, value, clock)
        val eventDay = clock.dayOf(eventAt)
        var current = state
        var finalized: FinalizedDay? = null

        if (current.day == 0 || eventDay > current.day) {
            val rolled = rollover(current, eventDay, resumeStepsFor(eventDay))
            current = rolled.state
            finalized = rolled.finalized
        }

        val delta = sanitize(window, eventAt)
        val withReading = current.copy(lastSensor = value, lastSensorAt = eventAt, sensorBoot = clock.boot)

        if (delta <= 0) {
            return Transition(withReading, changed = true, finalized = finalized)
        }

        if (eventDay < withReading.day) {
            return Transition(
                withReading,
                changed = true,
                finalized = finalized,
                lateCredit = LateCredit(eventDay, delta),
            )
        }

        val startOfEventDay = clock.startOfDay(eventDay)
        val next = when {
            window.start >= startOfEventDay || eventAt - window.start <= SHORT_WINDOW_MS -> withReading.copy(
                steps = withReading.steps + delta,
                sensorSteps = withReading.sensorSteps + delta,
            )

            window.firstEver -> withReading

            window.start >= startOfEventDay - DAY_MS -> withReading.copy(
                pendingGap = withReading.pendingGap + delta,
                pendingGapUntil = clock.now + GAP_GRACE_MS,
            )

            else -> withReading
        }
        return Transition(next, changed = true, finalized = finalized)
    }

    fun mergeExternal(state: CounterState, clock: Clock, total: Int, source: String, coversWholeDay: Boolean): Transition {
        if (state.day != clock.today) return Transition(state, changed = false)
        var next = state
        if (coversWholeDay && next.pendingGap > 0) {
            next = next.copy(pendingGap = 0, pendingGapUntil = 0L)
        }
        if (total > next.steps) {
            next = next.copy(steps = total, source = source)
        }
        return Transition(next, changed = next != state)
    }

    fun settleGap(state: CounterState, clock: Clock): Transition {
        if (state.pendingGap <= 0 || clock.now < state.pendingGapUntil) return Transition(state, changed = false)
        val next = state.copy(
            steps = state.steps + state.pendingGap,
            sensorSteps = state.sensorSteps + state.pendingGap,
            pendingGap = 0,
            pendingGapUntil = 0L,
        )
        return Transition(next, changed = true)
    }

    private data class Window(val start: Long, val steps: Float, val firstEver: Boolean)

    private fun windowFor(state: CounterState, value: Float, clock: Clock): Window {
        val sameBoot = state.hasReading && (
            state.sensorBoot == clock.boot ||
                (state.sensorBoot == CounterState.MIGRATED_BOOT && value + 0.5f >= state.lastSensor)
            )
        if (sameBoot) {
            val steps = if (value + 0.5f < state.lastSensor) value else value - state.lastSensor
            return Window(start = state.lastSensorAt, steps = steps, firstEver = false)
        }
        return Window(start = clock.bootAt, steps = value, firstEver = !state.hasReading)
    }

    private fun sanitize(window: Window, eventAt: Long): Int {
        val steps = window.steps.roundToInt()
        if (steps <= 0) return 0
        val elapsedMs = eventAt - window.start
        if (elapsedMs < 0) return steps
        val ceiling = (elapsedMs / 1000.0 * MAX_STEPS_PER_SECOND).toInt() + CADENCE_SLACK
        return if (steps > ceiling) 0 else steps
    }
}
