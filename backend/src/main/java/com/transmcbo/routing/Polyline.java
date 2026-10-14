package com.transmcbo.routing;

/** Google encoded polyline, precision 1e5. */
public final class Polyline {

    private Polyline() {
    }

    /** @param latLon alternating lat, lon in degrees */
    public static String encode(double[] latLon) {
        StringBuilder sb = new StringBuilder(latLon.length * 3);
        long prevLat = 0, prevLon = 0;
        for (int i = 0; i + 1 < latLon.length; i += 2) {
            long lat = Math.round(latLon[i] * 1e5);
            long lon = Math.round(latLon[i + 1] * 1e5);
            encodeValue(sb, lat - prevLat);
            encodeValue(sb, lon - prevLon);
            prevLat = lat;
            prevLon = lon;
        }
        return sb.toString();
    }

    private static void encodeValue(StringBuilder sb, long v) {
        long z = v < 0 ? ~(v << 1) : v << 1;
        while (z >= 0x20) {
            sb.append((char) ((0x20 | (z & 0x1f)) + 63));
            z >>= 5;
        }
        sb.append((char) (z + 63));
    }

    /** Inverse of {@link #encode}; used by tests. */
    public static double[] decode(String s) {
        double[] tmp = new double[s.length() * 2];
        int n = 0, i = 0;
        long lat = 0, lon = 0;
        while (i < s.length()) {
            long[] r = decodeValue(s, i);
            lat += r[0];
            r = decodeValue(s, (int) r[1]);
            lon += r[0];
            i = (int) r[1];
            tmp[n++] = lat / 1e5;
            tmp[n++] = lon / 1e5;
        }
        return java.util.Arrays.copyOf(tmp, n);
    }

    private static long[] decodeValue(String s, int i) {
        long result = 0;
        int shift = 0, b;
        do {
            b = s.charAt(i++) - 63;
            result |= (long) (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        return new long[] {(result & 1) != 0 ? ~(result >> 1) : result >> 1, i};
    }
}
