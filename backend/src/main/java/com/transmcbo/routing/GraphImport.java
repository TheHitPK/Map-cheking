package com.transmcbo.routing;

/**
 * Precompiles the GraphHopper graph at image build time, so the server only loads it from disk:
 * {@code java -Dloader.main=com.transmcbo.routing.GraphImport -cp app.jar
 * org.springframework.boot.loader.launch.PropertiesLauncher <osm.pbf> <graph-dir>}
 */
public final class GraphImport {

    private GraphImport() {
    }

    public static void main(String[] args) {
        if (args.length != 2) {
            throw new IllegalArgumentException("usage: GraphImport <osm.pbf> <graph-dir>");
        }
        Router router = new Router(new RoutingProperties(args[0], args[1]));
        if (!router.available()) {
            throw new IllegalStateException("import failed: " + args[0]);
        }
        router.close();
    }
}
