package com.asistencia.payroll.domain;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class WeeklyPayTest {

    @Test
    void fortyHoursOrLessIsAllRegular() {
        WeeklyPay p = WeeklyPay.of(40 * 60, 2550); // $25.50/h
        assertThat(p.regularMinutes()).isEqualTo(2400);
        assertThat(p.overtimeMinutes()).isZero();
        assertThat(p.grossCents()).isEqualTo(102_000); // $1,020.00
    }

    @Test
    void hoursOverFortyPayTimeAndAHalf() {
        WeeklyPay p = WeeklyPay.of(45 * 60 + 30, 2000); // 45.5 h at $20
        assertThat(p.regularMinutes()).isEqualTo(2400);
        assertThat(p.overtimeMinutes()).isEqualTo(330);
        assertThat(p.grossCents()).isEqualTo(80_000 + 16_500); // 40 × 20 + 5.5 × 30
    }

    @Test
    void centsRoundHalfUp() {
        assertThat(WeeklyPay.of(1, 1725).grossCents()).isEqualTo(29); // 28.75 ¢
        assertThat(WeeklyPay.of(1, 1730).grossCents()).isEqualTo(29); // 28.83 ¢
        assertThat(WeeklyPay.of(1, 1710).grossCents()).isEqualTo(29); // 28.50 ¢
        assertThat(WeeklyPay.of(1, 1709).grossCents()).isEqualTo(28); // 28.48 ¢
    }

    @Test
    void noRateMeansNoAmount() {
        WeeklyPay p = WeeklyPay.of(600, null);
        assertThat(p.grossCents()).isNull();
        assertThat(p.totalMinutes()).isEqualTo(600);
    }
}
