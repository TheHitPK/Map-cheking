package com.asistencia.attendance.domain;

import com.asistencia.worksite.domain.Worksite;
import java.time.Instant;
import java.util.Optional;

/**
 * Everything a {@link MarkRule} may look at.
 *
 * @param worksite     empty when the employee has no assigned worksite
 * @param receivedAt   server time
 * @param lastAccepted the employee's latest accepted mark before this one
 */
public record MarkContext(MarkAttempt attempt, Optional<Worksite> worksite, Instant receivedAt,
                          Optional<AttendanceMark> lastAccepted) {

    public Optional<Double> distanceMeters() {
        return worksite.map(w -> w.distanceTo(attempt.location().point()));
    }
}
