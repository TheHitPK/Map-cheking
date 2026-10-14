package com.transmcbo.ingest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.transmcbo.proto.Pos;
import com.transmcbo.proto.PosBatch;
import java.util.List;
import org.junit.jupiter.api.Test;

class PosBatchDecoderTest {

    static final Pos FIRST = Pos.newBuilder().setVeh(7).setTs(1000).setLat(10_642_700).setLon(-71_612_500).setSpd(20).setHdg(45).build();

    @Test
    void rebuildsAbsolutePointsFromDeltas() {
        PosBatch batch = PosBatch.newBuilder().setFirst(FIRST)
                .addAllDts(List.of(15, 15)).addAllDlat(List.of(300, -100)).addAllDlon(List.of(-50, 0))
                .addAllSpd(List.of(25, 0)).addAllHdg(List.of(90, 0))
                .build();

        List<Fix> fixes = PosBatchDecoder.decode("12", batch);

        assertThat(fixes).containsExactly(
                new Fix("12", 7, 1000, 10_642_700, -71_612_500, 20, 45),
                new Fix("12", 7, 1015, 10_643_000, -71_612_550, 25, 90),
                new Fix("12", 7, 1030, 10_642_900, -71_612_550, 0, 0));
    }

    @Test
    void firstOnlyBatchYieldsOnePoint() {
        assertThat(PosBatchDecoder.decode("12", PosBatch.newBuilder().setFirst(FIRST).build())).hasSize(1);
    }

    @Test
    void rejectsMismatchedArrays() {
        PosBatch batch = PosBatch.newBuilder().setFirst(FIRST).addDts(15).addDlat(1).build();
        assertThatThrownBy(() -> PosBatchDecoder.decode("12", batch)).isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void rejectsMissingFirst() {
        assertThatThrownBy(() -> PosBatchDecoder.decode("12", PosBatch.getDefaultInstance()))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
