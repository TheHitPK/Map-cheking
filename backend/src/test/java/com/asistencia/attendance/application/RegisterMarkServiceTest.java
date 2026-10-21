package com.asistencia.attendance.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.asistencia.attendance.application.port.MarkRepository;
import com.asistencia.attendance.domain.AttendanceMark;
import com.asistencia.attendance.domain.LocationReading;
import com.asistencia.attendance.domain.MarkAttempt;
import com.asistencia.attendance.domain.MarkStatus;
import com.asistencia.attendance.domain.MarkType;
import com.asistencia.attendance.domain.PunctualityPolicy;
import com.asistencia.attendance.domain.RejectionReason;
import com.asistencia.attendance.domain.rule.AccuracyRule;
import com.asistencia.attendance.domain.rule.CaptureTimeRule;
import com.asistencia.attendance.domain.rule.GeofenceRule;
import com.asistencia.attendance.domain.rule.MockLocationRule;
import com.asistencia.attendance.domain.rule.SequenceRule;
import com.asistencia.attendance.domain.rule.WorksiteAssignedRule;
import com.asistencia.schedule.application.port.ShiftRepository;
import com.asistencia.schedule.domain.Shift;
import com.asistencia.shared.application.UnitOfWork;
import com.asistencia.shared.domain.GeoPoint;
import com.asistencia.worksite.application.port.WorksiteRepository;
import com.asistencia.worksite.domain.Worksite;
import java.time.Clock;
import java.time.DayOfWeek;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Use case with in-memory adapters: no Spring, no database. */
class RegisterMarkServiceTest {

    static final ZoneId ZONE = ZoneId.of("America/Caracas");
    static final GeoPoint SITE = new GeoPoint(10.6427, -71.6125);
    static final long WORKER = 7;

    final InMemoryMarks marks = new InMemoryMarks();
    Instant now = LocalDateTime.parse("2026-10-19T07:05").atZone(ZONE).toInstant(); // Monday
    RegisterMarkService service;

    @BeforeEach
    void setUp() {
        Shift shift = new Shift(1L, WORKER, 1, LocalTime.of(7, 0), LocalTime.of(16, 0),
                EnumSet.range(DayOfWeek.MONDAY, DayOfWeek.FRIDAY), 10);
        Worksite site = new Worksite(1L, "Obra Norte", "", SITE, 100, true);
        ShiftRepository shifts = new ShiftRepository() {
            public Optional<Shift> findByEmployee(long id) { return id == WORKER ? Optional.of(shift) : Optional.empty(); }
            public List<Shift> findAll() { return List.of(shift); }
            public Shift save(Shift s) { return s; }
            public boolean deleteByEmployee(long id) { return false; }
        };
        WorksiteRepository sites = new WorksiteRepository() {
            public Optional<Worksite> findById(long id) { return id == 1 ? Optional.of(site) : Optional.empty(); }
            public List<Worksite> findAll() { return List.of(site); }
            public Worksite save(Worksite w) { return w; }
        };
        Clock clock = new Clock() {
            public ZoneId getZone() { return ZoneOffset.UTC; }
            public Clock withZone(ZoneId z) { return this; }
            public Instant instant() { return now; }
        };
        service = new RegisterMarkService(marks, shifts, sites, List.of(
                new WorksiteAssignedRule(),
                new CaptureTimeRule(Duration.ofMinutes(2), Duration.ofHours(24)),
                new SequenceRule(Duration.ofHours(20)),
                new MockLocationRule(),
                new AccuracyRule(50),
                new GeofenceRule()),
                new PunctualityPolicy(ZONE), new UnitOfWork() {
                    public <T> T inTransaction(java.util.function.Supplier<T> work) { return work.get(); }
                }, clock, Duration.ofMinutes(2));
    }

    MarkAttempt attempt(MarkType type, GeoPoint at, double accuracy, boolean mocked, Instant captured) {
        return new MarkAttempt(UUID.randomUUID(), WORKER, type, new LocationReading(at, accuracy, mocked), captured);
    }

    MarkAttempt inside(MarkType type) {
        return attempt(type, new GeoPoint(SITE.lat() + 0.0005, SITE.lon()), 12, false, now); // ~55 m
    }

