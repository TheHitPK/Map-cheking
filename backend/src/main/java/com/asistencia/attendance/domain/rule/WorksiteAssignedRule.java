package com.asistencia.attendance.domain.rule;

import com.asistencia.attendance.domain.MarkContext;
import com.asistencia.attendance.domain.RejectionReason;
import java.util.Optional;

public final class WorksiteAssignedRule implements MarkRule {

    @Override
    public Optional<RejectionReason> evaluate(MarkContext ctx) {
        return ctx.worksite().isEmpty() ? Optional.of(RejectionReason.NO_WORKSITE) : Optional.empty();
    }
}
