package com.transmcbo.ingest;

import static org.assertj.core.api.Assertions.assertThat;

import com.hivemq.client.mqtt.datatypes.MqttQos;
import com.hivemq.client.mqtt.mqtt5.Mqtt5BlockingClient;
import com.hivemq.client.mqtt.mqtt5.Mqtt5Client;
import com.transmcbo.auth.TokenService;
import com.transmcbo.proto.Pos;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

/** Backend token lives 12 s (EMQX kicks it at exp); rotation every 9 s must not lose any message. */
@SpringBootTest(properties = "transmcbo.auth.backend-token-ttl=12s")
@DirtiesContext
@Testcontainers
class MqttRotationIT {

    static final String SECRET = "rotation-secret-0123456789abcdef-0123456789";

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
            .withEnv(Map.of(
                    "EMQX_AUTHENTICATION__1__MECHANISM", "jwt",
                    "EMQX_AUTHENTICATION__1__FROM", "password",
                    "EMQX_AUTHENTICATION__1__USE_JWKS", "false",
                    "EMQX_AUTHENTICATION__1__ALGORITHM", "hmac-based",
                    "EMQX_AUTHENTICATION__1__SECRET", SECRET,
                    "EMQX_AUTHENTICATION__1__SECRET_BASE64_ENCODED", "false",
                    "EMQX_AUTHENTICATION__1__DISCONNECT_AFTER_EXPIRE", "true",
                    "EMQX_AUTHORIZATION__NO_MATCH", "deny",
                    "EMQX_AUTHORIZATION__SOURCES", "[]"))
            .waitingFor(Wait.forLogMessage(".*EMQX .* is running now.*", 1));

    @DynamicPropertySource
    static void props(DynamicPropertyRegistry r) {
        r.add("transmcbo.mqtt.host", emqx::getHost);
        r.add("transmcbo.mqtt.port", () -> emqx.getMappedPort(1883));
        r.add("transmcbo.auth.jwt-secret", () -> SECRET);
    }

    @Autowired
    TokenService tokens;
    @Autowired
    MeterRegistry registry;

    double received() {
        return registry.find("ingest.msgs").counters().stream().mapToDouble(Counter::count).sum();
    }

    @Test
    void noMessageIsLostAcrossTokenRotations() throws InterruptedException {
        Mqtt5BlockingClient driver = Mqtt5Client.builder().identifier("driver-rot")
                .serverHost(emqx.getHost()).serverPort(emqx.getMappedPort(1883)).buildBlocking();
        driver.connectWith().simpleAuth().username("veh:5")
                .password(tokens.driver("santa-rosa", 5).getJwt().getBytes(StandardCharsets.UTF_8)).applySimpleAuth().send();

        // Wait until the backend is subscribed (first message gets through).
        long deadline = System.nanoTime() + Duration.ofSeconds(15).toNanos();
        while (received() == 0 && System.nanoTime() < deadline) {
            driver.publishWith().topic("v/santa-rosa/5").qos(MqttQos.AT_LEAST_ONCE).payload(pos(0)).send();
            Thread.sleep(200);
        }
        double before = received();
        assertThat(before).isPositive();

        int sent = 0;
        long end = System.nanoTime() + Duration.ofSeconds(25).toNanos(); // > 2 rotations, > 2 token lifetimes
        while (System.nanoTime() < end) {
            driver.publishWith().topic("v/santa-rosa/5").qos(MqttQos.AT_LEAST_ONCE).payload(pos(++sent)).send();
            Thread.sleep(100);
        }
        Thread.sleep(1000);
        driver.disconnect();

        assertThat(registry.counter("mqtt.token.rotations").count()).isGreaterThanOrEqualTo(2);
        assertThat(received() - before).as("messages received by the backend").isEqualTo(sent);
    }

    static byte[] pos(int i) {
        return Pos.newBuilder().setVeh(5).setTs((int) (System.currentTimeMillis() / 1000))
                .setLat(10_642_700 + i).setLon(-71_612_500).setSpd(20).build().toByteArray();
    }
}
