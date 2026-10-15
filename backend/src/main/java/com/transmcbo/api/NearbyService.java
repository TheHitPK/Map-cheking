package com.transmcbo.api;

import com.transmcbo.api.ApproachFilter.Approach;
import com.transmcbo.live.RedisFlusher;
import com.transmcbo.proto.Nearby;
import com.transmcbo.proto.NearbyList;
import java.util.ArrayList;
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

    /** Widening search: the first radius with an approaching vehicle wins (long lines, few buses). */
    static final double[] RADII_M = {3_000, 8_000, 20_000};
    static final int CANDIDATES = 10;
    static final int MAX_RESULTS = 3;

    private final StringRedisTemplate redis;

    public NearbyService(StringRedisTemplate redis) {
        this.redis = redis;
    }

    /**
     * Up to 3 vehicles of {@code line}, closest first: those coming towards the passenger plus stopped ones
     * (no usable heading). The radius widens until one is approaching, so a stopped bus never hides a moving one.
     */
    public NearbyList find(String line, int userLat, int userLon) {
        List<Candidate> found = List.of();
        for (double radius : RADII_M) {
            found = candidates(line, userLat, userLon, radius); // each ring contains the previous one
            if (found.stream().anyMatch(Candidate::approaching)) {
                break;
            }
        }
        NearbyList.Builder out = NearbyList.newBuilder();
        found.stream().limit(MAX_RESULTS).forEach(c -> out.addVehicles(c.vehicle()));
        return out.build();
    }

    private record Candidate(Nearby vehicle, boolean approaching) {
    }

    /** Approaching or stopped vehicles within {@code radiusM}, closest first. */
    private List<Candidate> candidates(String line, int userLat, int userLon, double radiusM) {
        GeoResults<GeoLocation<String>> results = redis.opsForGeo().search(
                RedisFlusher.geoKey(line),
                GeoReference.fromCoordinate(new Point(userLon / 1e6, userLat / 1e6)),
                new Distance(radiusM, DistanceUnit.METERS),
                GeoSearchCommandArgs.newGeoSearchArgs().includeDistance().sortAscending().limit(CANDIDATES));
        if (results == null || results.getContent().isEmpty()) {
            return List.of();
        }
        List<GeoResult<GeoLocation<String>>> hits = results.getContent();
        List<Object> hashes = redis.executePipelined((RedisCallback<Object>) conn -> {
            StringRedisConnection c = conn instanceof StringRedisConnection s ? s : new DefaultStringRedisConnection(conn);
            hits.forEach(h -> c.hGetAll(RedisFlusher.vehKey(Integer.parseUnsignedInt(h.getContent().getName()))));
            return null;
        });

        List<Candidate> out = new ArrayList<>();
        for (int i = 0; i < hits.size(); i++) {
            @SuppressWarnings("unchecked")
            Map<String, String> h = (Map<String, String>) hashes.get(i);
            if (h == null || h.isEmpty() || !line.equals(h.get("line"))) {
                continue; // expired hash or stale GEO member
            }
            int lat = Integer.parseInt(h.get("lat"));
            int lon = Integer.parseInt(h.get("lon"));
            int spd = Integer.parseInt(h.get("spd"));
            int hdg = Integer.parseInt(h.get("hdg"));
            Approach approach = ApproachFilter.classify(
                    lat, lon, Integer.parseInt(h.get("plat")), Integer.parseInt(h.get("plon")), spd, hdg, userLat, userLon);
            if (approach == Approach.AWAY) {
                continue;
            }
            out.add(new Candidate(Nearby.newBuilder()
                    .setVeh(Integer.parseUnsignedInt(hits.get(i).getContent().getName()))
                    .setTs((int) Long.parseLong(h.get("ts")))
                    .setLat(lat)
                    .setLon(lon)
                    .setSpd(spd)
                    .setHdg(hdg)
                    .setDistM((int) Math.round(hits.get(i).getDistance().getValue()))
                    .build(), approach == Approach.APPROACHING));
        }
        return out;
    }
}
