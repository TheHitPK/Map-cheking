package com.transmcbo.routing;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

@ConfigurationProperties("transmcbo.routing")
public record RoutingProperties(
        @DefaultValue("../data/maracaibo.osm.pbf") String osmFile,
        @DefaultValue("../graph-cache") String graphDir) {
}
