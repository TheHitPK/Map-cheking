package com.asistencia.payroll.application.port;

import com.asistencia.payroll.domain.PayPeriod;
import com.asistencia.payroll.domain.Payment;
import com.asistencia.payroll.domain.WeeklyPay;
import java.util.List;
import java.util.Map;
import java.util.Optional;

public interface PayrollRepository {

    record PaidStub(Payment payment, WeeklyPay pay) {
    }

    Optional<Payment> findPayment(PayPeriod period);

    /** Frozen lines of a paid period, by employee id. */
    Map<Long, WeeklyPay> paidLines(PayPeriod period);

    /** Stores the payment and its lines; false (nothing stored) if the period was already paid. */
    boolean savePayment(Payment payment, Map<Long, WeeklyPay> lines);

    /** The employee's paid periods, most recent first. */
    List<PaidStub> history(long employeeId, int limit);
}
