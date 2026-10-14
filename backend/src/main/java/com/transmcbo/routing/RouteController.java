package com.transmcbo.routing;

import static com.transmcbo.api.LinesController.PROTOBUF;

import com.transmcbo.ingest.Geo;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class RouteController {

    private final RouteService routes;

    public RouteController(RouteService routes) {
        this.routes = routes;
    }

    @GetMapping("/ruta")
    public ResponseEntity<byte[]> route(@RequestParam long veh, @RequestParam double lat, @RequestParam double lon) {
        if (veh <= 0 || veh > 0xFFFF_FFFFL
                || !Geo.inServiceArea((int) Math.round(lat * 1e6), (int) Math.round(lon * 1e6))) {
            return ResponseEntity.badRequest().build();
        }
        RouteService.Result r = routes.route((int) veh, lat, lon);
        return switch (r.status()) {
            case OK -> ResponseEntity.ok().contentType(PROTOBUF).body(r.route().toByteArray());
            case VEHICLE_NOT_LIVE -> ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            case NO_ROUTE -> ResponseEntity.unprocessableContent().build();
            case UNAVAILABLE -> ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
        };
    }
}
