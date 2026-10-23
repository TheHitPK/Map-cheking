package com.asistencia.payroll.domain;

import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

/**
 * One punch-in and what followed it.
 *
 * @param out     null unless COMPLETE
 * @param minutes paid minutes: whole minutes between the punches (to now while in progress); 0 for a missing punch-out
 */
public record WorkSession(Instant in, Instant out, State state, int minutes) {

    public enum State {
        COMPLETE,
        /** Still punched in. Counted up to now for estimates; a period cannot be paid while one is open. */
        IN_PROGRESS,
        /** Forgot to punch out (a later punch-in, or too long ago). Not paid until fixed. */
        MISSING_OUT
    }

    public static WorkSession complete(Instant in, Instant out) {
        return new WorkSession(in, out, State.COMPLETE, minutesBetween(in, out));
    }

    public static WorkSession inProgress(Instant in, Instant now) {
        return new WorkSession(in, null, State.IN_PROGRESS, minutesBetween(in, now));
    }

    public static WorkSession missingOut(Instant in) {
        return new WorkSession(in, null, State.MISSING_OUT, 0);
    }

    /** Clock minutes, as a time card shows them: 7:58 → 4:31 is 273 min whatever the seconds. */
    private static int minutesBetween(Instant from, Instant to) {
        long m = Duration.between(from.truncatedTo(ChronoUnit.MINUTES), to.truncatedTo(ChronoUnit.MINUTES)).toMinutes();
        return (int) Math.max(0, m);
    }
}
