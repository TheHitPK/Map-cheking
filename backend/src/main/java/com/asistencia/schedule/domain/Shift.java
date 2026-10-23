package com.asistencia.schedule.domain;

import com.asistencia.shared.domain.InvalidInputException;
import java.time.DayOfWeek;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.EnumSet;
import java.util.Optional;
import java.util.Set;

/**
 * An employee's weekly schedule at one worksite. {@code end} before {@code start} means the shift ends the next day.
 * {@code days} are the days the shift starts on.
 *
 * @param id null until persisted
 */
public record Shift(Long id, long employeeId, long worksiteId, LocalTime start, LocalTime end, Set<DayOfWeek> days,
                    int graceMinutes) {

    /** How early before the start a check-in still belongs to that occurrence. */
    static final Duration EARLY_WINDOW = Duration.ofHours(3);
    /** How late after the end a check-out still belongs to that occurrence. */
    static final Duration LATE_WINDOW = Duration.ofHours(6);

    public Shift {
        if (start == null || end == null || start.equals(end)) {
            throw new InvalidInputException("Start and end times are required and must differ.");
        }
        if (days == null || days.isEmpty()) {
            throw new InvalidInputException("Select at least one day.");
        }
        if (graceMinutes < 0 || graceMinutes > 120) {
            throw new InvalidInputException("Grace period must be 0 to 120 minutes.");
        }
        days = Set.copyOf(EnumSet.copyOf(days));
    }

    public Duration grace() {
        return Duration.ofMinutes(graceMinutes);
    }

    public Optional<Occurrence> occurrenceOn(LocalDate date, ZoneId zone) {
        if (!days.contains(date.getDayOfWeek())) {
            return Optional.empty();
        }
        ZonedDateTime s = date.atTime(start).atZone(zone);
        ZonedDateTime e = (end.isAfter(start) ? date : date.plusDays(1)).atTime(end).atZone(zone);
        return Optional.of(new Occurrence(s.toInstant(), e.toInstant()));
    }

    /**
     * The occurrence a mark at {@code t} belongs to: the one whose window [start − 3 h, end + 6 h] contains it,
     * closest start first. Checks the day before too, for overnight shifts.
     */
    public Optional<Occurrence> occurrenceAround(Instant t, ZoneId zone) {
        LocalDate day = t.atZone(zone).toLocalDate();
        Occurrence best = null;
        for (LocalDate d : new LocalDate[] {day.minusDays(1), day, day.plusDays(1)}) {
            Optional<Occurrence> o = occurrenceOn(d, zone);
            if (o.isPresent() && o.get().window().contains(t)
                    && (best == null || distance(o.get().start(), t) < distance(best.start(), t))) {
                best = o.get();
            }
        }
        return Optional.ofNullable(best);
    }

    private static long distance(Instant a, Instant b) {
        return Math.abs(Duration.between(a, b).toSeconds());
    }

    public record Occurrence(Instant start, Instant end) {

        Window window() {
            return new Window(start.minus(EARLY_WINDOW), end.plus(LATE_WINDOW));
        }
    }

    record Window(Instant from, Instant to) {

        boolean contains(Instant t) {
            return !t.isBefore(from) && !t.isAfter(to);
        }
    }
}
