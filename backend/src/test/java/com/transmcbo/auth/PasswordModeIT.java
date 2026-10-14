package com.transmcbo.auth;

import static org.assertj.core.api.Assertions.assertThat;

import com.hivemq.client.mqtt.datatypes.MqttQos;
import com.hivemq.client.mqtt.mqtt5.Mqtt5BlockingClient;
import com.hivemq.client.mqtt.mqtt5.Mqtt5Client;
import com.hivemq.client.mqtt.mqtt5.exceptions.Mqtt5PubAckException;
import com.transmcbo.ingest.LivePositions;
import com.transmcbo.proto.DriverLogin;
import com.transmcbo.proto.Pos;
import com.transmcbo.proto.Token;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.images.builder.Transferable;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * transmcbo.auth.mode=password against an EMQX set up like EMQX Serverless:
 * built-in database users + per-username ACL (what DEPLOY.md asks to configure in its console).
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "transmcbo.auth.mode=password",
        "transmcbo.auth.driver.username=chofer", "transmcbo.auth.driver.password=drv-secret",
        "transmcbo.auth.passenger.username=pasajero", "transmcbo.auth.passenger.password=pas-secret",
        "transmcbo.auth.backend.username=backend", "transmcbo.auth.backend.password=be-secret",
        "transmcbo.auth.client-broker.host=broker.example.com",
        "transmcbo.auth.client-broker.port=8883",
        "transmcbo.auth.client-broker.tls=true",
})
@DirtiesContext
@Testcontainers
class PasswordModeIT {

    static final String USERS = "user_id,password,is_superuser\nbackend,be-secret,false\nchofer,drv-secret,false\npasajero,pas-secret,false\n";
    static final String ACL = """
            {allow, {username, "backend"}, subscribe, ["v/#", "$share/backend/v/#"]}.
            {allow, {username, "chofer"}, publish, ["v/#"]}.
            {allow, {username, "pasajero"}, subscribe, ["v/+/+"]}.
            {deny, all}.
            """;

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgis = new PostgreSQLContainer(
            DockerImageName.parse("postgis/postgis:16-3.4").asCompatibleSubstituteFor("postgres"));

    @Container
    @ServiceConnection(name = "redis")
    static GenericContainer<?> redis = new GenericContainer<>("redis:7.4.1-alpine").withExposedPorts(6379);

    @Container
    static GenericContainer<?> emqx = new GenericContainer<>("emqx/emqx:5.8.6")
            .withExposedPorts(1883)
            .withCopyToContainer(Transferable.of(USERS.getBytes(StandardCharsets.UTF_8), 0644), "/opt/emqx/etc/users.csv")
            .withCopyToContainer(Transferable.of(ACL.getBytes(StandardCharsets.UTF_8), 0644), "/opt/emqx/etc/test-acl.conf")
            .withEnv(Map.of(
                    "EMQX_AUTHENTICATION__1__MECHANISM", "password_based",
                    "EMQX_AUTHENTICATION__1__BACKEND", "built_in_database",
                    "EMQX_AUTHENTICATION__1__USER_ID_TYPE", "username",
                    "EMQX_AUTHENTICATION__1__BOOTSTRAP_FILE", "/opt/emqx/etc/users.csv",
                    "EMQX_AUTHENTICATION__1__BOOTSTRAP_TYPE", "plain",
                    "EMQX_AUTHORIZATION__NO_MATCH", "deny",
                    "EMQX_AUTHORIZATION__SOURCES", "[{type = file, enable = true, path = \"/opt/emqx/etc/test-acl.conf\"}]"))
            .waitingFor(Wait.forLogMessage(".*EMQX .* is running now.*", 1));

    @DynamicPropertySource
    static void mqtt(DynamicPropertyRegistry r) {
        r.add("transmcbo.mqtt.host", emqx::getHost);
        r.add("transmcbo.mqtt.port", () -> emqx.getMappedPort(1883));
    }

    @LocalServerPort
    int port;
    @Autowired
    JdbcTemplate jdbc;
    @Autowired
    LivePositions live;

    final HttpClient http = HttpClient.newHttpClient();

    Token post(String path, byte[] body) throws Exception {
        HttpResponse<byte[]> res = http.send(HttpRequest.newBuilder(URI.create("http://localhost:" + port + path))
                .POST(HttpRequest.BodyPublishers.ofByteArray(body)).build(), HttpResponse.BodyHandlers.ofByteArray());
        assertThat(res.statusCode()).isEqualTo(200);
        return Token.parseFrom(res.body());
    }

    Mqtt5BlockingClient connect(String id, Token t) {
        Mqtt5BlockingClient c = Mqtt5Client.builder().identifier(id)
                .serverHost(emqx.getHost()).serverPort(emqx.getMappedPort(1883)).buildBlocking();
        c.connectWith().simpleAuth().username(t.getUsername()).password(t.getJwt().getBytes(StandardCharsets.UTF_8))
                .applySimpleAuth().send();
        return c;
    }

    @Test
    void tokensCarryRoleCredentialsAndTheBrokerForTheApps() throws Exception {
        jdbc.update("INSERT INTO vehicle (id, pin_hash) VALUES (9, ?) ON CONFLICT (id) DO UPDATE SET pin_hash = EXCLUDED.pin_hash",
                PinHasher.hash("1234"));

        Token driver = post("/auth/chofer", DriverLogin.newBuilder().setVeh(9).setPin("1234").setLine("santa-rosa").build().toByteArray());
        Token passenger = post("/auth/pasajero", new byte[0]);

        assertThat(driver.getUsername()).isEqualTo("chofer");
        assertThat(driver.getJwt()).isEqualTo("drv-secret");
        assertThat(passenger.getUsername()).isEqualTo("pasajero");
        assertThat(passenger.getMqttHost()).isEqualTo("broker.example.com");
        assertThat(passenger.getMqttPort()).isEqualTo(8883);
        assertThat(passenger.getMqttTls()).isTrue();
        assertThat(passenger.getExp()).isGreaterThan((int) (System.currentTimeMillis() / 1000 + 23 * 3600));
    }

    @Test
    void backendIngestsWithPasswordAuthAndThePassengerCannotPublish() throws Exception {
        Token driverToken = post("/auth/chofer", DriverLogin.newBuilder().setVeh(9).setPin("1234").setLine("santa-rosa").build().toByteArray());
        Mqtt5BlockingClient driver = connect("drv-9", driverToken);
        long deadline = System.nanoTime() + Duration.ofSeconds(15).toNanos();
        while (live.get(9) == null && System.nanoTime() < deadline) {
            Pos pos = Pos.newBuilder().setVeh(9).setTs((int) (System.currentTimeMillis() / 1000))
                    .setLat(10_642_700).setLon(-71_612_500).setSpd(20).build();
            driver.publishWith().topic("v/santa-rosa/9").qos(MqttQos.AT_MOST_ONCE).retain(true).payload(pos.toByteArray()).send();
            Thread.sleep(200);
        }
        driver.disconnect();
        assertThat(live.get(9)).as("backend authenticated with its password and received the position").isNotNull();

        Mqtt5BlockingClient passenger = connect("pas-1", post("/auth/pasajero", new byte[0]));
        boolean denied;
        try {
            denied = passenger.publishWith().topic("v/santa-rosa/9").qos(MqttQos.AT_LEAST_ONCE).payload(new byte[] {1})
                    .send().getError().isPresent();
        } catch (Mqtt5PubAckException e) {
            denied = true;
        }
        passenger.disconnect();
        assertThat(denied).isTrue();
    }
}