    @Test
    void acceptsArrivalInsideTheRadius() {
        AttendanceMark m = service.register(inside(MarkType.IN)).mark();
        assertThat(m.status()).isEqualTo(MarkStatus.ON_TIME);
        assertThat(m.distanceMeters()).isBetween(50.0, 60.0);
        assertThat(m.recordedAt()).isEqualTo(now);
        assertThat(m.deferred()).isFalse();
    }

    @Test
    void rejectsOutsideTheRadiusAndKeepsTheAttempt() {
        AttendanceMark m = service.register(
                attempt(MarkType.IN, new GeoPoint(SITE.lat() + 0.002, SITE.lon()), 10, false, now)).mark(); // ~222 m
        assertThat(m.status()).isEqualTo(MarkStatus.REJECTED);
        assertThat(m.rejection()).isEqualTo(RejectionReason.OUT_OF_ZONE);
        assertThat(marks.stored).hasSize(1);
    }

    @Test
    void rejectsMockedAndImpreciseFixes() {
        assertThat(service.register(attempt(MarkType.IN, SITE, 5, true, now)).mark().rejection())
                .isEqualTo(RejectionReason.MOCK_LOCATION);
        assertThat(service.register(attempt(MarkType.IN, SITE, 80, false, now)).mark().rejection())
                .isEqualTo(RejectionReason.LOW_ACCURACY);
    }

    @Test
    void enforcesArrivalDepartureSequence() {
        assertThat(service.register(inside(MarkType.OUT)).mark().rejection()).isEqualTo(RejectionReason.NOT_IN);
        assertThat(service.register(inside(MarkType.IN)).mark().accepted()).isTrue();
        assertThat(service.register(inside(MarkType.IN)).mark().rejection()).isEqualTo(RejectionReason.ALREADY_IN);
        now = now.plus(Duration.ofHours(3));
        assertThat(service.register(inside(MarkType.OUT)).mark().status()).isEqualTo(MarkStatus.EARLY_LEAVE);
    }

    @Test
    void retryWithSameClientIdIsIdempotent() {
        MarkAttempt a = inside(MarkType.IN);
        RegisterMarkService.Result first = service.register(a);
        RegisterMarkService.Result again = service.register(a);
        assertThat(first.replay()).isFalse();
        assertThat(again.replay()).isTrue();
        assertThat(again.mark().id()).isEqualTo(first.mark().id());
        assertThat(marks.stored).hasSize(1);
    }

    @Test
    void offlineMarkUsesCaptureTimeAndIsFlagged() {
        Instant captured = now.minus(Duration.ofMinutes(30)); // 06:35, captured without signal
        AttendanceMark m = service.register(
                attempt(MarkType.IN, SITE, 10, false, captured)).mark();
        assertThat(m.deferred()).isTrue();
        assertThat(m.recordedAt()).isEqualTo(captured);
        assertThat(m.status()).isEqualTo(MarkStatus.ON_TIME);
    }

    @Test
    void rejectsDeviceClockAhead() {
        assertThat(service.register(attempt(MarkType.IN, SITE, 10, false, now.plus(Duration.ofMinutes(10))))
                .mark().rejection()).isEqualTo(RejectionReason.CLOCK_AHEAD);
    }

    static final class InMemoryMarks implements MarkRepository {

        final List<AttendanceMark> stored = new ArrayList<>();

        public Optional<AttendanceMark> findByClientId(UUID id) {
            return stored.stream().filter(m -> m.clientId().equals(id)).findFirst();
        }

        public Optional<AttendanceMark> lastAccepted(long employeeId) {
            return stored.stream().filter(m -> m.employeeId() == employeeId && m.accepted())
                    .max(Comparator.comparing(AttendanceMark::recordedAt));
        }

        public void lockEmployee(long employeeId) {
        }

        public Optional<AttendanceMark> insertIfAbsent(AttendanceMark m) {
            if (findByClientId(m.clientId()).isPresent()) {
                return Optional.empty();
            }
            AttendanceMark withId = m.withId(stored.size() + 1);
            stored.add(withId);
            return Optional.of(withId);
        }

        public List<AttendanceMark> findBetween(Instant from, Instant to, Long employeeId, Long worksiteId) {
            return stored.stream().filter(m -> !m.recordedAt().isBefore(from) && m.recordedAt().isBefore(to)).toList();
        }
    }
}
