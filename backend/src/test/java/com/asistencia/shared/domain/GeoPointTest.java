package com.asistencia.shared.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;

import org.junit.jupiter.api.Test;

class GeoPointTest {

    @Test
    void distanceMatchesKnownValues() {
        GeoPoint a = new GeoPoint(10.6427, -71.6125);
        assertThat(a.distanceTo(a)).isZero();
        // 0.001° of latitude ≈ 111.2 m
        assertThat(a.distanceTo(new GeoPoint(10.6437, -71.6125))).isCloseTo(111.2, within(0.5));
        // Maracaibo → Caracas ≈ 520 km
        assertThat(a.distanceTo(new GeoPoint(10.4806, -66.9036)) / 1000).isCloseTo(515, within(10.0));
    }

    @Test
    void rejectsOutOfRange() {
        assertThatThrownBy(() -> new GeoPoint(91, 0)).isInstanceOf(InvalidInputException.class);
        assertThatThrownBy(() -> new GeoPoint(0, Double.NaN)).isInstanceOf(InvalidInputException.class);
    }
}
