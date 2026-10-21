package com.asistencia.attendance.domain.rule;

import com.asistencia.attendance.domain.MarkContext;
import com.asistencia.attendance.domain.RejectionReason;
import java.util.Optional;

public final class GeofenceRule implements MarkRule {

    @Override
    public Optional<RejectionReason> evaluate(MarkContext ctx) {
        return ctx.worksite()
                .filter(w -> !w.contains(ctx.distanceMeters().orElseThrow()))
                .map(w -> RejectionReason.OUT_OF_ZONE);
    }
}
