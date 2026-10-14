package com.transmcbo.api;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class ApproachFilterTest {

    static final int LAT = 10_642_700, LON = -71_612_500; // passenger
    static final int M100 = 900;                           // ~100 m of latitude in degrees * 1e6

    @Test
    void movingTowardsPassengerIsApproaching() {
        assertThat(ApproachFilter.approaching(LAT + 5 * M100, LON, LAT + 7 * M100, LON, 90, LAT, LON)).isTrue();
    }

    @Test
    void movingAwayIsNotApproaching() {
        assertThat(ApproachFilter.approaching(LAT + 5 * M100, LON, LAT + 3 * M100, LON, 0, LAT, LON)).isFalse();
    }

    @Test
    void veryCloseIsAlwaysShown() {
        assertThat(ApproachFilter.approaching(LAT + M100 / 2, LON, LAT, LON, 0, LAT, LON)).isTrue();
    }

    @Test
    void stoppedVehicleUsesHeading() {
        int lat = LAT + 5 * M100; // north of the passenger
        assertThat(ApproachFilter.approaching(lat, LON, lat, LON, 90, LAT, LON)).as("facing south (180°)").isTrue();
        assertThat(ApproachFilter.approaching(lat, LON, lat, LON, 0, LAT, LON)).as("facing north (0°)").isFalse();
        assertThat(ApproachFilter.approaching(lat, LON, lat, LON, 110, LAT, LON)).as("220°, within 60°").isTrue();
    }
}
