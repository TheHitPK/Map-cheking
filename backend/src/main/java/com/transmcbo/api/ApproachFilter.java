package com.transmcbo.api;

import com.transmcbo.ingest.Geo;

/** Decides whether a vehicle is coming towards the passenger. */
public final class ApproachFilter {

    static final double ARRIVING_M = 100;     // this close: always shown
    static final double MIN_MOVE_M = 10;      // below this, previous position says nothing
    static final double MAX_HEADING_DIFF = 60;
    static final int STOPPED_KMH = 2;         // at or below this (and not moving), the GPS heading is meaningless

    public enum Approach { APPROACHING, STOPPED, AWAY }

    private ApproachFilter() {
    }

    /**
     * Stopped vehicles have no usable heading: they are reported as {@link Approach#STOPPED}, not hidden.
     *
     * @param hdgHalf heading in degrees / 2, as in the protocol
     */
    public static Approach classify(int lat, int lon, int plat, int plon, int spd, int hdgHalf, int userLat, int userLon) {
        double now = Geo.distanceMeters(lat, lon, userLat, userLon);
        if (now <= ARRIVING_M) {
            return Approach.APPROACHING;
        }
        if (Geo.distanceMeters(plat, plon, lat, lon) >= MIN_MOVE_M) {
            return now < Geo.distanceMeters(plat, plon, userLat, userLon) ? Approach.APPROACHING : Approach.AWAY;
        }
        if (spd <= STOPPED_KMH) {
            return Approach.STOPPED;
        }
        double toUser = Geo.bearingDeg(lat, lon, userLat, userLon);
        double diff = Math.abs(toUser - hdgHalf * 2.0) % 360;
        return Math.min(diff, 360 - diff) <= MAX_HEADING_DIFF ? Approach.APPROACHING : Approach.AWAY;
    }
}
