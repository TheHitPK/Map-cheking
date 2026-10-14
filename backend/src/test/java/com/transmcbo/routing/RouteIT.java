package com.transmcbo.routing;

import static org.assertj.core.api.Assertions.assertThat;

import com.transmcbo.ingest.Fix;
import com.transmcbo.ingest.Geo;
import com.transmcbo.ingest.LivePositions;
import com.transmcbo.live.RedisFlusher;
import com.transmcbo.proto.Route;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = "transmcbo.mqtt.enabled=false")
@Testcontainers
class RouteIT {

    static final String OSM = "src/test/resources/osm/maracaibo-centro.osm.pbf";
    // Both inside the downtown fixture (-71.635..-71.600, 10.635..10.665)
    static final int VEH_LAT = 10_642_000, VEH_LON = -71_628_000;
    static final double USER_LAT = 10.655, USER_LON = -71.608;

    static final Path GRAPH_DIR;

    static {
        try {
            GRAPH_DIR = Files.createTempDirectory("gh-test").resolve("graph");
        } catch (IOException e) {
            throw new ExceptionInInitializerError(e);
        }
    }

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgis = new PostgreSQLContainer(
            DockerImageName.parse("postgis/postgis:16-3.4").asCompatibleSubstituteFor("postgres"));

    @Container
    @ServiceConnection(name = "redis")
    static GenericContainer<?> redis = new GenericContainer<>("redis:7.4.1-alpine").withExposedPorts(6379);

    @DynamicPropertySource
    static void routing(DynamicPropertyRegistry r) {
        r.add("transmcbo.routing.osm-file", () -> OSM);
        r.add("transmcbo.routing.graph-dir", GRAPH_DIR::toString);
    }

    @LocalServerPort
    int port;
    @Autowired
    LivePositions live;
    @Autowired
    RedisFlusher flusher;

    final HttpClient http = HttpClient.newHttpClient();

    HttpResponse<byte[]> get(String query) throws IOException, InterruptedException {
        return http.send(HttpRequest.newBuilder(URI.create("http://localhost:" + port + "/ruta?" + query)).build(),
                HttpResponse.BodyHandlers.ofByteArray());
    }

    void vehicleAt(int veh, int lat, int lon) {
        live.putIf(new Fix("santa-rosa", veh, System.currentTimeMillis() / 1000, lat, lon, 25, 30), (p, n) -> true);
        flusher.flush();
    }

    static double metres(double lat1, double lon1, double lat2, double lon2) {
        return Geo.distanceMeters((int) Math.round(lat1 * 1e6), (int) Math.round(lon1 * 1e6),
                (int) Math.round(lat2 * 1e6), (int) Math.round(lon2 * 1e6));
    }

    @Test
    void routesFromVehicleToPassenger() throws Exception {
        vehicleAt(201, VEH_LAT, VEH_LON);

        HttpResponse<byte[]> res = get("veh=201&lat=" + USER_LAT + "&lon=" + USER_LON);

        assertThat(res.statusCode()).isEqualTo(200);
        assertThat(res.body().length).as("payload bytes").isLessThan(2048);
        Route route = Route.parseFrom(res.body());
        double[] pts = Polyline.decode(route.getPolyline());
        assertThat(pts.length).isGreaterThanOrEqualTo(4);
        assertThat(metres(pts[0], pts[1], VEH_LAT / 1e6, VEH_LON / 1e6)).as("starts at vehicle").isLessThan(100);
        assertThat(metres(pts[pts.length - 2], pts[pts.length - 1], USER_LAT, USER_LON)).as("ends at passenger").isLessThan(100);
        double straight = metres(VEH_LAT / 1e6, VEH_LON / 1e6, USER_LAT, USER_LON);
        assertThat((double) route.getDistM()).isBetween(straight, straight * 2.5);
        assertThat(route.getTimeS()).isPositive();
    }

    @Test
    void secondRequestInSameCellIsServedFromCache() throws Exception {
        vehicleAt(202, VEH_LAT, VEH_LON);
        byte[] first = get("veh=202&lat=" + USER_LAT + "&lon=" + USER_LON).body();

        // Vehicle moves, passenger stays in the same geohash7 cell: cached route within the 60 s TTL
        vehicleAt(202, VEH_LAT + 2_000, VEH_LON);
        byte[] second = get("veh=202&lat=" + (USER_LAT + 0.00001) + "&lon=" + USER_LON).body();

        assertThat(second).isEqualTo(first);
    }

    @Test
    void unknownVehicleIs404AndOutsideAreaIs400() throws Exception {
        assertThat(get("veh=999&lat=" + USER_LAT + "&lon=" + USER_LON).statusCode()).isEqualTo(404);
        assertThat(get("veh=201&lat=8.0&lon=-66.0").statusCode()).isEqualTo(400);
        assertThat(get("veh=0&lat=" + USER_LAT + "&lon=" + USER_LON).statusCode()).isEqualTo(400);
    }

    @Test
    void precompiledGraphLoadsWithoutOsmFile() {
        Router fromDisk = new Router(new RoutingProperties("does-not-exist.osm.pbf", GRAPH_DIR.toString()));
        try {
            assertThat(fromDisk.available()).isTrue();
            assertThat(fromDisk.route(VEH_LAT / 1e6, VEH_LON / 1e6, Double.NaN, USER_LAT, USER_LON)).isPresent();
        } finally {
            fromDisk.close();
        }
    }
}
