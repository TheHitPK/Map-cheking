package com.transmcbo.ingest;

public final class Geo {

    private static final double EARTH_RADIUS_M = 6_371_000;
    private static final double E6 = 1e6;

    // Service area: Maracaibo + San Francisco, degrees * 1e6.
    public static final int MIN_LAT = 10_400_000, MAX_LAT = 10_950_000;
    public static final int MIN_LON = -72_000_000, MAX_LON = -71_400_000;

    private Geo() {
    }

    public static boolean inServiceArea(int lat, int lon) {
        return lat >= MIN_LAT && lat <= MAX_LAT && lon >= MIN_LON && lon <= MAX_LON;
    }

    /** Initial bearing from point 1 to point 2, degrees [0, 360). */
    public static double bearingDeg(int lat1, int lon1, int lat2, int lon2) {
        double p1 = Math.toRadians(lat1 / E6);
        double p2 = Math.toRadians(lat2 / E6);
        double dl = Math.toRadians((lon2 - lon1) / E6);
        double y = Math.sin(dl) * Math.cos(p2);
        double x = Math.cos(p1) * Math.sin(p2) - Math.sin(p1) * Math.cos(p2) * Math.cos(dl);
        return (Math.toDegrees(Math.atan2(y, x)) + 360) % 360;
    }

    /** Haversine distance between two points given in degrees * 1e6. */
    public static double distanceMeters(int lat1, int lon1, int lat2, int lon2) {
        double p1 = Math.toRadians(lat1 / E6);
        double p2 = Math.toRadians(lat2 / E6);
        double dp = p2 - p1;
        double dl = Math.toRadians((lon2 - lon1) / E6);
        double a = Math.sin(dp / 2) * Math.sin(dp / 2) + Math.cos(p1) * Math.cos(p2) * Math.sin(dl / 2) * Math.sin(dl / 2);
        return 2 * EARTH_RADIUS_M * Math.asin(Math.sqrt(a));
    }
}
