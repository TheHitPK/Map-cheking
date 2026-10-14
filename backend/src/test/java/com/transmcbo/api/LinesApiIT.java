package com.transmcbo.api;

import static org.assertj.core.api.Assertions.assertThat;

import com.transmcbo.ingest.Fix;
import com.transmcbo.ingest.LivePositions;
import com.transmcbo.live.RedisFlusher;
import com.transmcbo.proto.Line;
import com.transmcbo.proto.Lines;
import com.transmcbo.proto.Nearby;
import com.transmcbo.proto.NearbyList;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = "transmcbo.mqtt.enabled=false")
@Testcontainers
class LinesApiIT {

    static final int LAT = 10_642_700, LON = -71_612_500; // passenger
    static final int M100 = 900;                           // ~100 m of latitude

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgis = new PostgreSQLContainer(
            DockerImageName.parse("postgis/postgis:16-3.4").asCompatibleSubstituteFor("postgres"));

    @Container
    @ServiceConnection(name = "redis")
    static GenericContainer<?> redis = new GenericContainer<>("redis:7.4.1-alpine").withExposedPorts(6379);

    @LocalServerPort
    int port;
    @Autowired
    LivePositions live;
    @Autowired
    RedisFlusher flusher;

    final HttpClient http = HttpClient.newHttpClient();

    HttpResponse<byte[]> get(String path, String ifNoneMatch) throws IOException, InterruptedException {
        HttpRequest.Builder req = HttpRequest.newBuilder(URI.create("http://localhost:" + port + path));
        if (ifNoneMatch != null) {
            req.header("If-None-Match", ifNoneMatch);
        }
        return http.send(req.build(), HttpResponse.BodyHandlers.ofByteArray());
    }

    String nearbyPath(String line) {
        return "/lineas/" + line + "/cercanos?lat=" + LAT / 1e6 + "&lon=" + LON / 1e6;
    }

    /** Vehicle north of the passenger, moving from {@code fromM} to {@code toM} hundreds of metres. */
    void vehicle(String line, int veh, int fromM, int toM) {
        long now = System.currentTimeMillis() / 1000;
        live.putIf(new Fix(line, veh, now - 5, LAT + fromM * M100, LON, 30, 90), (p, n) -> true);
        flusher.flush();
        live.putIf(new Fix(line, veh, now, LAT + toM * M100, LON, 30, 90), (p, n) -> true);
        flusher.flush();
    }

    @Test
    void linesSupportsEtag() throws Exception {
        HttpResponse<byte[]> first = get("/lineas", null);
        assertThat(first.statusCode()).isEqualTo(200);
        assertThat(first.headers().firstValue("Content-Type")).hasValue("application/x-protobuf");
        assertThat(Lines.parseFrom(first.body()).getLinesList()).extracting(Line::getId).contains("santa-rosa");

        String etag = first.headers().firstValue("ETag").orElseThrow();
        HttpResponse<byte[]> second = get("/lineas", etag);
        assertThat(second.statusCode()).isEqualTo(304);
        assertThat(second.body()).isEmpty();
    }

    @Test
    void nearbyReturnsClosestThreeApproaching() throws Exception {
        vehicle("santa-rosa", 101, 7, 5);    // 500 m, approaching
        vehicle("santa-rosa", 102, 10, 8);   // 800 m, approaching
        vehicle("santa-rosa", 103, 14, 12);  // 1.2 km, approaching
        vehicle("santa-rosa", 104, 17, 15);  // 1.5 km, approaching but 4th
        vehicle("santa-rosa", 105, 1, 3);    // 300 m, moving away
        vehicle("bella-vista", 106, 4, 2);   // other line
        vehicle("santa-rosa", 107, 42, 40);  // 4 km, outside radius

        HttpResponse<byte[]> res = get(nearbyPath("santa-rosa"), null);

        assertThat(res.statusCode()).isEqualTo(200);
        NearbyList list = NearbyList.parseFrom(res.body());
        assertThat(list.getVehiclesList()).extracting(Nearby::getVeh).containsExactly(101, 102, 103);
        assertThat(list.getVehicles(0).getDistM()).isBetween(480, 520);
    }

    @Test
    void unknownLineIs404AndOutsideAreaIs400() throws Exception {
        assertThat(get(nearbyPath("no-existe"), null).statusCode()).isEqualTo(404);
        assertThat(get("/lineas/santa-rosa/cercanos?lat=8.0&lon=-66.0", null).statusCode()).isEqualTo(400);
    }
}
