package com.asistencia.payroll.domain;

import java.time.Instant;
import java.time.LocalDate;

/** A supervisor marked a pay period as paid. */
public record Payment(PayPeriod period, LocalDate paidOn, long paidBy, Instant recordedAt) {
}
