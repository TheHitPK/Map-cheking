package com.transmcbo.routing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

import org.junit.jupiter.api.Test;

class PolylineTest {

    @Test
    void matchesGoogleReferenceExample() {
        // https://developers.google.com/maps/documentation/utilities/polylinealgorithm
        double[] pts = {38.5, -120.2, 40.7, -120.95, 43.252, -126.453};
        assertThat(Polyline.encode(pts)).isEqualTo("_p~iF~ps|U_ulLnnqC_mqNvxq`@");
    }

    @Test
    void roundTripsMaracaiboCoordinates() {
        double[] pts = {10.642700, -71.612500, 10.643010, -71.611990, 10.650000, -71.600000};
        double[] back = Polyline.decode(Polyline.encode(pts));

        assertThat(back).hasSize(pts.length);
        for (int i = 0; i < pts.length; i++) {
            assertThat(back[i]).isCloseTo(pts[i], within(1e-5));
        }
    }

    @Test
    void emptyInputGivesEmptyString() {
        assertThat(Polyline.encode(new double[0])).isEmpty();
    }
}
