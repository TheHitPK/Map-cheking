package com.transmcbo.auth;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.github.benmanes.caffeine.cache.Ticker;
import java.time.Duration;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.stereotype.Component;

/**
 * Brute-force guard for driver PINs: failed attempts per vehicle and per client IP in a fixed window
 * that starts at the first failure. In memory, so per backend instance.
 */
@Component
public class LoginLimiter {

    static final int MAX_PER_VEH = 5;
    static final int MAX_PER_IP = 20;
    static final Duration WINDOW = Duration.ofMinutes(15);

    private final Cache<String, AtomicInteger> failures;

    public LoginLimiter() {
        this(Ticker.systemTicker());
    }

    LoginLimiter(Ticker ticker) {
        this.failures = Caffeine.newBuilder().expireAfterWrite(WINDOW).ticker(ticker).maximumSize(100_000).build();
    }

    public boolean blocked(long veh, String ip) {
        return count("veh:" + veh) >= MAX_PER_VEH || count("ip:" + ip) >= MAX_PER_IP;
    }

    public void failed(long veh, String ip) {
        increment("veh:" + veh);
        increment("ip:" + ip);
    }

    public void succeeded(long veh) {
        failures.invalidate("veh:" + veh);
    }

    private int count(String key) {
        AtomicInteger n = failures.getIfPresent(key);
        return n == null ? 0 : n.get();
    }

    /** Mutating the existing counter is not a cache write, so later failures do not extend the window. */
    private void increment(String key) {
        failures.asMap().computeIfAbsent(key, k -> new AtomicInteger()).incrementAndGet();
    }
}
