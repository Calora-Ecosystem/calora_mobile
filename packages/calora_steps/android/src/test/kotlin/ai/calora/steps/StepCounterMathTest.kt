package ai.calora.steps

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDateTime
import java.time.ZoneId

class StepCounterMathTest {

    private val zone: ZoneId = ZoneId.of("Asia/Tashkent")

    private fun at(day: Int, hour: Int, minute: Int = 0): Long =
        LocalDateTime.of(2026, 10, day, hour, minute).atZone(zone).toInstant().toEpochMilli()

    private fun clock(now: Long, boot: Int = 7, bootAt: Long = at(1, 6)) =
        Clock(now = now, zone = zone, boot = boot, bootAt = bootAt)

    private fun read(
        state: CounterState,
        value: Float,
        now: Long,
        boot: Int = 7,
        bootAt: Long = at(1, 6),
        eventAt: Long = now,
        history: Map<Int, Int> = emptyMap(),
    ) = StepCounterMath.onReading(state, value, eventAt, clock(now, boot, bootAt)) { history[it] ?: 0 }

    @Test
    fun firstReadingCountsStepsSinceTodaysBoot() {
        val result = read(CounterState(), 420f, now = at(17, 9), bootAt = at(17, 7))
        assertEquals(20261017, result.state.day)
        assertEquals(420, result.state.steps)
        assertEquals(420, result.state.sensorSteps)
    }

    @Test
    fun firstReadingIgnoresStepsFromOlderBoot() {
        val result = read(CounterState(), 25_000f, now = at(17, 9), bootAt = at(14, 7))
        assertEquals(0, result.state.steps)
        assertEquals(25_000f, result.state.lastSensor)
    }

    @Test
    fun sameBootReadingsAddDeltas() {
        var state = read(CounterState(), 1_000f, now = at(17, 8), bootAt = at(17, 7)).state
        state = read(state, 1_250f, now = at(17, 9), bootAt = at(17, 7)).state
        state = read(state, 1_900f, now = at(17, 10), bootAt = at(17, 7)).state
        assertEquals(1_900, state.steps)
    }

    @Test
    fun rebootTodayAddsStepsSinceBoot() {
        val before = CounterState(
            day = 20261017,
            steps = 3_000,
            lastSensor = 52_000f,
            lastSensorAt = at(17, 9),
            sensorBoot = 7,
        )
        val result = read(before, 300f, now = at(17, 11), boot = 8, bootAt = at(17, 10, 30))
        assertEquals(3_300, result.state.steps)
        assertEquals(8, result.state.sensorBoot)
    }

    @Test
    fun counterResetWithoutRebootCountsNewValue() {
        val before = CounterState(day = 20261017, steps = 2_000, lastSensor = 9_000f, lastSensorAt = at(17, 9), sensorBoot = 7)
        val result = read(before, 150f, now = at(17, 10))
        assertEquals(2_150, result.state.steps)
    }

    @Test
    fun shortWindowAcrossMidnightGoesToNewDayAndFinalizesOldDay() {
        val before = CounterState(day = 20261016, steps = 8_100, lastSensor = 40_000f, lastSensorAt = at(16, 23, 40), sensorBoot = 7)
        val result = read(before, 40_120f, now = at(17, 0, 20))
        assertEquals(FinalizedDay(20261016, 8_100), result.finalized)
        assertEquals(20261017, result.state.day)
        assertEquals(120, result.state.steps)
    }

    @Test
    fun lateBatchedEventIsCreditedToPreviousDay() {
        val rolled = StepCounterMath.rollover(
            CounterState(day = 20261016, steps = 8_100, lastSensor = 40_000f, lastSensorAt = at(16, 23, 40), sensorBoot = 7),
            targetDay = 20261017,
            resumeSteps = 0,
        )
        assertEquals(FinalizedDay(20261016, 8_100), rolled.finalized)
        val late = read(rolled.state, 40_300f, now = at(17, 0, 1), eventAt = at(16, 23, 55))
        assertEquals(LateCredit(20261016, 300), late.lateCredit)
        assertEquals(0, late.state.steps)
        val next = read(late.state, 40_350f, now = at(17, 0, 30))
        assertEquals(50, next.state.steps)
    }

    @Test
    fun longGapAcrossMidnightWaitsForExternalTruth() {
        val before = CounterState(day = 20261016, steps = 6_000, lastSensor = 30_000f, lastSensorAt = at(16, 19), sensorBoot = 7)
        val now = at(17, 9)
        val result = read(before, 34_000f, now = now)
        assertEquals(0, result.state.steps)
        assertEquals(4_000, result.state.pendingGap)

        val merged = StepCounterMath.mergeExternal(result.state, clock(now), 2_600, CounterState.SOURCE_RECORDING, coversWholeDay = true)
        assertEquals(2_600, merged.state.steps)
        assertEquals(0, merged.state.pendingGap)
        assertEquals(CounterState.SOURCE_RECORDING, merged.state.source)
    }

