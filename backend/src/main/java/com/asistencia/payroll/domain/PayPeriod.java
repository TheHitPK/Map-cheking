package com.asistencia.payroll.domain;

import com.asistencia.shared.domain.InvalidInputException;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;

/**
 * A weekly pay period, Monday to Sunday (the FLSA workweek, so overtime is counted per period). Paid by default on the
 * Friday after it ends.
 */
public record PayPeriod(LocalDate start) {

    public static final DayOfWeek FIRST_DAY = DayOfWeek.MONDAY;
    /** Sunday → Friday. */
    public static final int PAYDAY_AFTER_DAYS = 5;

    public PayPeriod {
        if (start == null || start.getDayOfWeek() != FIRST_DAY) {
            throw new InvalidInputException("A pay period starts on a Monday.");
        }
    }

    public static PayPeriod containing(LocalDate date) {
        return new PayPeriod(date.with(TemporalAdjusters.previousOrSame(FIRST_DAY)));
    }

    /** Last day, inclusive. */
    public LocalDate end() {
        return start.plusDays(6);
    }

    public LocalDate defaultPayDate() {
        return end().plusDays(PAYDAY_AFTER_DAYS);
    }

    public boolean contains(LocalDate date) {
        return !date.isBefore(start) && !date.isAfter(end());
    }

    public PayPeriod previous() {
        return new PayPeriod(start.minusWeeks(1));
    }
}
