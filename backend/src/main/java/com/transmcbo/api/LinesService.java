package com.transmcbo.api;

import com.github.benmanes.caffeine.cache.Caffeine;
import com.github.benmanes.caffeine.cache.LoadingCache;
import com.transmcbo.proto.Line;
import com.transmcbo.proto.Lines;
import java.time.Duration;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

/** Active lines, encoded once and cached with their ETag. */
@Service
public class LinesService {

    public record Snapshot(byte[] body, String etag, Set<String> ids) {
    }

    private final JdbcTemplate jdbc;
    private final LoadingCache<Boolean, Snapshot> cache = Caffeine.newBuilder()
            .expireAfterWrite(Duration.ofMinutes(5))
            .build(k -> load());

    public LinesService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Snapshot get() {
        return cache.get(Boolean.TRUE);
    }

    private Snapshot load() {
        Lines lines = Lines.newBuilder()
                .addAllLines(jdbc.query("SELECT id, name FROM line WHERE active ORDER BY name",
                        (rs, i) -> Line.newBuilder().setId(rs.getString(1)).setName(rs.getString(2)).build()))
                .build();
        byte[] body = lines.toByteArray();
        Set<String> ids = lines.getLinesList().stream().map(Line::getId).collect(Collectors.toUnmodifiableSet());
        return new Snapshot(body, "\"" + DigestUtils.md5DigestAsHex(body) + "\"", ids);
    }
}
