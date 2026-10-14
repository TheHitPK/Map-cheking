package com.transmcbo.ingest;

/** Stateless plausibility checks; the caller supplies the previous accepted fix. */
public final class PosValidator {

    public enum Verdict { OK, STALE, FUTURE, TOO_OLD, OUT_OF_AREA, TOO_FAST }

    static final double MAX_KMH = 120;
    static final double JITTER_M = 30;          // GPS noise tolerated before computing implied speed
    static final long MAX_FUTURE_S = 60;
    static final long MAX_LIVE_AGE_S = 120;     // matches the Redis TTL

    private PosValidator() {
    }

    /** Live message: must be recent and newer than the last accepted fix. */
    public static Verdict validateLive(Fix prev, Fix next, long nowSec) {
        if (next.ts() < nowSec - MAX_LIVE_AGE_S) {
            return Verdict.TOO_OLD;
        }
        return validateStep(prev, next, nowSec);
    }

    /** Ordering, area and speed checks shared by live and batched fixes. */
    public static Verdict validateStep(Fix prev, Fix next, long nowSec) {
        if (next.ts() > nowSec + MAX_FUTURE_S) {
            return Verdict.FUTURE;
        }
        if (!Geo.inServiceArea(next.lat(), next.lon())) {
            return Verdict.OUT_OF_AREA;
        }
        if (next.spd() > MAX_KMH) {
            return Verdict.TOO_FAST;
        }
        if (prev == null) {
            return Verdict.OK;
        }
        long dt = next.ts() - prev.ts();
        if (dt <= 0) {
            return Verdict.STALE;
        }
        double meters = Math.max(0, Geo.distanceMeters(prev.lat(), prev.lon(), next.lat(), next.lon()) - JITTER_M);
        double kmh = meters / dt * 3.6;
        return kmh > MAX_KMH ? Verdict.TOO_FAST : Verdict.OK;
    }
}
