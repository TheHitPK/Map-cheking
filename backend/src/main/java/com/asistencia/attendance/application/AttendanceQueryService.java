package com.asistencia.attendance.application;

import com.asistencia.attendance.application.port.MarkRepository;
import com.asistencia.attendance.domain.AttendanceMark;
import com.asistencia.attendance.domain.MarkStatus;
import com.asistencia.attendance.domain.MarkType;
import com.asistencia.attendance.domain.rule.SequenceRule;
import com.asistencia.employee.application.port.EmployeeRepository;
import com.asistencia.employee.domain.Employee;
import com.asistencia.employee.domain.Role;
import com.asistencia.schedule.application.port.ShiftRepository;
import com.asistencia.schedule.domain.Shift;
import com.asistencia.shared.domain.InvalidInputException;
import com.asistencia.shared.domain.NotFoundException;
import com.asistencia.worksite.application.port.WorksiteRepository;
import com.asistencia.worksite.domain.Worksite;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Read side: the worker's day and the supervisor's reports. */
public class AttendanceQueryService {

    static final int MAX_REPORT_DAYS = 62;

    private final MarkRepository marks;
    private final EmployeeRepository employees;
    private final ShiftRepository shifts;
    private final WorksiteRepository worksites;
    private final SequenceRule sequence;
    private final Clock clock;
    private final ZoneId zone;

    public AttendanceQueryService(MarkRepository marks, EmployeeRepository employees, ShiftRepository shifts,
                                  WorksiteRepository worksites, SequenceRule sequence, Clock clock, ZoneId zone) {
        this.marks = marks;
        this.employees = employees;
        this.shifts = shifts;
        this.worksites = worksites;
        this.sequence = sequence;
        this.clock = clock;
        this.zone = zone;
    }

    /** @param next the mark the worker should make now */
    public record Today(Employee employee, Optional<Shift> shift, Optional<Worksite> worksite,
                        Optional<Shift.Occurrence> occurrence, List<AttendanceMark> marks, MarkType next) {
    }

    public Today today(long employeeId) {
        Employee employee = employees.findById(employeeId)
                .orElseThrow(() -> new NotFoundException("Empleado no encontrado."));
        Instant now = clock.instant();
        LocalDate date = now.atZone(zone).toLocalDate();
        Optional<Shift> shift = shifts.findByEmployee(employeeId);
        Optional<Worksite> worksite = shift.flatMap(s -> worksites.findById(s.worksiteId())).filter(Worksite::active);
        Instant dayStart = date.atStartOfDay(zone).toInstant();
        List<AttendanceMark> todays = marks.findBetween(dayStart, now.plusSeconds(1), employeeId, null);
        MarkType next = sequence.isOpen(marks.lastAccepted(employeeId), now) ? MarkType.OUT : MarkType.IN;
        return new Today(employee, shift, worksite, shift.flatMap(s -> s.occurrenceOn(date, zone)), todays, next);
    }

    public enum DayState {
        /** No shift that day. */
        OFF,
        /** Shift not started yet (or still within grace). */
        PENDING,
        ABSENT,
        ON_TIME,
        LATE
    }

    public record DailyRow(Employee employee, Shift shift, Worksite worksite, DayState state,
                           Optional<AttendanceMark> firstIn, Optional<AttendanceMark> lastOut, boolean earlyLeave,
                           boolean onSite, int rejectedAttempts) {
    }

