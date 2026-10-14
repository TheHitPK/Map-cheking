package com.transmcbo.auth;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import java.util.concurrent.atomic.AtomicLong;
import org.junit.jupiter.api.Test;

class LoginLimiterTest {

    final AtomicLong nanos = new AtomicLong();
    final LoginLimiter limiter = new LoginLimiter(nanos::get);

    void advance(Duration d) {
        nanos.addAndGet(d.toNanos());
    }

    @Test
    void blocksVehicleAfterFiveFailuresUntilWindowEnds() {
        for (int i = 0; i < LoginLimiter.MAX_PER_VEH; i++) {
            assertThat(limiter.blocked(7, "1.1.1." + i)).isFalse();
            limiter.failed(7, "1.1.1." + i);
            advance(Duration.ofMinutes(1));
        }
        assertThat(limiter.blocked(7, "9.9.9.9")).as("other IP, same vehicle").isTrue();
        assertThat(limiter.blocked(8, "9.9.9.9")).as("other vehicle").isFalse();

        advance(LoginLimiter.WINDOW.minusMinutes(LoginLimiter.MAX_PER_VEH - 1)); // window counted from the 1st failure
        assertThat(limiter.blocked(7, "9.9.9.9")).isFalse();
    }

    @Test
    void blocksIpTryingManyVehicles() {
        for (int veh = 1; veh <= LoginLimiter.MAX_PER_IP; veh++) {
            limiter.failed(veh, "6.6.6.6");
        }
        assertThat(limiter.blocked(999, "6.6.6.6")).isTrue();
        assertThat(limiter.blocked(999, "7.7.7.7")).isFalse();
    }

    @Test
    void successResetsVehicleCounter() {
        for (int i = 0; i < LoginLimiter.MAX_PER_VEH - 1; i++) {
            limiter.failed(7, "1.1.1.1");
        }
        limiter.succeeded(7);
        limiter.failed(7, "1.1.1.1");
        assertThat(limiter.blocked(7, "2.2.2.2")).isFalse();
    }
}
