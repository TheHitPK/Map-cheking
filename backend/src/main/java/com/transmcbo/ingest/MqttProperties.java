package com.transmcbo.ingest;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

@ConfigurationProperties("transmcbo.mqtt")
public record MqttProperties(
        @DefaultValue("true") boolean enabled,
        @DefaultValue("localhost") String host,
        @DefaultValue("1883") int port,
        @DefaultValue("transmcbo-backend") String clientIdPrefix,
        @DefaultValue("$share/backend/v/#") String subscription) {
}
