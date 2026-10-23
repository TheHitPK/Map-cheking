package com.asistencia.payroll.domain;

import static org.assertj.core.api.Assertions.assertThat;

import com.asistencia.attendance.domain.AttendanceMark;
import com.asistencia.attendance.domain.LocationReading;
import com.asistencia.attendance.domain.MarkStatus;
import com.asistencia.attendance.domain.MarkType;
import com.asistencia.attendance.domain.RejectionReason;
import com.asistencia.shared.domain.GeoPoint;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class TimesheetTest {

    static final ZoneId ZONE = ZoneId.of("America/Chicago");
    static final Duration FORGOTTEN = Duration.ofHours(20);
    /** Mon 2026-10-19 → Sun 2026-10-25. */
    static final PayPeriod WEEK = new PayPeriod(LocalDate.of(2026, 10, 19));
    static final Instant LATER = at("2026-11-02T12:00");

    static Instant at(String local) {
        return LocalDateTime.parse(local).atZone(ZONE).toInstant();
    }

    static AttendanceMark mark(MarkType type, String local, MarkStatus status) {
        Instant t = at(local);
        return new AttendanceMark(1L, UUID.randomUUID(), 7, 1L, type, t, t, t,
                new LocationReading(new GeoPoint(41.88, -87.63), 10, false), 5.0, status,
                status == MarkStatus.REJECTED ? RejectionReason.OUT_OF_ZONE : null, false);
    }

    static AttendanceMark in(String local) {
        return mark(MarkType.IN, local, MarkStatus.ON_TIME);
    }

    static AttendanceMark out(String local) {
        return mark(MarkType.OUT, local, MarkStatus.ON_TIME);
    }

    static Timesheet sheet(Instant now, AttendanceMark... marks) {
        return Timesheet.of(WEEK, List.of(marks), now, FORGOTTEN, ZONE);
    }

    @Test
    void pairsPunchesIntoClockMinutes() {
        Timesheet t = sheet(LATER,
                in("2026-10-19T07:58:40"), out("2026-10-19T16:31:10"),
                in("2026-10-20T08:00"), out("2026-10-20T12:00"));
        assertThat(t.workedMinutes()).isEqualTo(513 + 240);
        assertThat(t.minutesByDay()).containsExactly(
                java.util.Map.entry(LocalDate.of(2026, 10, 19), 513),
                java.util.Map.entry(LocalDate.of(2026, 10, 20), 240));
        assertThat(t.missingOuts()).isZero();
    }

    @Test
    void rejectedPunchesDoNotCount() {
        Timesheet t = sheet(LATER, in("2026-10-19T07:00"), mark(MarkType.OUT, "2026-10-19T09:00", MarkStatus.REJECTED),
                out("2026-10-19T15:00"));
        assertThat(t.workedMinutes()).isEqualTo(480);
    }

    @Test
    void forgottenPunchOutIsFlaggedAndUnpaid() {
        Timesheet t = sheet(LATER, in("2026-10-21T07:00"), in("2026-10-22T07:00"), out("2026-10-22T15:00"),
                in("2026-10-23T07:00"));
        assertThat(t.workedMinutes()).isEqualTo(480);
        assertThat(t.missingOuts()).isEqualTo(2);
        assertThat(t.inProgress()).isFalse();
    }

    @Test
    void openShiftCountsUpToNow() {
        Timesheet t = sheet(at("2026-10-23T11:30"), in("2026-10-23T07:00"));
        assertThat(t.inProgress()).isTrue();
        assertThat(t.workedMinutes()).isEqualTo(270);
    }

    @Test
    void overnightShiftBelongsToTheDayAndWeekItStarted() {
        Timesheet t = sheet(LATER,
                out("2026-10-19T06:00"), // punch-in was last week
                in("2026-10-25T22:00"), out("2026-10-26T06:00"),
                in("2026-10-26T22:00"), out("2026-10-27T06:00")); // next week
        assertThat(t.workedMinutes()).isEqualTo(480);
        assertThat(t.minutesByDay()).containsOnlyKeys(LocalDate.of(2026, 10, 25));
    }

    @Test
    void periodRunsMondayToSundayAndPaysFriday() {
        PayPeriod p = PayPeriod.containing(LocalDate.of(2026, 10, 25));
        assertThat(p).isEqualTo(WEEK);
        assertThat(p.end()).isEqualTo(LocalDate.of(2026, 10, 25));
        assertThat(p.defaultPayDate()).isEqualTo(LocalDate.of(2026, 10, 30));
        assertThat(PayPeriod.containing(LocalDate.of(2026, 10, 26)).previous()).isEqualTo(WEEK);
    }
}
