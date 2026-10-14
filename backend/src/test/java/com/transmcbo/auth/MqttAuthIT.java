package com.transmcbo.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hivemq.client.mqtt.MqttGlobalPublishFilter;
import com.hivemq.client.mqtt.datatypes.MqttQos;
import com.hivemq.client.mqtt.mqtt5.Mqtt5BlockingClient;
import com.hivemq.client.mqtt.mqtt5.Mqtt5Client;
import com.hivemq.client.mqtt.mqtt5.exceptions.Mqtt5ConnAckException;
import com.hivemq.client.mqtt.mqtt5.exceptions.Mqtt5PubAckException;
import com.hivemq.client.mqtt.mqtt5.exceptions.Mqtt5SubAckException;
import com.hivemq.client.mqtt.mqtt5.message.publish.Mqtt5Publish;
import com.transmcbo.proto.Token;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/** Same EMQX auth config as docker-compose.yml, checked against tokens from {@link TokenService}. */
@Testcontainers
class MqttAuthIT {

    static final String SECRET = "it-secret-0123456789abcdef-0123456789abcdef";

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

    static TokenService tokens(Instant now) {
        return new TokenService(new AuthProperties(SECRET, Duration.ofHours(1), Duration.ofHours(24)), Clock.fixed(now, ZoneOffset.UTC));
    }

    final TokenService tokens = tokens(Instant.now());

    static Mqtt5BlockingClient connect(Token token) {
        Mqtt5BlockingClient c = Mqtt5Client.builder().identifier(UUID.randomUUID().toString())
                .serverHost(emqx.getHost()).serverPort(emqx.getMappedPort(1883)).buildBlocking();
        c.connectWith().simpleAuth().username("u").password(token.getJwt().getBytes(StandardCharsets.UTF_8)).applySimpleAuth().send();
        return c;
    }

    static boolean canPublish(Mqtt5BlockingClient c, String topic) {
        try {
            return c.publishWith().topic(topic).qos(MqttQos.AT_LEAST_ONCE).payload(new byte[] {1}).send().getError().isEmpty();
        } catch (Mqtt5PubAckException e) {
            return false;
        }
    }

    static boolean canSubscribe(Mqtt5BlockingClient c, String filter) {
        try {
            c.subscribeWith().topicFilter(filter).qos(MqttQos.AT_MOST_ONCE).send();
            return true;
        } catch (Mqtt5SubAckException e) {
            return false;
        }
    }

    @Test
    void driverPublishesOnlyOnItsOwnTopics() {
        Mqtt5BlockingClient driver = connect(tokens.driver("santa-rosa", 7));

        assertThat(canPublish(driver, "v/santa-rosa/7")).isTrue();
        assertThat(canPublish(driver, "v/santa-rosa/7/b")).isTrue();
        assertThat(canPublish(driver, "v/santa-rosa/8")).isFalse();
        assertThat(canPublish(driver, "v/bella-vista/7")).isFalse();
        assertThat(canSubscribe(driver, "v/+/+")).isFalse();
        driver.disconnect();
    }

    @Test
    void passengerReadsLiveTopicsOnly() throws InterruptedException {
        Mqtt5BlockingClient passenger = connect(tokens.passenger());
        Mqtt5BlockingClient driver = connect(tokens.driver("santa-rosa", 7));

        assertThat(canPublish(passenger, "v/santa-rosa/7")).isFalse();
        assertThat(canSubscribe(passenger, "v/#")).isFalse();
        assertThat(canSubscribe(passenger, "v/santa-rosa/7/b")).isFalse();

        try (Mqtt5BlockingClient.Mqtt5Publishes inbox = passenger.publishes(MqttGlobalPublishFilter.SUBSCRIBED)) {
            assertThat(canSubscribe(passenger, "v/santa-rosa/7")).isTrue();
            assertThat(canPublish(driver, "v/santa-rosa/7")).isTrue();
            Optional<Mqtt5Publish> got = inbox.receive(5, TimeUnit.SECONDS);
            assertThat(got).isPresent();
            assertThat(got.get().getTopic().toString()).isEqualTo("v/santa-rosa/7");
        }
        driver.disconnect();
        passenger.disconnect();
    }

    @Test
    void backendCanUseSharedSubscription() {
        Mqtt5BlockingClient backend = connect(tokens.backend());
        assertThat(canSubscribe(backend, "$share/backend/v/#")).isTrue();
        assertThat(canPublish(backend, "v/santa-rosa/7")).isFalse();
        backend.disconnect();
    }

    @Test
    void expiredOrForeignTokensAreRejected() {
        Token expired = tokens(Instant.now().minus(Duration.ofHours(2))).driver("santa-rosa", 7);
        assertThatThrownBy(() -> connect(expired)).isInstanceOf(Mqtt5ConnAckException.class);

        Token foreign = new TokenService(new AuthProperties(SECRET + "x", Duration.ofHours(1), Duration.ofHours(1)),
                Clock.systemUTC()).driver("santa-rosa", 7);
        assertThatThrownBy(() -> connect(foreign)).isInstanceOf(Mqtt5ConnAckException.class);
    }
}
