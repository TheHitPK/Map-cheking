package com.transmcbo.ingest;

public final class Geo {

    private static final double EARTH_RADIUS_M = 6_371_000;
    private static final double E6 = 1e6;

    private Geo() {
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
