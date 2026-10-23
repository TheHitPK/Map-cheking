package com.asistencia.payroll.domain;

import com.asistencia.attendance.domain.AttendanceMark;
import com.asistencia.attendance.domain.MarkType;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.SortedMap;
import java.util.TreeMap;

/** One worker's sessions in a pay period. A session belongs to the day (and period) of its punch-in. */
public record Timesheet(PayPeriod period, List<WorkSession> sessions, ZoneId zone) {

    /**
     * @param marks          the worker's marks around the period (rejected ones are ignored); include the day after the
     *                       period plus {@code forgottenAfter} so a late punch-out on the last day is found
     * @param forgottenAfter an arrival older than this without departure is a missing punch-out (same as SequenceRule)
     */
    public static Timesheet of(PayPeriod period, List<AttendanceMark> marks, Instant now, Duration forgottenAfter,
                               ZoneId zone) {
        List<AttendanceMark> accepted = marks.stream()
                .filter(AttendanceMark::accepted)
                .sorted(Comparator.comparing(AttendanceMark::recordedAt))
                .toList();
        List<WorkSession> sessions = new ArrayList<>();
        AttendanceMark open = null;
        for (AttendanceMark m : accepted) {
            if (m.type() == MarkType.IN) {
                if (open != null) {
                    sessions.add(WorkSession.missingOut(open.recordedAt()));
                }
                open = m;
            } else if (open != null) {
                sessions.add(WorkSession.complete(open.recordedAt(), m.recordedAt()));
                open = null;
            } // a departure whose arrival is before the window belongs to the previous period
        }
        if (open != null) {
            sessions.add(open.recordedAt().plus(forgottenAfter).isAfter(now)
                    ? WorkSession.inProgress(open.recordedAt(), now)
                    : WorkSession.missingOut(open.recordedAt()));
        }
        List<WorkSession> inPeriod = sessions.stream()
                .filter(s -> period.contains(s.in().atZone(zone).toLocalDate()))
                .toList();
        return new Timesheet(period, inPeriod, zone);
    }

    public int workedMinutes() {
        return sessions.stream().mapToInt(WorkSession::minutes).sum();
    }

    /** Days with time (or a missing punch-out), in order. */
    public SortedMap<LocalDate, Integer> minutesByDay() {
        SortedMap<LocalDate, Integer> days = new TreeMap<>();
        for (WorkSession s : sessions) {
            days.merge(s.in().atZone(zone).toLocalDate(), s.minutes(), Integer::sum);
        }
        return days;
    }

    public int missingOuts() {
        return (int) sessions.stream().filter(s -> s.state() == WorkSession.State.MISSING_OUT).count();
    }

    public boolean inProgress() {
        return sessions.stream().anyMatch(s -> s.state() == WorkSession.State.IN_PROGRESS);
    }
}
