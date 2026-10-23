package com.asistencia.payroll.adapter.in.web;

import com.asistencia.payroll.adapter.in.web.PayDtos.MyPayDto;
import com.asistencia.payroll.adapter.in.web.PayDtos.PaidDto;
import com.asistencia.payroll.adapter.in.web.PayDtos.PayrollDto;
import com.asistencia.payroll.adapter.in.web.PayDtos.StubDto;
import com.asistencia.payroll.application.PayrollService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Supervisor: {@code /payroll}. Worker: {@code /me/pay} (its id always comes from the token). */
@RestController
public class PayrollController {

    public record PayRequest(@NotNull LocalDate paidOn) {
    }

    private final PayrollService payroll;

    public PayrollController(PayrollService payroll) {
        this.payroll = payroll;
    }

    /** The weekly period containing {@code date}. */
    @GetMapping("/payroll")
    PayrollDto week(@RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return PayrollDto.of(payroll.payroll(date));
    }

    @PostMapping("/payroll/{periodStart}/pay")
    PayrollDto markPaid(@AuthenticationPrincipal Jwt jwt,
                        @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate periodStart,
                        @Valid @RequestBody PayRequest req) {
        return PayrollDto.of(payroll.markPaid(periodStart, req.paidOn(), Long.parseLong(jwt.getSubject())));
    }

    @GetMapping("/me/pay")
    MyPayDto myPay(@AuthenticationPrincipal Jwt jwt) {
        PayrollService.MyPay p = payroll.myPay(Long.parseLong(jwt.getSubject()));
        return new MyPayDto(p.employee().hourlyRateCents(), StubDto.of(p.current()), StubDto.of(p.previous()),
                p.history().stream().map(PaidDto::of).toList());
    }
}
