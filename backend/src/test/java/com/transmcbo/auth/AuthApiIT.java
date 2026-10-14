package com.transmcbo.auth;

import static org.assertj.core.api.Assertions.assertThat;

import com.transmcbo.proto.DriverLogin;
import com.transmcbo.proto.Token;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.jdbc.core.JdbcTemplate;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = "transmcbo.mqtt.enabled=false")
@Testcontainers
class AuthApiIT {

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
    JdbcTemplate jdbc;

    final HttpClient http = HttpClient.newHttpClient();

    @BeforeEach
    void vehicle() {
        jdbc.update("INSERT INTO vehicle (id, pin_hash) VALUES (7, ?) ON CONFLICT (id) DO UPDATE SET pin_hash = EXCLUDED.pin_hash",
                PinHasher.hash("4821"));
    }

    HttpResponse<byte[]> post(String path, byte[] body) throws Exception {
        return http.send(HttpRequest.newBuilder(URI.create("http://localhost:" + port + path))
                .header("Content-Type", "application/x-protobuf")
                .POST(HttpRequest.BodyPublishers.ofByteArray(body)).build(), HttpResponse.BodyHandlers.ofByteArray());
    }

    static byte[] login(int veh, String pin, String line) {
        return DriverLogin.newBuilder().setVeh(veh).setPin(pin).setLine(line).build().toByteArray();
    }

    static String claims(Token t) {
        return new String(Base64.getUrlDecoder().decode(t.getJwt().split("\\.")[1]), StandardCharsets.UTF_8);
    }

    @Test
    void driverWithRightPinGetsScopedToken() throws Exception {
        HttpResponse<byte[]> res = post("/auth/chofer", login(7, "4821", "santa-rosa"));

        assertThat(res.statusCode()).isEqualTo(200);
        Token token = Token.parseFrom(res.body());
        assertThat(token.getExp()).isGreaterThan((int) (System.currentTimeMillis() / 1000));
        assertThat(claims(token)).contains("\"sub\":\"veh:7\"", "\"topic\":\"v/santa-rosa/7\"", "\"topic\":\"v/santa-rosa/7/b\"");
    }

    @Test
    void wrongPinUnknownVehicleOrLineAreRejected() throws Exception {
        assertThat(post("/auth/chofer", login(7, "0000", "santa-rosa")).statusCode()).isEqualTo(401);
        assertThat(post("/auth/chofer", login(99, "4821", "santa-rosa")).statusCode()).isEqualTo(401);
        assertThat(post("/auth/chofer", login(7, "4821", "no-existe")).statusCode()).isEqualTo(404);
        assertThat(post("/auth/chofer", new byte[] {(byte) 0xFF}).statusCode()).isEqualTo(400);
    }

    @Test
    void repeatedWrongPinsAreThrottled() throws Exception {
        jdbc.update("INSERT INTO vehicle (id, pin_hash) VALUES (8, ?) ON CONFLICT DO NOTHING", PinHasher.hash("1111"));
        for (int i = 0; i < LoginLimiter.MAX_PER_VEH; i++) {
            assertThat(post("/auth/chofer", login(8, "0000", "santa-rosa")).statusCode()).isEqualTo(401);
        }
        HttpResponse<byte[]> blocked = post("/auth/chofer", login(8, "1111", "santa-rosa"));

        assertThat(blocked.statusCode()).as("even with the right PIN").isEqualTo(429);
        assertThat(blocked.headers().firstValue("Retry-After")).hasValue("900");
    }

    @Test
    void passengerGetsReadOnlyToken() throws Exception {
        HttpResponse<byte[]> res = post("/auth/pasajero", new byte[0]);

        assertThat(res.statusCode()).isEqualTo(200);
        assertThat(claims(Token.parseFrom(res.body()))).contains("\"action\":\"subscribe\",\"topic\":\"v/+/+\"").doesNotContain("publish");
    }
}
