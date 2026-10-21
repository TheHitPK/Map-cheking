package com.asistencia.attendance.domain;

import java.time.Instant;
import java.util.UUID;

/**
 * A stored mark, accepted or rejected. Immutable once stored.
 *
 * @param id             null until persisted
 * @param worksiteId     null when the employee had no worksite
 * @param recordedAt     official time: server receive time, or the capture time for deferred (offline) marks
 * @param distanceMeters to the worksite centre; null without worksite
 * @param rejection      null unless {@code status} is REJECTED
 * @param deferred       sent well after capture (queued offline); {@code recordedAt} then relies on the device clock
 */
public record AttendanceMark(
        Long id,
        UUID clientId,
        long employeeId,
        Long worksiteId,
        MarkType type,
        Instant recordedAt,
        Instant capturedAt,
        Instant receivedAt,
        LocationReading location,
        Double distanceMeters,
        MarkStatus status,
        RejectionReason rejection,
        boolean deferred) {

    public boolean accepted() {
        return status.accepted();
    }

    public AttendanceMark withId(long newId) {
        return new AttendanceMark(newId, clientId, employeeId, worksiteId, type, recordedAt, capturedAt, receivedAt,
                location, distanceMeters, status, rejection, deferred);
    }
}
