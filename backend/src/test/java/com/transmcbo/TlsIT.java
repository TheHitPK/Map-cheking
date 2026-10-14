package com.transmcbo;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hivemq.client.mqtt.MqttClientSslConfig;
import com.hivemq.client.mqtt.datatypes.MqttQos;
import com.hivemq.client.mqtt.mqtt5.Mqtt5BlockingClient;
import com.hivemq.client.mqtt.mqtt5.Mqtt5Client;
import com.transmcbo.ingest.LivePositions;
import com.transmcbo.proto.Pos;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.security.KeyStore;
import java.security.cert.CertificateFactory;
import java.time.Duration;
import java.util.Map;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLHandshakeException;
import javax.net.ssl.TrustManagerFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
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
import org.testcontainers.images.builder.Transferable;

/** Backend with the `tls` profile: HTTPS server and MQTT over TLS to an EMQX TLS listener (test certificates). */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "spring.profiles.active=tls",
        "spring.ssl.bundle.pem.server.keystore.certificate=classpath:tls/server.crt",
        "spring.ssl.bundle.pem.server.keystore.private-key=classpath:tls/server.key",
        "spring.ssl.bundle.pem.mqtt.truststore.certificate=classpath:tls/ca.crt",
})
@DirtiesContext
@Testcontainers
class TlsIT {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgis = new PostgreSQLContainer(
            DockerImageName.parse("postgis/postgis:16-3.4").asCompatibleSubstituteFor("postgres"));

    @Container
    @ServiceConnection(name = "redis")
    static GenericContainer<?> redis = new GenericContainer<>("redis:7.4.1-alpine").withExposedPorts(6379);

    static final String CERTS = "/opt/emqx/etc/test-certs/";

    /** World-readable copy: EMQX runs as a non-root user. */
    static Transferable resource(String name) {
        try (InputStream in = TlsIT.class.getResourceAsStream("/tls/" + name)) {
            return Transferable.of(in.readAllBytes(), 0644);
        } catch (java.io.IOException e) {
            throw new java.io.UncheckedIOException(e);
        }
    }

    @Container
    static GenericContainer<?> emqx = new GenericContainer<>("emqx/emqx:5.8.6")
            .withExposedPorts(8883)
            .withCopyToContainer(resource("server.crt"), CERTS + "server.crt")
            .withCopyToContainer(resource("server.key"), CERTS + "server.key")
            .withCopyToContainer(resource("ca.crt"), CERTS + "ca.crt")
            .withEnv(Map.of(
                    "EMQX_LISTENERS__SSL__DEFAULT__BIND", "0.0.0.0:8883",
                    "EMQX_LISTENERS__SSL__DEFAULT__SSL_OPTIONS__CERTFILE", CERTS + "server.crt",
                    "EMQX_LISTENERS__SSL__DEFAULT__SSL_OPTIONS__KEYFILE", CERTS + "server.key",
                    "EMQX_LISTENERS__SSL__DEFAULT__SSL_OPTIONS__CACERTFILE", CERTS + "ca.crt",
                    "EMQX_LISTENERS__SSL__DEFAULT__SSL_OPTIONS__VERSIONS", "[\"tlsv1.3\",\"tlsv1.2\"]",
                    "EMQX_LISTENERS__TCP__DEFAULT__ENABLE", "false"))
            .waitingFor(Wait.forLogMessage(".*EMQX .* is running now.*", 1));

    @DynamicPropertySource
    static void mqtt(DynamicPropertyRegistry r) {
        r.add("transmcbo.mqtt.host", () -> "localhost"); // must match the certificate SAN
        r.add("transmcbo.mqtt.port", () -> emqx.getMappedPort(8883));
    }

    @LocalServerPort
    int port;
    @Autowired
    LivePositions live;

    static TrustManagerFactory trust(String resource) throws Exception {
        KeyStore ks = KeyStore.getInstance(KeyStore.getDefaultType());
        ks.load(null, null);
        try (InputStream in = TlsIT.class.getResourceAsStream("/tls/" + resource)) {
            ks.setCertificateEntry("ca", CertificateFactory.getInstance("X.509").generateCertificate(in));
        }
        TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init(ks);
        return tmf;
    }

    static Mqtt5BlockingClient client(String id, TrustManagerFactory tmf) {
        return Mqtt5Client.builder().identifier(id).serverHost("localhost").serverPort(emqx.getMappedPort(8883))
                .sslConfig(MqttClientSslConfig.builder().trustManagerFactory(tmf).build())
                .buildBlocking();
    }

    @Test
    void backendReceivesPositionsOverTls() throws Exception {
        Mqtt5BlockingClient driver = client("driver-tls", trust("ca.crt"));
        driver.connect();
        long deadline = System.nanoTime() + Duration.ofSeconds(15).toNanos();
        while (live.get(77) == null && System.nanoTime() < deadline) {
            Pos pos = Pos.newBuilder().setVeh(77).setTs((int) (System.currentTimeMillis() / 1000))
                    .setLat(10_642_700).setLon(-71_612_500).setSpd(20).build();
            driver.publishWith().topic("v/santa-rosa/77").qos(MqttQos.AT_MOST_ONCE).retain(true).payload(pos.toByteArray()).send();
            Thread.sleep(200);
        }
        driver.disconnect();
        assertThat(live.get(77)).isNotNull();
    }

    @Test
    void untrustedCertificateIsRejected() throws Exception {
        Mqtt5BlockingClient stranger = client("stranger", trust("other-ca.crt"));
        assertThatThrownBy(stranger::connect).hasCauseInstanceOf(SSLHandshakeException.class)
                .hasMessageContaining("PKIX path building failed");
    }

    @Test
    void httpsServesTheApi() throws Exception {
        SSLContext ssl = SSLContext.getInstance("TLS");
        ssl.init(null, trust("ca.crt").getTrustManagers(), null);
        HttpClient http = HttpClient.newBuilder().sslContext(ssl).build();

        HttpResponse<byte[]> res = http.send(HttpRequest.newBuilder(URI.create("https://localhost:" + port + "/lineas")).build(),
                HttpResponse.BodyHandlers.ofByteArray());

        assertThat(res.statusCode()).isEqualTo(200);
        assertThat(res.sslSession()).hasValueSatisfying(s -> assertThat(s.getProtocol()).startsWith("TLSv1."));
    }
}
