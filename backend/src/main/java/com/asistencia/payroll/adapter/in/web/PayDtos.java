package com.asistencia.payroll.adapter.in.web;

import com.asistencia.payroll.application.PayrollService.Line;
import com.asistencia.payroll.application.PayrollService.Payroll;
import com.asistencia.payroll.application.PayrollService.Stub;
import com.asistencia.payroll.application.port.PayrollRepository.PaidStub;
import com.asistencia.payroll.domain.Payment;
import com.asistencia.payroll.domain.Timesheet;
import com.asistencia.payroll.domain.WeeklyPay;
import java.time.LocalDate;
import java.util.List;

/** JSON shapes of the payroll API. Money in US cents, time in minutes; amounts are gross (before taxes). */
public final class PayDtos {

    private PayDtos() {
    }

    public record PayDto(int regularMinutes, int overtimeMinutes, Integer hourlyRateCents, Long grossCents) {

        static PayDto of(WeeklyPay p) {
            return new PayDto(p.regularMinutes(), p.overtimeMinutes(), p.hourlyRateCents(), p.grossCents());
        }
    }

    public record DayDto(LocalDate date, int minutes) {

        static List<DayDto> of(Timesheet t) {
            return t.minutesByDay().entrySet().stream().map(e -> new DayDto(e.getKey(), e.getValue())).toList();
        }
    }

    /**
     * @param payDate          the day it was paid, or the expected payday while unpaid
     * @param missingPunchOuts sessions left unpaid because the punch-out is missing
     * @param punchedIn        a session is still open (its time so far is included)
     */
    public record StubDto(LocalDate periodStart, LocalDate periodEnd, boolean paid, LocalDate payDate, PayDto pay,
                          List<DayDto> days, int missingPunchOuts, boolean punchedIn) {

        static StubDto of(Stub s) {
            return new StubDto(s.period().start(), s.period().end(), s.payment().isPresent(),
                    s.payment().map(Payment::paidOn).orElse(s.period().defaultPayDate()), PayDto.of(s.pay()),
                    DayDto.of(s.timesheet()), s.timesheet().missingOuts(), s.timesheet().inProgress());
        }
    }

    public record PaidDto(LocalDate periodStart, LocalDate periodEnd, LocalDate paidOn, PayDto pay) {

        static PaidDto of(PaidStub p) {
            return new PaidDto(p.payment().period().start(), p.payment().period().end(), p.payment().paidOn(),
                    PayDto.of(p.pay()));
        }
    }

    public record LineDto(long employeeId, String fullName, String document, boolean active, PayDto pay, List<DayDto> days,
                          int missingPunchOuts, boolean punchedIn) {

        static LineDto of(Line l) {
            return new LineDto(l.employee().id(), l.employee().fullName(), l.employee().document(), l.employee().active(),
                    PayDto.of(l.pay()), DayDto.of(l.timesheet()), l.timesheet().missingOuts(), l.timesheet().inProgress());
        }
    }

    /** @param payDate the day it was paid, or the expected payday while unpaid */
    public record PayrollDto(LocalDate periodStart, LocalDate periodEnd, boolean paid, LocalDate payDate,
                             long totalGrossCents, int totalMinutes, List<LineDto> lines) {

        static PayrollDto of(Payroll p) {
            return new PayrollDto(p.period().start(), p.period().end(), p.payment().isPresent(),
                    p.payment().map(Payment::paidOn).orElse(p.period().defaultPayDate()), p.totalGrossCents(),
                    p.totalMinutes(), p.lines().stream().map(LineDto::of).toList());
        }
    }

    public record MyPayDto(Integer hourlyRateCents, StubDto current, StubDto previous, List<PaidDto> history) {
    }
}
