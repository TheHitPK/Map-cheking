package com.asistencia.payroll.application;

import com.asistencia.attendance.application.port.MarkRepository;
import com.asistencia.attendance.domain.AttendanceMark;
import com.asistencia.employee.application.port.EmployeeRepository;
import com.asistencia.employee.domain.Employee;
import com.asistencia.employee.domain.Role;
import com.asistencia.payroll.application.port.PayrollRepository;
import com.asistencia.payroll.application.port.PayrollRepository.PaidStub;
import com.asistencia.payroll.domain.PayPeriod;
import com.asistencia.payroll.domain.Payment;
import com.asistencia.payroll.domain.Timesheet;
import com.asistencia.payroll.domain.WeeklyPay;
import com.asistencia.shared.application.UnitOfWork;
import com.asistencia.shared.domain.ConflictException;
import com.asistencia.shared.domain.InvalidInputException;
import com.asistencia.shared.domain.NotFoundException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

/** Weekly gross pay from accepted punches: the supervisor's payroll and the worker's own pay. */
public class PayrollService {

    static final int HISTORY_SIZE = 12;
    private static final DateTimeFormatter DAY = DateTimeFormatter.ofPattern("EEE, MMM d", Locale.US);

    private final MarkRepository marks;
    private final EmployeeRepository employees;
    private final PayrollRepository payroll;
    private final UnitOfWork uow;
    private final Clock clock;
    private final ZoneId zone;
    private final Duration forgottenAfter;

    public PayrollService(MarkRepository marks, EmployeeRepository employees, PayrollRepository payroll, UnitOfWork uow,
                          Clock clock, ZoneId zone, Duration forgottenAfter) {
        this.marks = marks;
        this.employees = employees;
        this.payroll = payroll;
        this.uow = uow;
        this.clock = clock;
        this.zone = zone;
        this.forgottenAfter = forgottenAfter;
    }

    /** {@code pay} is the frozen amount once paid, the live estimate before. */
    public record Line(Employee employee, Timesheet timesheet, WeeklyPay pay) {
    }

    public record Payroll(PayPeriod period, Optional<Payment> payment, List<Line> lines) {

        public long totalGrossCents() {
            return lines.stream().map(l -> l.pay().grossCents()).filter(Objects::nonNull).mapToLong(Long::longValue).sum();
        }

        public int totalMinutes() {
            return lines.stream().mapToInt(l -> l.pay().totalMinutes()).sum();
        }
    }

    /** The week containing {@code date}: every active worker, plus anyone else who worked or was paid in it. */
    public Payroll payroll(LocalDate date) {
        return payroll(PayPeriod.containing(date));
    }

    private Payroll payroll(PayPeriod period) {
        Instant now = clock.instant();
        Map<Long, List<AttendanceMark>> byEmployee = marks.findBetween(from(period), to(period), null, null).stream()
                .collect(Collectors.groupingBy(AttendanceMark::employeeId));
        Optional<Payment> payment = payroll.findPayment(period);
        Map<Long, WeeklyPay> paid = payment.isPresent() ? payroll.paidLines(period) : Map.of();
        List<Line> lines = employees.findAll().stream()
                .filter(e -> e.role() == Role.WORKER)
                .map(e -> {
                    Timesheet t = Timesheet.of(period, byEmployee.getOrDefault(e.id(), List.of()), now, forgottenAfter, zone);
                    WeeklyPay pay = payment.isPresent()
                            ? paid.getOrDefault(e.id(), WeeklyPay.of(0, e.hourlyRateCents()))
                            : WeeklyPay.of(t.workedMinutes(), e.hourlyRateCents());
                    return new Line(e, t, pay);
                })
                .filter(l -> payment.isPresent()
                        ? paid.containsKey(l.employee().id()) || !l.timesheet().sessions().isEmpty()
                        : l.employee().active() || !l.timesheet().sessions().isEmpty())
                .toList();
        return new Payroll(period, payment, lines);
    }

    /** Freezes each worker's pay for the period. Only after the period ends, with every punch-out in and every rate set. */
    public Payroll markPaid(LocalDate periodStart, LocalDate paidOn, long supervisorId) {
        PayPeriod period = new PayPeriod(periodStart);
        LocalDate today = clock.instant().atZone(zone).toLocalDate();
        if (!today.isAfter(period.end())) {
            throw new InvalidInputException("This pay period isn't over yet. It ends " + DAY.format(period.end()) + ".");
        }
        if (paidOn == null || !paidOn.isAfter(period.end()) || paidOn.isAfter(today)) {
            throw new InvalidInputException("Pay date must be after " + DAY.format(period.end()) + " and not in the future.");
        }
        Payroll sheet = payroll(period);
        if (sheet.payment().isPresent()) {
            throw new ConflictException("This pay period is already marked as paid.");
        }
        for (Line l : sheet.lines()) {
            if (l.timesheet().inProgress()) {
                throw new InvalidInputException(l.employee().fullName() + " is still punched in from this period.");
            }
            if (l.pay().totalMinutes() > 0 && l.pay().hourlyRateCents() == null) {
                throw new InvalidInputException("Set an hourly rate for " + l.employee().fullName() + " first.");
            }
        }
        Map<Long, WeeklyPay> lines = sheet.lines().stream()
                .filter(l -> l.pay().totalMinutes() > 0)
                .collect(Collectors.toMap(l -> l.employee().id(), Line::pay));
        Payment payment = new Payment(period, paidOn, supervisorId, clock.instant());
        if (!uow.inTransaction(() -> payroll.savePayment(payment, lines))) {
            throw new ConflictException("This pay period is already marked as paid.");
        }
        return payroll(period);
    }

    public record Stub(PayPeriod period, Optional<Payment> payment, Timesheet timesheet, WeeklyPay pay) {
    }

    /** @param previous last week: usually the check coming this Friday */
    public record MyPay(Employee employee, Stub current, Stub previous, List<PaidStub> history) {
    }

    public MyPay myPay(long employeeId) {
        Employee e = employees.findById(employeeId).orElseThrow(() -> new NotFoundException("Employee not found."));
        Instant now = clock.instant();
        PayPeriod current = PayPeriod.containing(now.atZone(zone).toLocalDate());
        List<AttendanceMark> recent = marks.findBetween(from(current.previous()), to(current), employeeId, null);
        return new MyPay(e, stub(e, current, recent, now), stub(e, current.previous(), recent, now),
                payroll.history(employeeId, HISTORY_SIZE));
    }

    private Stub stub(Employee e, PayPeriod period, List<AttendanceMark> recent, Instant now) {
        Timesheet t = Timesheet.of(period, recent, now, forgottenAfter, zone);
        Optional<Payment> payment = payroll.findPayment(period);
        WeeklyPay pay = payment.isPresent()
                ? payroll.paidLines(period).getOrDefault(e.id(), WeeklyPay.of(0, e.hourlyRateCents()))
                : WeeklyPay.of(t.workedMinutes(), e.hourlyRateCents());
        return new Stub(period, payment, t, pay);
    }

    private Instant from(PayPeriod period) {
        return period.start().atStartOfDay(zone).toInstant();
    }

    /** Past the last day by {@code forgottenAfter}, to catch the punch-out of a shift started that night. */
    private Instant to(PayPeriod period) {
        return period.end().plusDays(1).atStartOfDay(zone).toInstant().plus(forgottenAfter);
    }
}
