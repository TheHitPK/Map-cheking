package com.asistencia.attendance.domain;

public enum MarkStatus {
    ON_TIME,
    LATE,
    EARLY_LEAVE,
    /** Accepted, but outside any scheduled occurrence (e.g. overtime on a day off). */
    UNSCHEDULED,
    /** Kept for auditing; see {@link RejectionReason}. */
    REJECTED;

    public boolean accepted() {
        return this != REJECTED;
    }
}
