package com.transmcbo.ingest;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.BiFunction;
import org.springframework.stereotype.Component;

/** Latest fix per vehicle (coalescing) plus the set of vehicles changed since the last flush. */
@Component
public class LivePositions {

    private final ConcurrentHashMap<Integer, Fix> latest = new ConcurrentHashMap<>();
    private final Set<Integer> dirty = ConcurrentHashMap.newKeySet();

    public Fix get(int veh) {
        return latest.get(veh);
    }

    /** Atomically replaces the fix if {@code accept(prev, next)} returns true. */
    public boolean putIf(Fix next, BiFunction<Fix, Fix, Boolean> accept) {
        boolean[] accepted = {false};
        latest.compute(next.veh(), (k, prev) -> {
            if (accept.apply(prev, next)) {
                accepted[0] = true;
                return next;
            }
            return prev;
        });
        if (accepted[0]) {
            dirty.add(next.veh());
        }
        return accepted[0];
    }

    public void remove(int veh) {
        if (latest.remove(veh) != null) {
            dirty.add(veh);
        }
    }

    /** Removes vehicles whose last fix is older than {@code minTs}; returns how many. */
    public int evictOlderThan(long minTs) {
        int n = 0;
        for (var e : latest.entrySet()) {
            if (e.getValue().ts() < minTs && latest.remove(e.getKey(), e.getValue())) {
                dirty.add(e.getKey());
                n++;
            }
        }
        return n;
    }

    /** Re-queues ids whose flush failed. */
    public void markDirty(Collection<Integer> vehs) {
        dirty.addAll(vehs);
    }

    /** Returns and clears the changed vehicle ids; absent ones in {@link #get} were removed. */
    public List<Integer> drainDirty() {
        List<Integer> out = new ArrayList<>(dirty.size());
        for (Iterator<Integer> it = dirty.iterator(); it.hasNext(); ) {
            out.add(it.next());
            it.remove();
        }
        return out;
    }
}
