package com.transmcbo.auth;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

@ConfigurationProperties("transmcbo.auth")
public record AuthProperties(
        String jwtSecret,
        @DefaultValue("1h") Duration tokenTtl,
        @DefaultValue("24h") Duration backendTokenTtl) {
}
