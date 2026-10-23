package com.asistencia.attendance.domain;

import com.asistencia.shared.domain.GeoPoint;
import com.asistencia.shared.domain.InvalidInputException;

/** One GPS fix as reported by the phone. */
public record LocationReading(GeoPoint point, double accuracyMeters, boolean mocked) {

    public LocationReading {
        if (point == null) {
            throw new InvalidInputException("Location is required.");
        }
        if (!(accuracyMeters >= 0)) {
            throw new InvalidInputException("Invalid GPS accuracy.");
        }
    }
}
