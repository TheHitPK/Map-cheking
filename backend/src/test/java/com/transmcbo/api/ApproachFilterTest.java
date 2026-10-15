package com.transmcbo.api;

import static org.assertj.core.api.Assertions.assertThat;

import com.transmcbo.api.ApproachFilter.Approach;
import org.junit.jupiter.api.Test;

class ApproachFilterTest {

    static final int LAT = 10_642_700, LON = -71_612_500; // passenger
    static final int M100 = 900;                           // ~100 m of latitude in degrees * 1e6

    @Test
    void movingTowardsPassengerIsApproaching() {
        assertThat(ApproachFilter.classify(LAT + 5 * M100, LON, LAT + 7 * M100, LON, 30, 90, LAT, LON)).isEqualTo(Approach.APPROACHING);
    }

    @Test
    void movingAwayIsAway() {
        assertThat(ApproachFilter.classify(LAT + 5 * M100, LON, LAT + 3 * M100, LON, 30, 0, LAT, LON)).isEqualTo(Approach.AWAY);
    }

    @Test
    void veryCloseIsAlwaysShown() {
        assertThat(ApproachFilter.classify(LAT + M100 / 2, LON, LAT, LON, 30, 0, LAT, LON)).isEqualTo(Approach.APPROACHING);
    }

    @Test
    void stoppedVehicleIsStoppedWhateverItsHeading() {
        int lat = LAT + 5 * M100;
        assertThat(ApproachFilter.classify(lat, LON, lat, LON, 0, 0, LAT, LON)).isEqualTo(Approach.STOPPED);
        assertThat(ApproachFilter.classify(lat, LON, lat, LON, 2, 90, LAT, LON)).isEqualTo(Approach.STOPPED);
    }

    @Test
    void slowVehicleWithoutDisplacementUsesHeading() {
        int lat = LAT + 5 * M100; // north of the passenger
        assertThat(ApproachFilter.classify(lat, LON, lat, LON, 8, 90, LAT, LON)).as("facing south (180°)").isEqualTo(Approach.APPROACHING);
        assertThat(ApproachFilter.classify(lat, LON, lat, LON, 8, 0, LAT, LON)).as("facing north (0°)").isEqualTo(Approach.AWAY);
        assertThat(ApproachFilter.classify(lat, LON, lat, LON, 8, 110, LAT, LON)).as("220°, within 60°").isEqualTo(Approach.APPROACHING);
    }
}
