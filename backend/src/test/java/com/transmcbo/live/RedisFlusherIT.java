package com.transmcbo.live;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

import com.transmcbo.ingest.Fix;
import com.transmcbo.ingest.LivePositions;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.geo.Point;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@Testcontainers
class RedisFlusherIT {

    static final long NOW = 1_800_000_000L;
    static final int LAT = 10_642_700, LON = -71_612_500;

    @Container
    static GenericContainer<?> redisContainer = new GenericContainer<>("redis:7.4.1-alpine").withExposedPorts(6379);

    LettuceConnectionFactory factory;
    StringRedisTemplate redis;
    LivePositions live;
    SimpleMeterRegistry registry;
    RedisFlusher flusher;

    @BeforeEach
    void setUp() {
        factory = connect(redisContainer.getHost(), redisContainer.getMappedPort(6379));
        redis = new StringRedisTemplate(factory);
        redis.getConnectionFactory().getConnection().serverCommands().flushAll();
        live = new LivePositions();
        registry = new SimpleMeterRegistry();
        flusher = new RedisFlusher(live, redis, Clock.fixed(Instant.ofEpochSecond(NOW), ZoneOffset.UTC), registry);
    }

    @AfterEach
    void tearDown() {
        factory.destroy();
    }

    static LettuceConnectionFactory connect(String host, int port) {
        LettuceConnectionFactory f = new LettuceConnectionFactory(new RedisStandaloneConfiguration(host, port));
        f.afterPropertiesSet();
        f.start();
        return f;
    }

    void put(Fix fix) {
        live.putIf(fix, (prev, next) -> true);
    }

    @Test
    void writesGeoMemberAndHashWithTtl() {
        put(new Fix("12", 7, NOW, LAT, LON, 30, 45));
        flusher.flush();

        List<Point> pos = redis.opsForGeo().position("geo:12", "7");
        assertThat(pos.getFirst().getY()).isCloseTo(10.6427, within(1e-5));
        assertThat(pos.getFirst().getX()).isCloseTo(-71.6125, within(1e-5));
        assertThat(redis.<String, String>opsForHash().entries("veh:7"))
                .containsEntry("line", "12").containsEntry("ts", Long.toString(NOW))
                .containsEntry("spd", "30").containsEntry("hdg", "45")
                .containsEntry("plat", Integer.toString(LAT));
        assertThat(redis.getExpire("veh:7")).isBetween(1L, RedisFlusher.TTL_S);
        assertThat(registry.counter("flush.vehicles").count()).isEqualTo(1);
        assertThat(registry.counter("flush.errors").count()).isZero();
    }

    @Test
    void keepsPreviousPositionForApproachFilter() {
        put(new Fix("12", 7, NOW - 15, LAT, LON, 30, 0));
        flusher.flush();
        put(new Fix("12", 7, NOW, LAT + 1_000, LON, 30, 0));
        flusher.flush();

        assertThat(redis.<String, String>opsForHash().entries("veh:7"))
                .containsEntry("lat", Integer.toString(LAT + 1_000))
                .containsEntry("plat", Integer.toString(LAT));
    }

    @Test
    void onlyChangedVehiclesAreWritten() {
        put(new Fix("12", 7, NOW, LAT, LON, 30, 0));
        flusher.flush();
        redis.delete("veh:7");
        flusher.flush();

        assertThat(redis.hasKey("veh:7")).isFalse();
    }

    @Test
    void removalDeletesHashAndGeoMember() {
        put(new Fix("12", 7, NOW, LAT, LON, 30, 0));
        flusher.flush();
        live.remove(7);
        flusher.flush();

        assertThat(redis.hasKey("veh:7")).isFalse();
        assertThat(redis.opsForZSet().size("geo:12")).isZero();
    }

    @Test
    void lineChangeMovesGeoMember() {
        put(new Fix("12", 7, NOW - 15, LAT, LON, 30, 0));
        flusher.flush();
        put(new Fix("30", 7, NOW, LAT, LON, 30, 0));
        flusher.flush();

        assertThat(redis.opsForZSet().size("geo:12")).isZero();
        assertThat(redis.opsForZSet().size("geo:30")).isEqualTo(1);
    }

    @Test
    void inactiveVehicleIsEvicted() {
        put(new Fix("12", 7, NOW - 30, LAT, LON, 30, 0));
        flusher.flush();
        put(new Fix("12", 7, NOW - RedisFlusher.TTL_S - 1, LAT, LON, 30, 0));
        flusher.flush();

        assertThat(live.get(7)).isNull();
        assertThat(redis.hasKey("veh:7")).isFalse();
        assertThat(redis.opsForZSet().size("geo:12")).isZero();
    }

    @Test
    void failedFlushKeepsVehiclesDirty() {
        LettuceConnectionFactory down = connect("localhost", 1);
        try {
            RedisFlusher broken = new RedisFlusher(live, new StringRedisTemplate(down),
                    Clock.fixed(Instant.ofEpochSecond(NOW), ZoneOffset.UTC), registry);
            put(new Fix("12", 7, NOW, LAT, LON, 30, 0));
            broken.flush();

            assertThat(registry.counter("flush.errors").count()).isEqualTo(1);
            assertThat(live.drainDirty()).containsExactly(7);
        } finally {
            down.destroy();
        }
    }
}
