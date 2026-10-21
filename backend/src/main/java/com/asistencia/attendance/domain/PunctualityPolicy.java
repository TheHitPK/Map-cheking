package com.asistencia.attendance.domain;

import com.asistencia.schedule.domain.Shift;
import java.time.Instant;
import java.time.ZoneId;
import java.util.Optional;

/**
 * Classifies an accepted mark against the employee's shift. The grace period applies to both ends:
 * an arrival up to {@code start + grace} is on time, a departure from {@code end − grace} is on time.
 */
public final class PunctualityPolicy {

    private final ZoneId zone;

    public PunctualityPolicy(ZoneId zone) {
        this.zone = zone;
    }

    public MarkStatus classify(MarkType type, Instant at, Optional<Shift> shift) {
        Optional<Shift.Occurrence> occurrence = shift.flatMap(s -> s.occurrenceAround(at, zone));
        if (occurrence.isEmpty()) {
            return MarkStatus.UNSCHEDULED;
        }
        Shift.Occurrence o = occurrence.get();
        return switch (type) {
            case IN -> at.isAfter(o.start().plus(shift.get().grace())) ? MarkStatus.LATE : MarkStatus.ON_TIME;
            case OUT -> at.isBefore(o.end().minus(shift.get().grace())) ? MarkStatus.EARLY_LEAVE : MarkStatus.ON_TIME;
        };
    }
}
