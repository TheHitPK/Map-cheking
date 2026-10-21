package com.asistencia.auth.application;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Brute-force guard: failed logins per document and per client IP in a fixed window that starts at the first failure.
 * In memory, so per backend instance.
 */
public class LoginThrottle {

    static final int MAX_PER_DOCUMENT = 5;
    static final int MAX_PER_IP = 30;
    static final Duration WINDOW = Duration.ofMinutes(15);
    private static final int MAX_KEYS = 100_000;

    private record Failures(Instant since, int count) {
    }

    private final ConcurrentHashMap<String, Failures> failures = new ConcurrentHashMap<>();
    private final Clock clock;

    public LoginThrottle(Clock clock) {
        this.clock = clock;
    }

    public boolean blocked(String document, String ip) {
        return count("doc:" + document) >= MAX_PER_DOCUMENT || count("ip:" + ip) >= MAX_PER_IP;
    }

    public void failed(String document, String ip) {
        if (failures.size() > MAX_KEYS) {
            evictExpired();
        }
        increment("doc:" + document);
        increment("ip:" + ip);
    }

    public void succeeded(String document) {
        failures.remove("doc:" + document);
    }

    public Duration window() {
        return WINDOW;
    }

    private int count(String key) {
        Failures f = failures.get(key);
        return f == null || expired(f) ? 0 : f.count();
    }

    private void increment(String key) {
        failures.compute(key, (k, f) -> f == null || expired(f) ? new Failures(clock.instant(), 1)
                : new Failures(f.since(), f.count() + 1));
    }

    private boolean expired(Failures f) {
        return f.since().plus(WINDOW).isBefore(clock.instant());
    }

    private void evictExpired() {
        failures.values().removeIf(this::expired);
    }
}
