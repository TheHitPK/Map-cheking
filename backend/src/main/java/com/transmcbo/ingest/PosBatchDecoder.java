package com.transmcbo.ingest;

import com.transmcbo.proto.PosBatch;
import java.util.ArrayList;
import java.util.List;

public final class PosBatchDecoder {

    private PosBatchDecoder() {
    }

    /** Rebuilds absolute fixes from the first point plus per-point deltas. */
    public static List<Fix> decode(String line, PosBatch batch) {
        if (!batch.hasFirst()) {
            throw new IllegalArgumentException("batch without first point");
        }
        int n = batch.getDtsCount();
        if (batch.getDlatCount() != n || batch.getDlonCount() != n || batch.getSpdCount() != n || batch.getHdgCount() != n) {
            throw new IllegalArgumentException("batch arrays differ in length");
        }
        List<Fix> out = new ArrayList<>(n + 1);
        Fix prev = Fix.of(line, batch.getFirst());
        out.add(prev);
        for (int i = 0; i < n; i++) {
            prev = new Fix(line, prev.veh(),
                    prev.ts() + batch.getDts(i),
                    prev.lat() + batch.getDlat(i),
                    prev.lon() + batch.getDlon(i),
                    batch.getSpd(i),
                    batch.getHdg(i));
            out.add(prev);
        }
        return out;
    }
}
