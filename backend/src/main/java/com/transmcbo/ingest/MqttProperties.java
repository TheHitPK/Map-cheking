package com.transmcbo.ingest;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

@ConfigurationProperties("transmcbo.mqtt")
public record MqttProperties(
        @DefaultValue("true") boolean enabled,
        @DefaultValue("localhost") String host,
        @DefaultValue("1883") int port,
        @DefaultValue("transmcbo-backend") String clientIdPrefix,
        /* TLS to the broker; trust comes from the SSL bundle below, or the JVM defaults when it is empty. */
        @DefaultValue("false") boolean tls,
        @DefaultValue("") String sslBundle,
        @DefaultValue("$share/backend/v/#") String subscription) {
}
