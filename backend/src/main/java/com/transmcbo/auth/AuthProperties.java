package com.transmcbo.auth;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.ConstructorBinding;
import org.springframework.boot.context.properties.bind.DefaultValue;

/**
 * MQTT credentials handed out by /auth/*.
 * <ul>
 *   <li>{@code jwt} (default): short JWT with a per-vehicle ACL, for brokers with JWT auth (EMQX self-hosted).</li>
 *   <li>{@code password}: fixed username/password per role, for brokers without JWT auth (EMQX Serverless);
 *       the ACL is configured in the broker per role.</li>
 * </ul>
 */
@ConfigurationProperties("transmcbo.auth")
public record AuthProperties(
        String jwtSecret,
        Duration tokenTtl,
        Duration backendTokenTtl,
        Mode mode,
        Credentials driver,
        Credentials passenger,
        Credentials backend,
        Duration passwordTokenTtl,
        ClientBroker clientBroker) {

    public enum Mode { JWT, PASSWORD }

    public record Credentials(String username, String password) {
    }

    /** Broker the apps should use; empty host = keep the app's built-in default. */
    public record ClientBroker(@DefaultValue("") String host, @DefaultValue("0") int port, @DefaultValue("false") boolean tls) {
    }

    @ConstructorBinding
    public AuthProperties(
            String jwtSecret,
            @DefaultValue("1h") Duration tokenTtl,
            @DefaultValue("24h") Duration backendTokenTtl,
            @DefaultValue("jwt") Mode mode,
            Credentials driver,
            Credentials passenger,
            Credentials backend,
            @DefaultValue("24h") Duration passwordTokenTtl,
            @DefaultValue ClientBroker clientBroker) {
        this.jwtSecret = jwtSecret;
        this.tokenTtl = tokenTtl;
        this.backendTokenTtl = backendTokenTtl;
        this.mode = mode;
        this.driver = driver;
        this.passenger = passenger;
        this.backend = backend;
        this.passwordTokenTtl = passwordTokenTtl;
        this.clientBroker = clientBroker;
        if (mode == Mode.PASSWORD && (missing(driver) || missing(passenger) || missing(backend))) {
            throw new IllegalArgumentException("transmcbo.auth.mode=password needs driver, passenger and backend username/password");
        }
    }

    /** JWT mode with defaults (tests). */
    public AuthProperties(String jwtSecret, Duration tokenTtl, Duration backendTokenTtl) {
        this(jwtSecret, tokenTtl, backendTokenTtl, Mode.JWT, null, null, null, Duration.ofHours(24), new ClientBroker("", 0, false));
    }

    private static boolean missing(Credentials c) {
        return c == null || c.username() == null || c.username().isBlank() || c.password() == null || c.password().isBlank();
    }
}
