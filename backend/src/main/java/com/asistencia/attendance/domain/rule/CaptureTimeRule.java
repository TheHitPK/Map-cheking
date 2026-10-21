package com.asistencia.attendance.domain.rule;

import com.asistencia.attendance.domain.MarkContext;
import com.asistencia.attendance.domain.RejectionReason;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

/** Rejects capture times in the future (device clock ahead) or queued offline for too long. */
public final class CaptureTimeRule implements MarkRule {

    private final Duration maxClockAhead;
    private final Duration maxDeferral;

    public CaptureTimeRule(Duration maxClockAhead, Duration maxDeferral) {
        this.maxClockAhead = maxClockAhead;
        this.maxDeferral = maxDeferral;
    }

    @Override
    public Optional<RejectionReason> evaluate(MarkContext ctx) {
        Instant captured = ctx.attempt().capturedAt();
        if (captured.isAfter(ctx.receivedAt().plus(maxClockAhead))) {
            return Optional.of(RejectionReason.CLOCK_AHEAD);
        }
        if (captured.isBefore(ctx.receivedAt().minus(maxDeferral))) {
            return Optional.of(RejectionReason.TOO_OLD);
        }
        return Optional.empty();
    }
}
