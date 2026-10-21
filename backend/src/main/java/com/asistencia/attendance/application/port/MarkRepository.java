package com.asistencia.attendance.application.port;

import com.asistencia.attendance.domain.AttendanceMark;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MarkRepository {

    Optional<AttendanceMark> findByClientId(UUID clientId);

    Optional<AttendanceMark> lastAccepted(long employeeId);

    /** Serializes concurrent marks of one employee until the transaction ends. */
    void lockEmployee(long employeeId);

    /** Stores the mark with its new id; empty if its clientId already exists (a concurrent retry). */
    Optional<AttendanceMark> insertIfAbsent(AttendanceMark mark);

    /** Marks with {@code from <= recordedAt < to}, oldest first. Null filters are ignored. */
    List<AttendanceMark> findBetween(Instant from, Instant to, Long employeeId, Long worksiteId);
}
