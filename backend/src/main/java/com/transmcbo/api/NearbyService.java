package com.transmcbo.api;

import com.transmcbo.live.RedisFlusher;
import com.transmcbo.proto.Nearby;
import com.transmcbo.proto.NearbyList;
import java.util.List;
import java.util.Map;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.GeoResult;
import org.springframework.data.geo.GeoResults;
import org.springframework.data.geo.Point;
import org.springframework.data.redis.connection.DefaultStringRedisConnection;
import org.springframework.data.redis.connection.RedisGeoCommands.DistanceUnit;
import org.springframework.data.redis.connection.RedisGeoCommands.GeoLocation;
import org.springframework.data.redis.connection.RedisGeoCommands.GeoSearchCommandArgs;
import org.springframework.data.redis.connection.StringRedisConnection;
import org.springframework.data.redis.core.RedisCallback;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.domain.geo.GeoReference;
import org.springframework.stereotype.Service;

@Service
public class NearbyService {

    static final double RADIUS_M = 3000;
    static final int CANDIDATES = 10;
    static final int MAX_RESULTS = 3;

    private final StringRedisTemplate redis;

    public NearbyService(StringRedisTemplate redis) {
        this.redis = redis;
    }

    /** Up to 3 vehicles of {@code line} within 3 km that are coming towards the passenger, closest first. */
    public NearbyList find(String line, int userLat, int userLon) {
        GeoResults<GeoLocation<String>> results = redis.opsForGeo().search(
                RedisFlusher.geoKey(line),
                GeoReference.fromCoordinate(new Point(userLon / 1e6, userLat / 1e6)),
                new Distance(RADIUS_M, DistanceUnit.METERS),
                GeoSearchCommandArgs.newGeoSearchArgs().includeDistance().sortAscending().limit(CANDIDATES));
        NearbyList.Builder out = NearbyList.newBuilder();
        if (results == null || results.getContent().isEmpty()) {
            return out.build();
        }
        List<GeoResult<GeoLocation<String>>> hits = results.getContent();
        List<Object> hashes = redis.executePipelined((RedisCallback<Object>) conn -> {
            StringRedisConnection c = conn instanceof StringRedisConnection s ? s : new DefaultStringRedisConnection(conn);
            hits.forEach(h -> c.hGetAll(RedisFlusher.vehKey(Integer.parseUnsignedInt(h.getContent().getName()))));
            return null;
        });

        for (int i = 0; i < hits.size() && out.getVehiclesCount() < MAX_RESULTS; i++) {
            @SuppressWarnings("unchecked")
            Map<String, String> h = (Map<String, String>) hashes.get(i);
            if (h == null || h.isEmpty() || !line.equals(h.get("line"))) {
                continue; // expired hash or stale GEO member
            }
            int lat = Integer.parseInt(h.get("lat"));
            int lon = Integer.parseInt(h.get("lon"));
            int hdg = Integer.parseInt(h.get("hdg"));
            if (!ApproachFilter.approaching(lat, lon, Integer.parseInt(h.get("plat")), Integer.parseInt(h.get("plon")), hdg, userLat, userLon)) {
                continue;
            }
            out.addVehicles(Nearby.newBuilder()
                    .setVeh(Integer.parseUnsignedInt(hits.get(i).getContent().getName()))
                    .setTs((int) Long.parseLong(h.get("ts")))
                    .setLat(lat)
                    .setLon(lon)
                    .setSpd(Integer.parseInt(h.get("spd")))
                    .setHdg(hdg)
                    .setDistM((int) Math.round(hits.get(i).getDistance().getValue())));
        }
        return out.build();
    }
}
