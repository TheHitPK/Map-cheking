package com.transmcbo.ingest;

import static org.assertj.core.api.Assertions.assertThat;

import com.hivemq.client.mqtt.datatypes.MqttQos;
import com.hivemq.client.mqtt.mqtt5.Mqtt5BlockingClient;
import com.hivemq.client.mqtt.mqtt5.Mqtt5Client;
import com.transmcbo.proto.Pos;
import java.time.Duration;
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

@SpringBootTest
@DirtiesContext
@Testcontainers
class MqttIngestIT {

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
            .waitingFor(Wait.forLogMessage(".*EMQX .* is running now.*", 1));

    @DynamicPropertySource
    static void mqtt(DynamicPropertyRegistry r) {
        r.add("transmcbo.mqtt.host", emqx::getHost);
        r.add("transmcbo.mqtt.port", () -> emqx.getMappedPort(1883));
    }

    @Autowired
    LivePositions live;

    @Test
    void publishedPositionReachesLatest() throws InterruptedException {
        Mqtt5BlockingClient driver = Mqtt5Client.builder()
                .identifier("driver-test").serverHost(emqx.getHost()).serverPort(emqx.getMappedPort(1883))
                .buildBlocking();
        driver.connect();

        // The backend subscribes asynchronously; keep publishing until it is seen.
        long deadline = System.nanoTime() + Duration.ofSeconds(15).toNanos();
        while (live.get(42) == null && System.nanoTime() < deadline) {
            Pos pos = Pos.newBuilder().setVeh(42).setTs((int) (System.currentTimeMillis() / 1000))
                    .setLat(10_642_700).setLon(-71_612_500).setSpd(30).setHdg(45).build();
            driver.publishWith().topic("v/12/42").qos(MqttQos.AT_MOST_ONCE).retain(true).payload(pos.toByteArray()).send();
            Thread.sleep(200);
        }
        driver.disconnect();

        assertThat(live.get(42)).isNotNull();
        assertThat(live.get(42).line()).isEqualTo("12");
        assertThat(live.get(42).lat()).isEqualTo(10_642_700);
    }
}
