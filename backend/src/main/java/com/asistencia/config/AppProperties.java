package com.asistencia.config;

import java.time.Duration;
import java.time.ZoneId;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

@ConfigurationProperties("asistencia")
public record AppProperties(
        @DefaultValue("America/New_York") ZoneId zone,
        Auth auth,
        @DefaultValue Attendance attendance,
        @DefaultValue Cors cors) {

    public record Auth(String jwtSecret, @DefaultValue("12h") Duration tokenTtl, @DefaultValue BootstrapAdmin bootstrapAdmin) {

        public Auth {
            if (jwtSecret == null || jwtSecret.getBytes(java.nio.charset.StandardCharsets.UTF_8).length < 32) {
                throw new IllegalArgumentException("asistencia.auth.jwt-secret must be at least 32 bytes");
            }
        }
    }

    public record BootstrapAdmin(@DefaultValue("admin") String document, @DefaultValue("") String password) {
    }

    public record Attendance(
            @DefaultValue("50") double maxAccuracyMeters,
            @DefaultValue("2m") Duration deferredAfter,
            @DefaultValue("2m") Duration maxClockAhead,
            @DefaultValue("24h") Duration maxDeferral,
            /* An arrival without departure after this long no longer blocks a new arrival. */
            @DefaultValue("20h") Duration forgottenCheckoutAfter) {
    }

    public record Cors(@DefaultValue("http://localhost:*") List<String> allowedOrigins) {
    }
}
