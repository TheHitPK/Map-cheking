package com.asistencia.shared.domain;

/** WGS84 point in degrees. */
public record GeoPoint(double lat, double lon) {

    private static final double EARTH_RADIUS_M = 6_371_008.8;

    public GeoPoint {
        if (!(lat >= -90 && lat <= 90) || !(lon >= -180 && lon <= 180)) {
            throw new InvalidInputException("Coordenadas fuera de rango: " + lat + ", " + lon);
        }
    }

    /** Great-circle distance in metres (haversine; error well under 0.5 % at worksite scale). */
    public double distanceTo(GeoPoint other) {
        double dLat = Math.toRadians(other.lat - lat);
        double dLon = Math.toRadians(other.lon - lon);
        double a = Math.pow(Math.sin(dLat / 2), 2)
                + Math.cos(Math.toRadians(lat)) * Math.cos(Math.toRadians(other.lat)) * Math.pow(Math.sin(dLon / 2), 2);
        return 2 * EARTH_RADIUS_M * Math.asin(Math.min(1, Math.sqrt(a)));
    }
}