    @Test
    fun pendingGapIsAttributedToTodayWhenNoExternalSourceAnswers() {
        val before = CounterState(day = 20261016, steps = 6_000, lastSensor = 30_000f, lastSensorAt = at(16, 19), sensorBoot = 7)
        val now = at(17, 9)
        val pending = read(before, 34_000f, now = now).state
        val early = StepCounterMath.settleGap(pending, clock(now + 10_000))
        assertTrue(!early.changed)
        val settled = StepCounterMath.settleGap(pending, clock(now + StepCounterMath.GAP_GRACE_MS + 1))
        assertEquals(4_000, settled.state.steps)
        assertEquals(0, settled.state.pendingGap)
    }

    @Test
    fun gapLongerThanADayIsDropped() {
        val before = CounterState(day = 20261013, steps = 6_000, lastSensor = 30_000f, lastSensorAt = at(13, 19), sensorBoot = 7)
        val result = read(before, 60_000f, now = at(17, 9))
        assertEquals(20261017, result.state.day)
        assertEquals(0, result.state.steps)
        assertEquals(0, result.state.pendingGap)
    }

    @Test
    fun impossibleCadenceIsIgnored() {
        val before = CounterState(day = 20261017, steps = 1_000, lastSensor = 5_000f, lastSensorAt = at(17, 9), sensorBoot = 7)
        val result = read(before, 95_000f, now = at(17, 9, 1))
        assertEquals(1_000, result.state.steps)
        assertEquals(95_000f, result.state.lastSensor)
    }

    @Test
    fun externalValuesOnlyRaiseTheCount() {
        val state = CounterState(day = 20261017, steps = 5_000, lastSensor = 1f, lastSensorAt = at(17, 9), sensorBoot = 7)
        val lower = StepCounterMath.mergeExternal(state, clock(at(17, 10)), 4_200, CounterState.SOURCE_HEALTH_CONNECT, true)
        assertEquals(5_000, lower.state.steps)
        assertTrue(!lower.changed)
        val higher = StepCounterMath.mergeExternal(state, clock(at(17, 10)), 7_300, CounterState.SOURCE_HEALTH_CONNECT, true)
        assertEquals(7_300, higher.state.steps)
        assertEquals(CounterState.SOURCE_HEALTH_CONNECT, higher.state.source)
    }

    @Test
    fun sensorKeepsCountingOnTopOfExternalValue() {
        var state = CounterState(day = 20261017, steps = 5_000, lastSensor = 10_000f, lastSensorAt = at(17, 9), sensorBoot = 7)
        state = StepCounterMath.mergeExternal(state, clock(at(17, 9)), 7_300, CounterState.SOURCE_HEALTH_CONNECT, true).state
        state = read(state, 10_200f, now = at(17, 9, 5)).state
        assertEquals(7_500, state.steps)
    }

    @Test
    fun externalValueForAnotherDayIsIgnored() {
        val state = CounterState(day = 20261016, steps = 5_000)
        val result = StepCounterMath.mergeExternal(state, clock(at(17, 10)), 9_000, CounterState.SOURCE_HEALTH_CONNECT, true)
        assertEquals(5_000, result.state.steps)
    }

    @Test
    fun migratedStateKeepsCountingWithinTheSameBoot() {
        val migrated = CounterState(
            day = 20261017,
            steps = 2_000,
            lastSensor = 8_000f,
            lastSensorAt = at(17, 0),
            sensorBoot = CounterState.MIGRATED_BOOT,
        )
        val sameBoot = read(migrated, 8_600f, now = at(17, 12))
        assertEquals(2_600, sameBoot.state.steps)
        val rebooted = read(migrated, 90f, now = at(17, 12), boot = 9, bootAt = at(17, 11))
        assertEquals(2_090, rebooted.state.steps)
    }

    @Test
    fun rolloverResumesKnownDayTotals() {
        val state = CounterState(day = 20261017, steps = 1_000)
        val result = StepCounterMath.rollover(state, targetDay = 20261016, resumeSteps = 7_000)
        assertEquals(20261016, result.state.day)
        assertEquals(7_000, result.state.steps)
        assertEquals(FinalizedDay(20261017, 1_000), result.finalized)
    }

    @Test
    fun emptyDayIsNotFinalized() {
        val result = StepCounterMath.rollover(CounterState(day = 20261016, steps = 0), targetDay = 20261017, resumeSteps = 0)
        assertNull(result.finalized)
    }
}
