package com.transmcbo.live;

import com.transmcbo.ingest.Fix;
import com.transmcbo.ingest.LivePositions;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import java.time.Clock;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.geo.Point;
import org.springframework.data.redis.connection.DefaultStringRedisConnection;
import org.springframework.data.redis.connection.StringRedisConnection;
import org.springframework.data.redis.core.RedisCallback;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Writes changed vehicles to Redis once per second in a single pipeline.
 * Layout: {@code geo:{line}} GEO set of vehicle ids; {@code veh:{veh}} hash with the fix and previous position.
 */
@Component
public class RedisFlusher {

    public static final long TTL_S = 120;

    private static final Logger log = LoggerFactory.getLogger(RedisFlusher.class);

    private final LivePositions live;
    private final StringRedisTemplate redis;
    private final Clock clock;
    private final Timer latency;
    private final Counter vehicles;
    private final Counter errors;
    /** Last fix written per vehicle: previous line (for ZREM on line change) and previous position. */
    private final Map<Integer, Fix> written = new HashMap<>();

    public RedisFlusher(LivePositions live, StringRedisTemplate redis, Clock clock, MeterRegistry registry) {
        this.live = live;
        this.redis = redis;
        this.clock = clock;
        this.latency = registry.timer("flush.latency");
        this.vehicles = registry.counter("flush.vehicles");
        this.errors = registry.counter("flush.errors");
    }

    public static String geoKey(String line) {
        return "geo:" + line;
    }

    public static String vehKey(int veh) {
        return "veh:" + veh;
    }

    @Scheduled(fixedDelay = 1000)
    public synchronized void flush() {
        live.evictOlderThan(clock.millis() / 1000 - TTL_S);
        List<Integer> dirty = live.drainDirty();
        if (dirty.isEmpty()) {
            return;
        }
        Map<Integer, Fix> current = new HashMap<>();
        for (int veh : dirty) {
            current.put(veh, live.get(veh));
        }
        try {
            latency.record(() -> redis.executePipelined((RedisCallback<Object>) conn -> {
                StringRedisConnection c = conn instanceof StringRedisConnection s ? s : new DefaultStringRedisConnection(conn);
                current.forEach((veh, fix) -> write(c, veh, fix, written.get(veh)));
                return null;
            }));
        } catch (RuntimeException e) {
            errors.increment();
            live.markDirty(dirty);
            log.warn("Redis flush of {} vehicles failed: {}", dirty.size(), e.toString());
            return;
        }
        current.forEach((veh, fix) -> {
            if (fix == null) {
                written.remove(veh);
            } else {
                written.put(veh, fix);
            }
        });
        vehicles.increment(dirty.size());
    }

    private static void write(StringRedisConnection c, int veh, Fix fix, Fix prev) {
        String key = vehKey(veh);
        String member = Integer.toUnsignedString(veh);
        if (prev != null && (fix == null || !prev.line().equals(fix.line()))) {
            c.zRem(geoKey(prev.line()), member);
        }
        if (fix == null) {
            c.del(key);
            return;
        }
        Fix p = prev != null ? prev : fix;
        c.geoAdd(geoKey(fix.line()), new Point(fix.lon() / 1e6, fix.lat() / 1e6), member);
        c.hMSet(key, Map.of(
                "line", fix.line(),
                "ts", Long.toString(fix.ts()),
                "lat", Integer.toString(fix.lat()),
                "lon", Integer.toString(fix.lon()),
                "spd", Integer.toString(fix.spd()),
                "hdg", Integer.toString(fix.hdg()),
                "plat", Integer.toString(p.lat()),
                "plon", Integer.toString(p.lon())));
        c.expire(key, TTL_S);
    }
}
