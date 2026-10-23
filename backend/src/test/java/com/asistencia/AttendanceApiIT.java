package com.asistencia;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/** End to end through HTTP, security and PostgreSQL: supervisor sets up a site, a worker marks. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = {"asistencia.auth.bootstrap-admin.document=admin", "asistencia.auth.bootstrap-admin.password=admin-pass"})
@Testcontainers
class AttendanceApiIT {

    static final ZoneId ZONE = ZoneId.of("America/New_York"); // default asistencia.zone
    static final double LAT = 10.6427, LON = -71.6125;

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:16-alpine");

    @LocalServerPort
    int port;

    final HttpClient http = HttpClient.newHttpClient();
    final JsonMapper json = JsonMapper.builder().build();

    record Res(int status, JsonNode body, String raw) {
    }

    Res call(String method, String path, String token, Object body, String accept) throws IOException, InterruptedException {
        HttpRequest.Builder req = HttpRequest.newBuilder(URI.create("http://localhost:" + port + path))
                .header("Accept", accept)
                .method(method, body == null ? HttpRequest.BodyPublishers.noBody()
                        : HttpRequest.BodyPublishers.ofString(json.writeValueAsString(body)));
        if (body != null) {
            req.header("Content-Type", "application/json");
        }
        if (token != null) {
            req.header("Authorization", "Bearer " + token);
        }
        HttpResponse<String> res = http.send(req.build(), HttpResponse.BodyHandlers.ofString());
        JsonNode node = res.body().startsWith("{") || res.body().startsWith("[") ? json.readTree(res.body()) : null;
        return new Res(res.statusCode(), node, res.body());
    }

    Res call(String method, String path, String token, Object body) throws IOException, InterruptedException {
        return call(method, path, token, body, "application/json");
    }

    String login(String document, String password) throws Exception {
        Res r = call("POST", "/auth/login", null, java.util.Map.of("document", document, "password", password));
        assertThat(r.status()).isEqualTo(200);
        return r.body().get("token").asString();
    }

    java.util.Map<String, Object> mark(String type, double lat, double accuracy) {
        return java.util.Map.of("clientId", UUID.randomUUID().toString(), "type", type, "lat", lat, "lon", LON,
                "accuracyMeters", accuracy, "mocked", false, "capturedAt", Instant.now().toString());
    }

    @Test
    void supervisorSetsUpAndWorkerMarks() throws Exception {
        assertThat(call("POST", "/auth/login", null, java.util.Map.of("document", "admin", "password", "wrong")).status())
                .isEqualTo(401);
        String admin = login("admin", "admin-pass");

        long site = call("POST", "/worksites", admin, java.util.Map.of("name", "Obra Norte", "address", "Av. 5 de Julio",
                "lat", LAT, "lon", LON, "radiusMeters", 100)).body().get("id").asLong();
        Res worker = call("POST", "/employees", admin, java.util.Map.of("document", "V-12345678",
                "fullName", "Ana Pérez", "role", "WORKER", "password", "clave-123", "hourlyRateCents", 2400));
        assertThat(worker.status()).isEqualTo(201);
        long workerId = worker.body().get("id").asLong();
        assertThat(call("POST", "/employees", admin, java.util.Map.of("document", "v-12345678",
                "fullName", "Otra", "role", "WORKER", "password", "clave-123")).status()).isEqualTo(409);

        // Shift that started an hour ago (10 min grace) → arrival is LATE, departure now is EARLY_LEAVE.
        LocalTime start = LocalTime.now(ZONE).minusHours(1).truncatedTo(ChronoUnit.MINUTES);
        Res shift = call("PUT", "/schedules/" + workerId, admin, java.util.Map.of("worksiteId", site,
                "start", start.toString(), "end", start.plusHours(8).toString(),
                "days", java.util.List.of("MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"),
                "graceMinutes", 10));
        assertThat(shift.status()).isEqualTo(200);

        String token = login("V-12345678", "clave-123");
        assertThat(call("GET", "/worksites", token, null).status()).isEqualTo(403);
        assertThat(call("GET", "/me/today", null, null).status()).isEqualTo(401);

        Res today = call("GET", "/me/today", token, null);
        assertThat(today.body().get("next").asString()).isEqualTo("IN");
        assertThat(today.body().get("worksite").get("radiusMeters").asInt()).isEqualTo(100);

        Res outside = call("POST", "/me/marks", token, mark("IN", LAT + 0.003, 10));
        assertThat(outside.status()).isEqualTo(201);
        assertThat(outside.body().get("status").asString()).isEqualTo("REJECTED");
        assertThat(outside.body().get("rejection").asString()).isEqualTo("OUT_OF_ZONE");

        java.util.Map<String, Object> in = mark("IN", LAT + 0.0003, 10);
        Res arrival = call("POST", "/me/marks", token, in);
        assertThat(arrival.status()).isEqualTo(201);
        assertThat(arrival.body().get("status").asString()).isEqualTo("LATE");
        Res replay = call("POST", "/me/marks", token, in);
        assertThat(replay.status()).isEqualTo(200);
        assertThat(replay.body().get("id").asLong()).isEqualTo(arrival.body().get("id").asLong());

        assertThat(call("GET", "/me/today", token, null).body().get("next").asString()).isEqualTo("OUT");

        Res daily = call("GET", "/attendance/daily?date=" + LocalDate.now(ZONE), admin, null);
        JsonNode row = daily.body().get(0);
        assertThat(row.get("fullName").asString()).isEqualTo("Ana Pérez");
        assertThat(row.get("state").asString()).isEqualTo("LATE");
        assertThat(row.get("onSite").asBoolean()).isTrue();
        assertThat(row.get("rejectedAttempts").asInt()).isEqualTo(1);

        assertThat(call("POST", "/me/marks", token, mark("OUT", LAT, 8)).body().get("status").asString())
                .isEqualTo("EARLY_LEAVE");

        LocalDate d = LocalDate.now(ZONE);
        Res csv = call("GET", "/attendance/marks?from=" + d.minusDays(1) + "&to=" + d.plusDays(1), admin, null, "text/csv");
        assertThat(csv.status()).isEqualTo(200);
        assertThat(csv.raw()).contains("\"Ana Pérez\"", "OUT_OF_ZONE", "EARLY_LEAVE");

        // Payroll: this week is an estimate; last week (nothing worked) can be paid once.
        Res week = call("GET", "/payroll?date=" + d, admin, null);
        assertThat(week.status()).isEqualTo(200);
        assertThat(week.body().get("paid").asBoolean()).isFalse();
        JsonNode line = week.body().get("lines").get(0);
        assertThat(line.get("fullName").asString()).isEqualTo("Ana Pérez");
        assertThat(line.get("pay").get("hourlyRateCents").asInt()).isEqualTo(2400);
        assertThat(call("GET", "/payroll?date=" + d, token, null).status()).isEqualTo(403);

        LocalDate thisMonday = LocalDate.parse(week.body().get("periodStart").asString());
        assertThat(call("POST", "/payroll/" + thisMonday + "/pay", admin, java.util.Map.of("paidOn", d.toString())).status())
                .isEqualTo(400);
        LocalDate lastMonday = thisMonday.minusWeeks(1);
        Res paid = call("POST", "/payroll/" + lastMonday + "/pay", admin, java.util.Map.of("paidOn", d.toString()));
        assertThat(paid.status()).isEqualTo(200);
        assertThat(paid.body().get("paid").asBoolean()).isTrue();
        assertThat(call("POST", "/payroll/" + lastMonday + "/pay", admin, java.util.Map.of("paidOn", d.toString())).status())
                .isEqualTo(409);

        Res mine = call("GET", "/me/pay", token, null);
        assertThat(mine.status()).isEqualTo(200);
        assertThat(mine.body().get("hourlyRateCents").asInt()).isEqualTo(2400);
        assertThat(mine.body().get("current").get("periodStart").asString()).isEqualTo(thisMonday.toString());
        assertThat(mine.body().get("previous").get("paid").asBoolean()).isTrue();
        assertThat(call("GET", "/me/pay", admin, null).status()).isEqualTo(403);
    }
}
