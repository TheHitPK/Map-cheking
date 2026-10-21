package com.asistencia.attendance.domain.rule;

import com.asistencia.attendance.domain.MarkContext;
import com.asistencia.attendance.domain.RejectionReason;
import java.util.Optional;

/** One acceptance check for a mark. Rules run in order; the first rejection wins. */
@FunctionalInterface
public interface MarkRule {

    Optional<RejectionReason> evaluate(MarkContext ctx);
}
