package com.transmcbo.ingest;

import com.google.protobuf.InvalidProtocolBufferException;
import com.transmcbo.ingest.PosValidator.Verdict;
import com.transmcbo.proto.Pos;
import com.transmcbo.proto.PosBatch;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Runs on the MQTT callback thread: decode, validate, coalesce, enqueue. Must never block.
 * Topics: {@code v/{line}/{veh}} (live Pos, retained) and {@code v/{line}/{veh}/b} (PosBatch, history only).
 */
@Component
public class IngestHandler {

    private static final Logger log = LoggerFactory.getLogger(IngestHandler.class);

    private final LivePositions live;
    private final HistoryQueue history;
    private final Clock clock;
    private final MeterRegistry registry;
    private final Map<String, Counter> counters = new HashMap<>();

    public IngestHandler(LivePositions live, HistoryQueue history, Clock clock, MeterRegistry registry) {
        this.live = live;
        this.history = history;
        this.clock = clock;
        this.registry = registry;
        for (Verdict v : Verdict.values()) {
            counter(v.name().toLowerCase());
        }
        for (String r : List.of("bad_topic", "decode_error", "veh_mismatch", "cleared")) {
            counter(r);
        }
    }

    public void onMessage(String topic, byte[] payload) {
        try {
            handle(topic, payload);
        } catch (RuntimeException e) {
            count("decode_error");
            log.debug("Rejected message on {}: {}", topic, e.toString());
        }
    }

    private void handle(String topic, byte[] payload) {
        String[] parts = topic.split("/");
        boolean batch = parts.length == 4 && parts[3].equals("b");
        if (!parts[0].equals("v") || !(parts.length == 3 || batch)) {
            count("bad_topic");
            return;
        }
        String line = parts[1];
        int veh = Integer.parseUnsignedInt(parts[2]);
        long now = clock.millis() / 1000;

        if (payload.length == 0) {
            if (!batch) {
                live.remove(veh);
                count("cleared");
            }
            return;
        }
        if (batch) {
            handleBatch(line, veh, decodeBatch(payload), now);
            return;
        }

        Fix fix = Fix.of(line, decodePos(payload));
        if (fix.veh() != veh) {
            count("veh_mismatch");
            return;
        }
        Verdict[] verdict = {Verdict.OK};
        live.putIf(fix, (prev, next) -> (verdict[0] = PosValidator.validateLive(prev, next, now)) == Verdict.OK);
        count(verdict[0].name().toLowerCase());
        if (verdict[0] == Verdict.OK) {
            history.offer(fix);
        }
    }

    /** Batched points are old by definition: history only, validated against each other. */
    private void handleBatch(String line, int veh, PosBatch batch, long now) {
        List<Fix> fixes = PosBatchDecoder.decode(line, batch);
        if (fixes.getFirst().veh() != veh) {
            count("veh_mismatch");
            return;
        }
        Fix prev = null;
        for (Fix fix : fixes) {
            Verdict v = PosValidator.validateStep(prev, fix, now);
            count(v.name().toLowerCase());
            if (v == Verdict.OK) {
                history.offer(fix);
                prev = fix;
            }
        }
    }

    private static Pos decodePos(byte[] payload) {
        try {
            return Pos.parseFrom(payload);
        } catch (InvalidProtocolBufferException e) {
            throw new IllegalArgumentException(e);
        }
    }

    private static PosBatch decodeBatch(byte[] payload) {
        try {
            return PosBatch.parseFrom(payload);
        } catch (InvalidProtocolBufferException e) {
            throw new IllegalArgumentException(e);
        }
    }

    private Counter counter(String result) {
        return counters.computeIfAbsent(result, r -> registry.counter("ingest.msgs", "result", r));
    }

    private void count(String result) {
        counters.get(result).increment();
    }
}
