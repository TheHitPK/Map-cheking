package com.transmcbo.api;

import static org.assertj.core.api.Assertions.assertThat;

import com.transmcbo.proto.Lines;
import java.io.ByteArrayInputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.zip.GZIPInputStream;
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

/** gzip only above 1 KB. Single test: /lineas is cached, so the big list must be inserted before the first call. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = "transmcbo.mqtt.enabled=false")
@Testcontainers
class CompressionIT {

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

    HttpResponse<byte[]> get(String path) throws Exception {
        return http.send(HttpRequest.newBuilder(URI.create("http://localhost:" + port + path))
                .header("Accept-Encoding", "gzip").build(), HttpResponse.BodyHandlers.ofByteArray());
    }

    @Test
    void largeProtobufIsGzippedAndSmallIsNot() throws Exception {
        for (int i = 0; i < 80; i++) {
            jdbc.update("INSERT INTO line (id, name) VALUES (?, ?)", "linea-" + i, "Línea de prueba número " + i);
        }

        HttpResponse<byte[]> big = get("/lineas");
        assertThat(big.headers().firstValue("Content-Encoding")).hasValue("gzip");
        Lines lines = Lines.parseFrom(new GZIPInputStream(new ByteArrayInputStream(big.body())).readAllBytes());
        assertThat(lines.getLinesCount()).isGreaterThanOrEqualTo(86);
        assertThat(big.body().length).as("compressed size").isLessThan(lines.getSerializedSize());

        HttpResponse<byte[]> small = get("/lineas/santa-rosa/cercanos?lat=10.6427&lon=-71.6125");
        assertThat(small.statusCode()).isEqualTo(200);
        assertThat(small.headers().firstValue("Content-Encoding")).isEmpty();
    }
}
