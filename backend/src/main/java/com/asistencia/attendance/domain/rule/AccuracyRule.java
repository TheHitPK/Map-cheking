package com.asistencia.attendance.domain.rule;

import com.asistencia.attendance.domain.MarkContext;
import com.asistencia.attendance.domain.RejectionReason;
import java.util.Optional;

/** A fix with a large error circle cannot prove the worker is inside a small radius. */
public final class AccuracyRule implements MarkRule {

    private final double maxAccuracyMeters;

    public AccuracyRule(double maxAccuracyMeters) {
        this.maxAccuracyMeters = maxAccuracyMeters;
    }

    @Override
    public Optional<RejectionReason> evaluate(MarkContext ctx) {
        return ctx.attempt().location().accuracyMeters() > maxAccuracyMeters
                ? Optional.of(RejectionReason.LOW_ACCURACY)
                : Optional.empty();
    }
}
