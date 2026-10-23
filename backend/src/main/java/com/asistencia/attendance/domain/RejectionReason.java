package com.asistencia.attendance.domain;

/** Why a mark was rejected, with the message shown to the worker. */
public enum RejectionReason {
    NO_WORKSITE("You're not assigned to a job site yet. Ask your supervisor."),
    MOCK_LOCATION("A fake GPS location was detected. Turn off any location-spoofing apps."),
    LOW_ACCURACY("GPS signal is too weak. Move to an open area and try again."),
    CLOCK_AHEAD("Your phone's clock is off. Turn on automatic date & time."),
    TOO_OLD("This punch was saved offline too long ago to be accepted."),
    OUT_OF_ZONE("You're outside the job site area."),
    ALREADY_IN("You're already punched in. Punch out first."),
    NOT_IN("You haven't punched in yet. Punch in first.");

    private final String message;

    RejectionReason(String message) {
        this.message = message;
    }

    public String message() {
        return message;
    }
}
