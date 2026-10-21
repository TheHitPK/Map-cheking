package com.asistencia.attendance.domain;

import static org.assertj.core.api.Assertions.assertThat;

import com.asistencia.schedule.domain.Shift;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.EnumSet;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class PunctualityPolicyTest {

    static final ZoneId ZONE = ZoneId.of("America/Caracas");
    final PunctualityPolicy policy = new PunctualityPolicy(ZONE);

    /** Mon–Fri 07:00–16:00, 10 min grace. */
    final Shift day = new Shift(1L, 1, 1, LocalTime.of(7, 0), LocalTime.of(16, 0),
            EnumSet.range(DayOfWeek.MONDAY, DayOfWeek.FRIDAY), 10);
    /** Every day 22:00–06:00. */
    final Shift night = new Shift(2L, 2, 1, LocalTime.of(22, 0), LocalTime.of(6, 0),
            EnumSet.allOf(DayOfWeek.class), 5);

    static Instant at(String localDateTime) {
        return LocalDateTime.parse(localDateTime).atZone(ZONE).toInstant();
    }

    @Test
    void arrivalWithinGraceIsOnTime() {
        // 2026-10-19 is a Monday
        assertThat(policy.classify(MarkType.IN, at("2026-10-19T06:40"), Optional.of(day))).isEqualTo(MarkStatus.ON_TIME);
        assertThat(policy.classify(MarkType.IN, at("2026-10-19T07:10"), Optional.of(day))).isEqualTo(MarkStatus.ON_TIME);
        assertThat(policy.classify(MarkType.IN, at("2026-10-19T07:11"), Optional.of(day))).isEqualTo(MarkStatus.LATE);
    }

    @Test
    void departureBeforeEndMinusGraceIsEarly() {
        assertThat(policy.classify(MarkType.OUT, at("2026-10-19T15:49"), Optional.of(day))).isEqualTo(MarkStatus.EARLY_LEAVE);
        assertThat(policy.classify(MarkType.OUT, at("2026-10-19T15:50"), Optional.of(day))).isEqualTo(MarkStatus.ON_TIME);
        assertThat(policy.classify(MarkType.OUT, at("2026-10-19T18:30"), Optional.of(day))).isEqualTo(MarkStatus.ON_TIME);
    }

    @Test
    void dayOffOrNoShiftIsUnscheduled() {
        // Sunday
        assertThat(policy.classify(MarkType.IN, at("2026-10-18T07:00"), Optional.of(day))).isEqualTo(MarkStatus.UNSCHEDULED);
        assertThat(policy.classify(MarkType.IN, at("2026-10-19T07:00"), Optional.empty())).isEqualTo(MarkStatus.UNSCHEDULED);
    }

    @Test
    void overnightShiftEndsNextDay() {
        assertThat(policy.classify(MarkType.IN, at("2026-10-19T22:20"), Optional.of(night))).isEqualTo(MarkStatus.LATE);
        assertThat(policy.classify(MarkType.OUT, at("2026-10-20T06:02"), Optional.of(night))).isEqualTo(MarkStatus.ON_TIME);
        assertThat(policy.classify(MarkType.OUT, at("2026-10-20T03:00"), Optional.of(night))).isEqualTo(MarkStatus.EARLY_LEAVE);
    }
}
