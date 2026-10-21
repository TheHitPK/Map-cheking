package com.asistencia.attendance.adapter.in.web;

import com.asistencia.attendance.domain.AttendanceMark;
import com.asistencia.attendance.domain.MarkStatus;
import com.asistencia.attendance.domain.MarkType;
import com.asistencia.attendance.domain.RejectionReason;
import java.time.Instant;
import java.util.UUID;

/** @param message user-facing reason when rejected */
public record MarkDto(long id, UUID clientId, MarkType type, MarkStatus status, RejectionReason rejection,
                      String message, Instant recordedAt, Double distanceMeters, double accuracyMeters,
                      boolean deferred) {

    public static MarkDto of(AttendanceMark m) {
        return new MarkDto(m.id(), m.clientId(), m.type(), m.status(), m.rejection(),
                m.rejection() == null ? null : m.rejection().message(), m.recordedAt(),
                m.distanceMeters() == null ? null : (double) Math.round(m.distanceMeters()),
                m.location().accuracyMeters(), m.deferred());
    }
}
