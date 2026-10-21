package com.asistencia.attendance.domain.rule;

import com.asistencia.attendance.domain.AttendanceMark;
import com.asistencia.attendance.domain.MarkContext;
import com.asistencia.attendance.domain.MarkType;
import com.asistencia.attendance.domain.RejectionReason;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

/**
 * Arrivals and departures alternate. An arrival older than {@code forgottenAfter} counts as a forgotten departure,
 * so the worker is not locked out the next day.
 */
public final class SequenceRule implements MarkRule {

    private final Duration forgottenAfter;

    public SequenceRule(Duration forgottenAfter) {
        this.forgottenAfter = forgottenAfter;
    }

    @Override
    public Optional<RejectionReason> evaluate(MarkContext ctx) {
        boolean open = isOpen(ctx.lastAccepted(), ctx.attempt().capturedAt());
        return switch (ctx.attempt().type()) {
            case IN -> open ? Optional.of(RejectionReason.ALREADY_IN) : Optional.empty();
            case OUT -> open ? Optional.empty() : Optional.of(RejectionReason.NOT_IN);
        };
    }

    /** True if the worker is checked in at {@code at}, i.e. the next valid mark is a departure. */
    public boolean isOpen(Optional<AttendanceMark> lastAccepted, Instant at) {
        return lastAccepted
                .filter(m -> m.type() == MarkType.IN)
                .filter(m -> m.recordedAt().plus(forgottenAfter).isAfter(at))
                .isPresent();
    }
}
