package com.transmcbo.ingest;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import java.util.Collection;
import java.util.concurrent.ArrayBlockingQueue;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/** Bounded buffer between ingest and the history writer. Never blocks the producer. */
@Component
public class HistoryQueue {

    private final ArrayBlockingQueue<Fix> queue;
    private final Counter dropped;

    public HistoryQueue(@Value("${transmcbo.ingest.history-capacity:10000}") int capacity, MeterRegistry registry) {
        this.queue = new ArrayBlockingQueue<>(capacity);
        this.dropped = registry.counter("ingest.history.dropped");
        registry.gauge("ingest.history.queue.size", queue, ArrayBlockingQueue::size);
    }

    public boolean offer(Fix fix) {
        boolean ok = queue.offer(fix);
        if (!ok) {
            dropped.increment();
        }
        return ok;
    }

    public int drainTo(Collection<? super Fix> sink, int max) {
        return queue.drainTo(sink, max);
    }

    public int size() {
        return queue.size();
    }
}
