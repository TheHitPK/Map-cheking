package com.asistencia.payroll.domain;

/**
 * Gross pay for one workweek: hours over 40 at time and a half (FLSA). Before taxes and deductions.
 *
 * @param hourlyRateCents null when the worker has no rate yet
 * @param grossCents      null when the rate is unknown
 */
public record WeeklyPay(int regularMinutes, int overtimeMinutes, Integer hourlyRateCents, Long grossCents) {

    public static final int OVERTIME_AFTER_MINUTES = 40 * 60;

    public static WeeklyPay of(int workedMinutes, Integer hourlyRateCents) {
        int regular = Math.min(workedMinutes, OVERTIME_AFTER_MINUTES);
        int overtime = workedMinutes - regular;
        return new WeeklyPay(regular, overtime, hourlyRateCents, gross(regular, overtime, hourlyRateCents));
    }

    /** rate × (regular + 1.5 × overtime) / 60, in exact integer cents rounded half up. */
    static Long gross(int regularMinutes, int overtimeMinutes, Integer rateCents) {
        if (rateCents == null) {
            return null;
        }
        long halfMinutes = 2L * regularMinutes + 3L * overtimeMinutes;
        return (rateCents * halfMinutes + 60) / 120;
    }

    public int totalMinutes() {
        return regularMinutes + overtimeMinutes;
    }
}
