package com.transmcbo.history;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

import com.transmcbo.ingest.Fix;
import com.transmcbo.ingest.HistoryQueue;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Duration;
import java.util.Map;
import java.util.function.BooleanSupplier;
import javax.sql.DataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.jdbc.core.JdbcTemplate;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

@SpringBootTest(properties = "transmcbo.mqtt.enabled=false")
@Testcontainers
class HistoryWriterIT {

    static final long NOW = 1_800_000_000L;
    static final int LAT = 10_642_700, LON = -71_612_500;

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgis = new PostgreSQLContainer(
            DockerImageName.parse("postgis/postgis:16-3.4").asCompatibleSubstituteFor("postgres"));

    @Container
    @ServiceConnection(name = "redis")
    static GenericContainer<?> redis = new GenericContainer<>("redis:7.4.1-alpine").withExposedPorts(6379);

    @Autowired
    HistoryQueue queue;
    @Autowired
    DataSource dataSource;
    @Autowired
    JdbcTemplate jdbc;

    @BeforeEach
    void truncate() {
        jdbc.execute("TRUNCATE trace_point");
    }

    int rows(int veh) {
        return jdbc.queryForObject("SELECT count(*) FROM trace_point WHERE veh = ?", Integer.class, veh);
    }

    static void await(Duration timeout, BooleanSupplier condition) throws InterruptedException {
        long deadline = System.nanoTime() + timeout.toNanos();
        while (!condition.getAsBoolean()) {
            assertThat(System.nanoTime()).as("condition not met within %s", timeout).isLessThan(deadline);
            Thread.sleep(50);
        }
    }

    @Test
    void writesPointsWithGeometry() throws InterruptedException {
        queue.offer(new Fix("12", 7, NOW, LAT, LON, 30, 45));
        queue.offer(new Fix("12", 7, NOW + 15, LAT + 1_000, LON, 32, 46));

        await(Duration.ofSeconds(5), () -> rows(7) == 2);
        Map<String, Object> row = jdbc.queryForMap("""
                SELECT line, ST_X(geom) AS x, ST_Y(geom) AS y, ST_SRID(geom) AS srid, spd, hdg, extract(epoch FROM ts)::bigint AS ts
                FROM trace_point WHERE veh = 7 ORDER BY ts LIMIT 1""");
        assertThat(row).containsEntry("line", "12").containsEntry("srid", 4326).containsEntry("ts", NOW);
        assertThat((Double) row.get("x")).isCloseTo(-71.6125, within(1e-9));
        assertThat((Double) row.get("y")).isCloseTo(10.6427, within(1e-9));
        assertThat(((Number) row.get("spd")).intValue()).isEqualTo(30);
        assertThat(((Number) row.get("hdg")).intValue()).isEqualTo(45);
    }

    @Test
    void duplicatePointsAreIgnored() throws InterruptedException {
        Fix fix = new Fix("12", 8, NOW, LAT, LON, 30, 0);
        queue.offer(fix);
        queue.offer(fix);
        await(Duration.ofSeconds(5), () -> rows(8) == 1);

        queue.offer(fix);
        queue.offer(new Fix("12", 8, NOW + 15, LAT, LON, 30, 0));
        await(Duration.ofSeconds(5), () -> rows(8) == 2);
    }

    @Test
    void fullBatchIsWrittenWithoutWaiting() throws InterruptedException {
        for (int i = 0; i < HistoryWriter.BATCH; i++) {
            queue.offer(new Fix("12", 9, NOW + i, LAT, LON, 30, 0));
        }
        await(Duration.ofMillis(HistoryWriter.MAX_WAIT_MS - 500), () -> rows(9) == HistoryWriter.BATCH);
    }

    @Test
    void stopDrainsQueue() {
        HistoryQueue own = new HistoryQueue(100, new SimpleMeterRegistry());
        HistoryWriter writer = new HistoryWriter(own, dataSource, new SimpleMeterRegistry());
        writer.start();
        for (int i = 0; i < 10; i++) {
            own.offer(new Fix("12", 10, NOW + i, LAT, LON, 30, 0));
        }
        writer.stop();

        assertThat(rows(10)).isEqualTo(10);
        assertThat(own.size()).isZero();
    }

    @Test
    void lineIsEscapedForCopy() throws InterruptedException {
        queue.offer(new Fix("a\tb\\c", 11, NOW, LAT, LON, 0, 0));
        await(Duration.ofSeconds(5), () -> rows(11) == 1);
        assertThat(jdbc.queryForObject("SELECT line FROM trace_point WHERE veh = 11", String.class)).isEqualTo("a\tb\\c");
    }
}
