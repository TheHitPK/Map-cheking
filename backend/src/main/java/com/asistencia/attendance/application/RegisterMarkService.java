package com.asistencia.attendance.application;

import com.asistencia.attendance.application.port.MarkRepository;
import com.asistencia.attendance.domain.AttendanceMark;
import com.asistencia.attendance.domain.MarkAttempt;
import com.asistencia.attendance.domain.MarkContext;
import com.asistencia.attendance.domain.MarkStatus;
import com.asistencia.attendance.domain.PunctualityPolicy;
import com.asistencia.attendance.domain.RejectionReason;
import com.asistencia.attendance.domain.rule.MarkRule;
import com.asistencia.schedule.application.port.ShiftRepository;
import com.asistencia.schedule.domain.Shift;
import com.asistencia.shared.application.UnitOfWork;
import com.asistencia.shared.domain.ConflictException;
import com.asistencia.worksite.application.port.WorksiteRepository;
import com.asistencia.worksite.domain.Worksite;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

/** Validates a mark against the rules, classifies it and stores it (rejected attempts too, for auditing). */
public class RegisterMarkService {

    private final MarkRepository marks;
    private final ShiftRepository shifts;
    private final WorksiteRepository worksites;
    private final List<MarkRule> rules;
    private final PunctualityPolicy punctuality;
    private final UnitOfWork uow;
    private final Clock clock;
    private final Duration deferredAfter;

    public RegisterMarkService(MarkRepository marks, ShiftRepository shifts, WorksiteRepository worksites,
                               List<MarkRule> rules, PunctualityPolicy punctuality, UnitOfWork uow, Clock clock,
                               Duration deferredAfter) {
        this.marks = marks;
        this.shifts = shifts;
        this.worksites = worksites;
        this.rules = List.copyOf(rules);
        this.punctuality = punctuality;
        this.uow = uow;
        this.clock = clock;
        this.deferredAfter = deferredAfter;
    }

    /** @param replay true if this clientId was already stored (a retry); the stored mark is returned unchanged */
    public record Result(AttendanceMark mark, boolean replay) {
    }

    public Result register(MarkAttempt attempt) {
        return uow.inTransaction(() -> {
            Optional<AttendanceMark> existing = marks.findByClientId(attempt.clientId());
            if (existing.isPresent()) {
                return replay(existing.get(), attempt);
            }
            marks.lockEmployee(attempt.employeeId());
            Instant now = clock.instant();
            Optional<Shift> shift = shifts.findByEmployee(attempt.employeeId());
            Optional<Worksite> worksite = shift.flatMap(s -> worksites.findById(s.worksiteId())).filter(Worksite::active);
            MarkContext ctx = new MarkContext(attempt, worksite, now, marks.lastAccepted(attempt.employeeId()));

            boolean deferred = attempt.capturedAt().isBefore(now.minus(deferredAfter));
            Instant recordedAt = deferred ? attempt.capturedAt() : now;
            Optional<RejectionReason> rejection = rules.stream()
                    .map(r -> r.evaluate(ctx))
                    .flatMap(Optional::stream)
                    .findFirst();
            MarkStatus status = rejection.isPresent()
                    ? MarkStatus.REJECTED
                    : punctuality.classify(attempt.type(), recordedAt, shift);

            AttendanceMark mark = new AttendanceMark(null, attempt.clientId(), attempt.employeeId(),
                    worksite.map(Worksite::id).orElse(null), attempt.type(), recordedAt, attempt.capturedAt(), now,
                    attempt.location(), ctx.distanceMeters().orElse(null), status, rejection.orElse(null), deferred);
            return marks.insertIfAbsent(mark)
                    .map(stored -> new Result(stored, false))
                    .orElseGet(() -> replay(marks.findByClientId(attempt.clientId()).orElseThrow(), attempt));
        });
    }

    private static Result replay(AttendanceMark stored, MarkAttempt attempt) {
        if (stored.employeeId() != attempt.employeeId()) {
            throw new ConflictException("Identificador de marca repetido.");
        }
        return new Result(stored, true);
    }
}
