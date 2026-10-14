package com.transmcbo.routing;

public final class Geohash {

    private static final char[] BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz".toCharArray();

    private Geohash() {
    }

    /** Standard geohash; precision 7 is a ~153 m x 153 m cell. */
    public static String encode(double lat, double lon, int precision) {
        double minLat = -90, maxLat = 90, minLon = -180, maxLon = 180;
        StringBuilder sb = new StringBuilder(precision);
        boolean evenBit = true;
        int bit = 0, ch = 0;
        while (sb.length() < precision) {
            if (evenBit) {
                double mid = (minLon + maxLon) / 2;
                if (lon >= mid) {
                    ch = (ch << 1) | 1;
                    minLon = mid;
                } else {
                    ch <<= 1;
                    maxLon = mid;
                }
            } else {
                double mid = (minLat + maxLat) / 2;
                if (lat >= mid) {
                    ch = (ch << 1) | 1;
                    minLat = mid;
                } else {
                    ch <<= 1;
                    maxLat = mid;
                }
            }
            evenBit = !evenBit;
            if (++bit == 5) {
                sb.append(BASE32[ch]);
                bit = 0;
                ch = 0;
            }
        }
        return sb.toString();
    }
}
