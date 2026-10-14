package com.transmcbo.auth;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class PinHasherTest {

    @Test
    void matchesOnlyTheRightPin() {
        String stored = PinHasher.hash("4821");

        assertThat(stored).startsWith("pbkdf2$" + PinHasher.ITERATIONS + "$");
        assertThat(PinHasher.matches("4821", stored)).isTrue();
        assertThat(PinHasher.matches("4822", stored)).isFalse();
    }

    @Test
    void saltsEveryHash() {
        assertThat(PinHasher.hash("4821")).isNotEqualTo(PinHasher.hash("4821"));
    }

    @Test
    void rejectsUnknownFormat() {
        assertThat(PinHasher.matches("4821", "plain$4821")).isFalse();
    }
}
