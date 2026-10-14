package com.transmcbo.ingest;

import static com.transmcbo.ingest.PosValidator.Verdict.FUTURE;
import static com.transmcbo.ingest.PosValidator.Verdict.OK;
import static com.transmcbo.ingest.PosValidator.Verdict.OUT_OF_AREA;
import static com.transmcbo.ingest.PosValidator.Verdict.STALE;
import static com.transmcbo.ingest.PosValidator.Verdict.TOO_FAST;
import static com.transmcbo.ingest.PosValidator.Verdict.TOO_OLD;
import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class PosValidatorTest {

    static final long NOW = 1_800_000_000L;
    static final int LAT = 10_642_700, LON = -71_612_500; // Maracaibo centre

    static Fix fix(long ts, int lat, int lon, int spd) {
        return new Fix("12", 7, ts, lat, lon, spd, 0);
    }

    @Test
    void firstFixInsideAreaIsAccepted() {
        assertThat(PosValidator.validateLive(null, fix(NOW, LAT, LON, 30), NOW)).isEqualTo(OK);
    }

    @Test
    void rejectsRepeatedOrOlderTimestamp() {
        Fix prev = fix(NOW, LAT, LON, 30);
        assertThat(PosValidator.validateLive(prev, fix(NOW, LAT, LON, 30), NOW)).isEqualTo(STALE);
        assertThat(PosValidator.validateLive(prev, fix(NOW - 5, LAT, LON, 30), NOW)).isEqualTo(STALE);
    }

    @Test
    void rejectsFutureAndTooOld() {
        assertThat(PosValidator.validateLive(null, fix(NOW + 61, LAT, LON, 0), NOW)).isEqualTo(FUTURE);
        assertThat(PosValidator.validateLive(null, fix(NOW - 121, LAT, LON, 0), NOW)).isEqualTo(TOO_OLD);
    }

    @Test
    void rejectsOutsideMaracaibo() {
        assertThat(PosValidator.validateLive(null, fix(NOW, 10_480_000 - 200_000, LON, 0), NOW)).isEqualTo(OUT_OF_AREA);
    }

    @Test
    void rejectsReportedSpeedOver120() {
        assertThat(PosValidator.validateLive(null, fix(NOW, LAT, LON, 121), NOW)).isEqualTo(TOO_FAST);
    }

    @Test
    void rejectsImpossibleJump() {
        // ~1.1 km in 10 s = ~400 km/h
        Fix prev = fix(NOW - 10, LAT, LON, 40);
        assertThat(PosValidator.validateLive(prev, fix(NOW, LAT + 10_000, LON, 40), NOW)).isEqualTo(TOO_FAST);
    }

    @Test
    void acceptsNormalMovementAndGpsJitter() {
        Fix prev = fix(NOW - 15, LAT, LON, 40);
        // ~170 m in 15 s = ~40 km/h
        assertThat(PosValidator.validateLive(prev, fix(NOW, LAT + 1_500, LON, 40), NOW)).isEqualTo(OK);
        // ~22 m jitter in 1 s would be ~80 km/h raw, tolerated
        assertThat(PosValidator.validateLive(prev, fix(prev.ts() + 1, LAT + 200, LON, 0), NOW)).isEqualTo(OK);
    }
}
