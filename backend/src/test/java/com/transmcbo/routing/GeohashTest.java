package com.transmcbo.routing;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class GeohashTest {

    @Test
    void matchesKnownReference() {
        // Classic example from the geohash spec (Jutland, Denmark)
        assertThat(Geohash.encode(57.64911, 10.40744, 11)).isEqualTo("u4pruydqqvj");
    }

    @Test
    void nearbyPointsShareTheCellAndDistantOnesDoNot() {
        String a = Geohash.encode(10.642700, -71.612500, 7);
        assertThat(a).hasSize(7);
        assertThat(Geohash.encode(10.642710, -71.612490, 7)).isEqualTo(a);  // ~1.5 m away
        assertThat(Geohash.encode(10.650000, -71.612500, 7)).isNotEqualTo(a); // ~800 m away
    }
}
