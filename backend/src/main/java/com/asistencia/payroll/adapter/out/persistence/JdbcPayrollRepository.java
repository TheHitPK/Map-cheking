package com.asistencia.payroll.adapter.out.persistence;

import com.asistencia.payroll.application.port.PayrollRepository;
import com.asistencia.payroll.domain.PayPeriod;
import com.asistencia.payroll.domain.Payment;
import com.asistencia.payroll.domain.WeeklyPay;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class JdbcPayrollRepository implements PayrollRepository {

    private static final String PAYMENT = "start_date, paid_on, paid_by, recorded_at";
    private static final String LINE = "hourly_rate_cents, regular_minutes, overtime_minutes, gross_cents";

    private final JdbcClient jdbc;

    public JdbcPayrollRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<Payment> findPayment(PayPeriod period) {
        return jdbc.sql("SELECT " + PAYMENT + " FROM pay_period WHERE start_date = ?")
                .param(period.start()).query(this::payment).optional();
    }

    @Override
    public Map<Long, WeeklyPay> paidLines(PayPeriod period) {
        Map<Long, WeeklyPay> lines = new HashMap<>();
        jdbc.sql("SELECT employee_id, " + LINE + " FROM payroll_line WHERE period_start = ?")
                .param(period.start())
                .query(rs -> {
                    lines.put(rs.getLong("employee_id"), line(rs));
                });
        return lines;
    }

    @Override
    public boolean savePayment(Payment p, Map<Long, WeeklyPay> lines) {
        Optional<LocalDate> inserted = jdbc.sql("""
                        INSERT INTO pay_period (start_date, end_date, paid_on, paid_by, recorded_at)
                        VALUES (?, ?, ?, ?, ?)
                        ON CONFLICT (start_date) DO NOTHING RETURNING start_date""")
                .params(p.period().start(), p.period().end(), p.paidOn(), p.paidBy(),
                        p.recordedAt().atOffset(ZoneOffset.UTC))
                .query(LocalDate.class).optional();
        if (inserted.isEmpty()) {
            return false;
        }
        lines.forEach((employeeId, pay) -> jdbc.sql("""
                        INSERT INTO payroll_line (period_start, employee_id, hourly_rate_cents, regular_minutes,
                            overtime_minutes, gross_cents)
                        VALUES (?, ?, ?, ?, ?, ?)""")
                .params(p.period().start(), employeeId, pay.hourlyRateCents(), pay.regularMinutes(),
                        pay.overtimeMinutes(), pay.grossCents())
                .update());
        return true;
    }

    @Override
    public List<PaidStub> history(long employeeId, int limit) {
        return jdbc.sql("SELECT p.start_date, p.paid_on, p.paid_by, p.recorded_at, " + LINE + """
                         FROM payroll_line l JOIN pay_period p ON p.start_date = l.period_start
                        WHERE l.employee_id = ?
                        ORDER BY p.start_date DESC LIMIT ?""")
                .params(employeeId, limit)
                .query((rs, row) -> new PaidStub(payment(rs, row), line(rs)))
                .list();
    }

    private Payment payment(ResultSet rs, int row) throws SQLException {
        return new Payment(new PayPeriod(rs.getObject("start_date", LocalDate.class)),
                rs.getObject("paid_on", LocalDate.class), rs.getLong("paid_by"),
                rs.getTimestamp("recorded_at").toInstant());
    }

    private static WeeklyPay line(ResultSet rs) throws SQLException {
        return new WeeklyPay(rs.getInt("regular_minutes"), rs.getInt("overtime_minutes"), rs.getInt("hourly_rate_cents"),
                rs.getLong("gross_cents"));
    }
}
