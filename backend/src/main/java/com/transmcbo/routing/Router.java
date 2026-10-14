package com.transmcbo.routing;

import com.graphhopper.GHRequest;
import com.graphhopper.GHResponse;
import com.graphhopper.GraphHopper;
import com.graphhopper.ResponsePath;
import com.graphhopper.config.Profile;
import com.graphhopper.util.GHUtility;
import com.graphhopper.util.PointList;
import com.graphhopper.util.shapes.GHPoint;
import com.transmcbo.proto.Route;
import jakarta.annotation.PreDestroy;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * GraphHopper singleton, profile {@code car}, flexible mode (no CH) so the vehicle heading can be used.
 * Loads the precompiled graph from disk; imports the .osm.pbf only when no graph exists yet.
 */
@Component
public class Router {

    static final String PROFILE = "car";

    private static final Logger log = LoggerFactory.getLogger(Router.class);

    private final GraphHopper hopper;

    public Router(RoutingProperties props) {
        Path graph = Path.of(props.graphDir());
        Path osm = Path.of(props.osmFile());
        if (!Files.isDirectory(graph) && !Files.isRegularFile(osm)) {
            log.warn("Routing disabled: no graph at {} and no OSM file at {} (run tools/build-osm.sh)",
                    graph.toAbsolutePath(), osm.toAbsolutePath());
            hopper = null;
            return;
        }
        GraphHopper gh = new GraphHopper();
        gh.setOSMFile(osm.toString());
        gh.setGraphHopperLocation(graph.toString());
        gh.setEncodedValuesString("car_access, car_average_speed");
        gh.setProfiles(new Profile(PROFILE).setCustomModel(GHUtility.loadCustomModelFromJar("car.json")));
        long start = System.nanoTime();
        gh.importOrLoad();
        log.info("GraphHopper ready in {} ms ({} edges)", (System.nanoTime() - start) / 1_000_000, gh.getBaseGraph().getEdges());
        hopper = gh;
    }

    public boolean available() {
        return hopper != null;
    }

    /**
     * @param headingDeg vehicle heading, or NaN when unknown/stopped
     * @return empty when no road route connects both points
     */
    public Optional<Route> route(double fromLat, double fromLon, double headingDeg, double toLat, double toLon) {
        GHRequest req = new GHRequest(new GHPoint(fromLat, fromLon), new GHPoint(toLat, toLon)).setProfile(PROFILE);
        if (!Double.isNaN(headingDeg)) {
            req.setHeadings(List.of(headingDeg, Double.NaN));
        }
        GHResponse res = hopper.route(req);
        if (res.hasErrors()) {
            log.debug("No route: {}", res.getErrors());
            return Optional.empty();
        }
        ResponsePath path = res.getBest();
        PointList pts = path.getPoints();
        double[] latLon = new double[pts.size() * 2];
        for (int i = 0; i < pts.size(); i++) {
            latLon[2 * i] = pts.getLat(i);
            latLon[2 * i + 1] = pts.getLon(i);
        }
        return Optional.of(Route.newBuilder()
                .setPolyline(Polyline.encode(latLon))
                .setDistM((int) Math.round(path.getDistance()))
                .setTimeS((int) (path.getTime() / 1000))
                .build());
    }

    @PreDestroy
    void close() {
        if (hopper != null) {
            hopper.close();
        }
    }
}
