package com.transmcbo.history;

import com.transmcbo.ingest.Fix;
import com.transmcbo.ingest.HistoryQueue;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import java.io.IOException;
import java.io.StringReader;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import javax.sql.DataSource;
import org.postgresql.PGConnection;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.SmartLifecycle;
import org.springframework.stereotype.Component;

/**
 * Single thread that drains {@link HistoryQueue} into PostGIS every 2 s or 1000 points.
 * COPY into a temp table, then INSERT ... ON CONFLICT DO NOTHING so resent batches are ignored.
 */
@Component
public class HistoryWriter implements SmartLifecycle {

    static final int BATCH = 1000;
    static final long MAX_WAIT_MS = 2000;
    static final long MAX_BACKOFF_MS = 30_000;

    private static final Logger log = LoggerFactory.getLogger(HistoryWriter.class);

    private final HistoryQueue queue;
    private final DataSource dataSource;
    private final Counter written;
    private final Counter errors;
    private final Timer latency;
    private volatile boolean running;
    private Thread thread;

    public HistoryWriter(HistoryQueue queue, DataSource dataSource, MeterRegistry registry) {
        this.queue = queue;
        this.dataSource = dataSource;
        this.written = registry.counter("history.written");
        this.errors = registry.counter("history.write.errors");
        this.latency = registry.timer("history.write.latency");
    }

    @Override
    public void start() {
        running = true;
        thread = Thread.ofPlatform().name("history-writer").start(this::loop);
    }

    @Override
    public void stop() {
        running = false;
        if (thread == null) {
            return;
        }
        try {
            thread.join(MAX_WAIT_MS + 10_000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    @Override
    public boolean isRunning() {
        return running;
    }

    /** Starts before and stops after the MQTT client (default phase), so the queue is drained on shutdown. */
    @Override
    public int getPhase() {
        return DEFAULT_PHASE - 1000;
    }

    private void loop() {
        List<Fix> batch = new ArrayList<>(BATCH);
        long backoff = 1000;
        while (true) {
            boolean stopping = !running;
            try {
                collect(batch, stopping);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                stopping = true;
            }
            if (batch.isEmpty()) {
                if (stopping) {
                    return;
                }
                continue;
            }
            try {
                write(batch);
                batch.clear();
                backoff = 1000;
            } catch (SQLException | IOException e) {
                errors.increment();
                if (stopping) {
                    log.error("History write failed during shutdown, {} points lost", batch.size(), e);
                    return;
                }
                log.warn("History write of {} points failed, retrying in {} ms: {}", batch.size(), backoff, e.toString());
                sleep(backoff);
                backoff = Math.min(backoff * 2, MAX_BACKOFF_MS);
            }
        }
    }

    /** Fills {@code batch} up to BATCH points or MAX_WAIT_MS; when stopping, only takes what is already queued. */
    private void collect(List<Fix> batch, boolean stopping) throws InterruptedException {
        if (stopping) {
            queue.drainTo(batch, BATCH - batch.size());
            return;
        }
        long deadline = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(MAX_WAIT_MS);
        while (batch.size() < BATCH) {
            long remaining = deadline - System.nanoTime();
            if (remaining <= 0) {
                return;
            }
            Fix fix = queue.poll(remaining, TimeUnit.NANOSECONDS);
            if (fix == null) {
                return;
            }
            batch.add(fix);
            queue.drainTo(batch, BATCH - batch.size());
        }
    }

    private void write(List<Fix> batch) throws SQLException, IOException {
        long start = System.nanoTime();
        try (Connection c = dataSource.getConnection()) {
            c.setAutoCommit(false);
            try (Statement st = c.createStatement()) {
                st.execute("CREATE TEMP TABLE IF NOT EXISTS trace_point_in (LIKE trace_point) ON COMMIT DELETE ROWS");
                c.unwrap(PGConnection.class).getCopyAPI().copyIn(
                        "COPY trace_point_in (veh, ts, line, geom, spd, hdg) FROM STDIN", new StringReader(toCopyText(batch)));
                int inserted = st.executeUpdate("""
                        INSERT INTO trace_point (veh, ts, line, geom, spd, hdg)
                        SELECT veh, ts, line, geom, spd, hdg FROM trace_point_in
                        ON CONFLICT DO NOTHING""");
                c.commit();
                written.increment(inserted);
            } catch (SQLException | IOException | RuntimeException e) {
                c.rollback();
                throw e;
            }
        } finally {
            latency.record(System.nanoTime() - start, TimeUnit.NANOSECONDS);
        }
    }

    static String toCopyText(List<Fix> batch) {
        StringBuilder sb = new StringBuilder(batch.size() * 80);
        for (Fix f : batch) {
            sb.append(Integer.toUnsignedLong(f.veh())).append('\t')
                    .append(Instant.ofEpochSecond(f.ts())).append('\t')
                    .append(escape(f.line())).append('\t')
                    .append("SRID=4326;POINT(")
                    .append(BigDecimal.valueOf(f.lon(), 6).toPlainString()).append(' ')
                    .append(BigDecimal.valueOf(f.lat(), 6).toPlainString()).append(")\t")
                    .append(f.spd()).append('\t')
                    .append(f.hdg()).append('\n');
        }
        return sb.toString();
    }

    /** COPY text format escaping. */
    private static String escape(String s) {
        return s.replace("\\", "\\\\").replace("\t", "\\t").replace("\n", "\\n").replace("\r", "\\r");
    }

    private static void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
