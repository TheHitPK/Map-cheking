package com.transmcbo.ingest;

import static org.assertj.core.api.Assertions.assertThat;

import com.transmcbo.proto.Pos;
import com.transmcbo.proto.PosBatch;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class IngestHandlerTest {

    static final long NOW = 1_800_000_000L;
    static final int LAT = 10_642_700, LON = -71_612_500;

    SimpleMeterRegistry registry;
    LivePositions live;
    HistoryQueue history;
    IngestHandler handler;

    @BeforeEach
    void setUp() {
        registry = new SimpleMeterRegistry();
        live = new LivePositions();
        history = new HistoryQueue(3, registry);
        handler = new IngestHandler(live, history, Clock.fixed(Instant.ofEpochSecond(NOW), ZoneOffset.UTC), registry);
    }

    static byte[] pos(int veh, long ts, int lat) {
        return Pos.newBuilder().setVeh(veh).setTs((int) ts).setLat(lat).setLon(LON).setSpd(30).build().toByteArray();
    }

    double count(String result) {
        return registry.counter("ingest.msgs", "result", result).count();
    }

    List<Fix> drainHistory() {
        List<Fix> out = new ArrayList<>();
        history.drainTo(out, 100);
        return out;
    }

    @Test
    void validLivePositionUpdatesLatestAndHistory() {
        handler.onMessage("v/12/7", pos(7, NOW, LAT));

        assertThat(live.get(7)).isEqualTo(new Fix("12", 7, NOW, LAT, LON, 30, 0));
        assertThat(live.drainDirty()).containsExactly(7);
        assertThat(drainHistory()).hasSize(1);
        assertThat(count("ok")).isEqualTo(1);
    }

    @Test
    void staleLivePositionKeepsPreviousAndSkipsHistory() {
        handler.onMessage("v/12/7", pos(7, NOW, LAT));
        live.drainDirty();
        handler.onMessage("v/12/7", pos(7, NOW - 1, LAT + 100));

        assertThat(live.get(7).ts()).isEqualTo(NOW);
        assertThat(live.drainDirty()).isEmpty();
        assertThat(drainHistory()).hasSize(1);
        assertThat(count("stale")).isEqualTo(1);
    }

    @Test
    void emptyRetainedPayloadClearsVehicle() {
        handler.onMessage("v/12/7", pos(7, NOW, LAT));
        live.drainDirty();
        handler.onMessage("v/12/7", new byte[0]);

        assertThat(live.get(7)).isNull();
        assertThat(live.drainDirty()).containsExactly(7);
        assertThat(count("cleared")).isEqualTo(1);
    }

    @Test
    void payloadVehicleMustMatchTopic() {
        handler.onMessage("v/12/7", pos(8, NOW, LAT));

        assertThat(live.get(7)).isNull();
        assertThat(live.get(8)).isNull();
        assertThat(count("veh_mismatch")).isEqualTo(1);
    }

    @Test
    void badTopicAndGarbageAreCounted() {
        handler.onMessage("x/12/7", pos(7, NOW, LAT));
        handler.onMessage("v/12", pos(7, NOW, LAT));
        handler.onMessage("v/12/7", new byte[] {(byte) 0xFF, 0x01});

        assertThat(count("bad_topic")).isEqualTo(2);
        assertThat(count("decode_error")).isEqualTo(1);
    }

    @Test
    void batchGoesToHistoryOnlyEvenIfOlderThanLatest() {
        handler.onMessage("v/12/7", pos(7, NOW, LAT));
        drainHistory();
        live.drainDirty();

        Pos first = Pos.newBuilder().setVeh(7).setTs((int) (NOW - 600)).setLat(LAT).setLon(LON).build();
        PosBatch batch = PosBatch.newBuilder().setFirst(first)
                .addDts(15).addDlat(1_000).addDlon(0).addSpd(25).addHdg(0)
                .build();
        handler.onMessage("v/12/7/b", batch.toByteArray());

        assertThat(drainHistory()).extracting(Fix::ts).containsExactly(NOW - 600, NOW - 585);
        assertThat(live.get(7).ts()).isEqualTo(NOW);
        assertThat(live.drainDirty()).isEmpty();
    }

    @Test
    void fullHistoryQueueDropsAndCounts() {
        for (int i = 0; i < 5; i++) {
            handler.onMessage("v/12/7", pos(7, NOW - 10 + i, LAT));
        }

        assertThat(history.size()).isEqualTo(3);
        assertThat(registry.counter("ingest.history.dropped").count()).isEqualTo(2);
        assertThat(live.get(7).ts()).isEqualTo(NOW - 6);
    }
}
