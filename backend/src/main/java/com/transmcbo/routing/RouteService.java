package com.transmcbo.routing;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.transmcbo.live.RedisFlusher;
import com.transmcbo.proto.Route;
import java.time.Duration;
import java.util.Map;
import java.util.Optional;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

@Service
public class RouteService {

    public enum Status { OK, VEHICLE_NOT_LIVE, NO_ROUTE, UNAVAILABLE }

    public record Result(Status status, Route route) {
    }

    static final int MOVING_KMH = 5; // below this the reported heading is noise

    private final Router router;
    private final StringRedisTemplate redis;
    /** Key: veh + geohash7 of the passenger. */
    private final Cache<String, Route> cache = Caffeine.newBuilder()
            .expireAfterWrite(Duration.ofSeconds(60))
            .maximumSize(10_000)
            .build();

    public RouteService(Router router, StringRedisTemplate redis) {
        this.router = router;
        this.redis = redis;
    }

    public Result route(int veh, double userLat, double userLon) {
        if (!router.available()) {
            return new Result(Status.UNAVAILABLE, null);
        }
        String key = Integer.toUnsignedString(veh) + ":" + Geohash.encode(userLat, userLon, 7);
        Route cached = cache.getIfPresent(key);
        if (cached != null) {
            return new Result(Status.OK, cached);
        }
        Map<String, String> h = redis.<String, String>opsForHash().entries(RedisFlusher.vehKey(veh));
        if (h.isEmpty()) {
            return new Result(Status.VEHICLE_NOT_LIVE, null);
        }
        double lat = Integer.parseInt(h.get("lat")) / 1e6;
        double lon = Integer.parseInt(h.get("lon")) / 1e6;
        double heading = Integer.parseInt(h.get("spd")) >= MOVING_KMH ? Integer.parseInt(h.get("hdg")) * 2.0 : Double.NaN;
        Optional<Route> route = router.route(lat, lon, heading, userLat, userLon);
        if (route.isEmpty()) {
            return new Result(Status.NO_ROUTE, null);
        }
        cache.put(key, route.get());
        return new Result(Status.OK, route.get());
    }
}