    /** One row per worker with a shift (optionally at one worksite). */
    public List<DailyRow> daily(LocalDate date, Long worksiteId) {
        Instant now = clock.instant();
        Map<Long, Employee> workers = employees.findAll().stream()
                .filter(e -> e.role() == Role.WORKER && e.active())
                .collect(Collectors.toMap(Employee::id, Function.identity()));
        Map<Long, Worksite> sites = worksites.findAll().stream().collect(Collectors.toMap(Worksite::id, Function.identity()));
        Instant from = date.minusDays(1).atStartOfDay(zone).toInstant();
        Instant to = date.plusDays(2).atStartOfDay(zone).toInstant();
        Map<Long, List<AttendanceMark>> byEmployee = marks.findBetween(from, to, null, worksiteId).stream()
                .collect(Collectors.groupingBy(AttendanceMark::employeeId));

        return shifts.findAll().stream()
                .filter(s -> workers.containsKey(s.employeeId()))
                .filter(s -> worksiteId == null || s.worksiteId() == worksiteId)
                .map(s -> row(workers.get(s.employeeId()), s, sites.get(s.worksiteId()), date, now,
                        byEmployee.getOrDefault(s.employeeId(), List.of())))
                .sorted(Comparator.comparing((DailyRow r) -> r.employee().fullName()))
                .toList();
    }

    private DailyRow row(Employee employee, Shift shift, Worksite worksite, LocalDate date, Instant now,
                         List<AttendanceMark> candidates) {
        Optional<Shift.Occurrence> occurrence = shift.occurrenceOn(date, zone);
        Instant from = occurrence.map(o -> o.start().minus(Duration.ofHours(3))).orElse(date.atStartOfDay(zone).toInstant());
        Instant to = occurrence.map(o -> o.end().plus(Duration.ofHours(6))).orElse(date.plusDays(1).atStartOfDay(zone).toInstant());
        List<AttendanceMark> window = candidates.stream()
                .filter(m -> !m.recordedAt().isBefore(from) && m.recordedAt().isBefore(to))
                .toList();
        List<AttendanceMark> accepted = window.stream().filter(AttendanceMark::accepted).toList();
        Optional<AttendanceMark> firstIn = accepted.stream().filter(m -> m.type() == MarkType.IN).findFirst();
        Optional<AttendanceMark> lastOut = accepted.stream().filter(m -> m.type() == MarkType.OUT).reduce((a, b) -> b);
        boolean onSite = !accepted.isEmpty() && accepted.getLast().type() == MarkType.IN;

        DayState state;
        if (firstIn.isPresent()) {
            state = firstIn.get().status() == MarkStatus.LATE ? DayState.LATE : DayState.ON_TIME;
        } else if (occurrence.isEmpty()) {
            state = DayState.OFF;
        } else {
            state = now.isAfter(occurrence.get().start().plus(shift.grace())) ? DayState.ABSENT : DayState.PENDING;
        }
        boolean earlyLeave = lastOut.filter(m -> m.status() == MarkStatus.EARLY_LEAVE).isPresent();
        int rejected = (int) window.stream().filter(m -> !m.accepted()).count();
        return new DailyRow(employee, shift, worksite, state, firstIn, lastOut, earlyLeave, onSite, rejected);
    }

    public record MarkRow(AttendanceMark mark, String employeeName, String employeeDocument, String worksiteName) {
    }

    /** All marks (rejected included) between two local dates, inclusive. */
    public List<MarkRow> marks(LocalDate from, LocalDate to, Long worksiteId) {
        if (to.isBefore(from) || from.plusDays(MAX_REPORT_DAYS).isBefore(to)) {
            throw new InvalidInputException("Rango de fechas inválido (máximo " + MAX_REPORT_DAYS + " días).");
        }
        Map<Long, Employee> people = employees.findAll().stream().collect(Collectors.toMap(Employee::id, Function.identity()));
        Map<Long, Worksite> sites = worksites.findAll().stream().collect(Collectors.toMap(Worksite::id, Function.identity()));
        return marks.findBetween(from.atStartOfDay(zone).toInstant(), to.plusDays(1).atStartOfDay(zone).toInstant(),
                        null, worksiteId).stream()
                .map(m -> {
                    Employee e = people.get(m.employeeId());
                    Worksite w = m.worksiteId() == null ? null : sites.get(m.worksiteId());
                    return new MarkRow(m, e == null ? "" : e.fullName(), e == null ? "" : e.document(),
                            w == null ? "" : w.name());
                })
                .toList();
    }
}
