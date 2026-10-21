package com.asistencia.worksite.domain;

import com.asistencia.shared.domain.GeoPoint;
import com.asistencia.shared.domain.InvalidInputException;

/**
 * A worksite: a centre and a radius. A reading is on site when its distance to the centre is within the radius.
 *
 * @param id null until persisted
 */
public record Worksite(Long id, String name, String address, GeoPoint center, int radiusMeters, boolean active) {

    public static final int MIN_RADIUS_M = 20;
    public static final int MAX_RADIUS_M = 2_000;

    public Worksite {
        name = name == null ? "" : name.trim();
        address = address == null ? "" : address.trim();
        if (name.length() < 2 || name.length() > 120) {
            throw new InvalidInputException("El nombre de la obra debe tener entre 2 y 120 caracteres.");
        }
        if (center == null) {
            throw new InvalidInputException("Ubicación de la obra requerida.");
        }
        if (radiusMeters < MIN_RADIUS_M || radiusMeters > MAX_RADIUS_M) {
            throw new InvalidInputException("El radio debe estar entre " + MIN_RADIUS_M + " y " + MAX_RADIUS_M + " m.");
        }
    }

    public double distanceTo(GeoPoint point) {
        return center.distanceTo(point);
    }

    public boolean contains(double distanceMeters) {
        return distanceMeters <= radiusMeters;
    }

    public Worksite withId(long newId) {
        return new Worksite(newId, name, address, center, radiusMeters, active);
    }
}
