package com.transmcbo.api;

import com.transmcbo.ingest.Geo;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.request.WebRequest;

/** All bodies are raw Protobuf bytes. */
@RestController
public class LinesController {

    public static final MediaType PROTOBUF = MediaType.parseMediaType("application/x-protobuf");

    private final LinesService lines;
    private final NearbyService nearby;

    public LinesController(LinesService lines, NearbyService nearby) {
        this.lines = lines;
        this.nearby = nearby;
    }

    @GetMapping("/lineas")
    public ResponseEntity<byte[]> lines(WebRequest request) {
        LinesService.Snapshot s = lines.get();
        if (request.checkNotModified(s.etag())) {
            return null; // 304 already written
        }
        return ResponseEntity.ok().contentType(PROTOBUF).eTag(s.etag()).body(s.body());
    }

    @GetMapping("/lineas/{id}/cercanos")
    public ResponseEntity<byte[]> nearby(@PathVariable String id, @RequestParam double lat, @RequestParam double lon) {
        if (!lines.get().ids().contains(id)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
        int latE6 = (int) Math.round(lat * 1e6);
        int lonE6 = (int) Math.round(lon * 1e6);
        if (!Geo.inServiceArea(latE6, lonE6)) {
            return ResponseEntity.badRequest().build();
        }
        return ResponseEntity.ok().contentType(PROTOBUF).body(nearby.find(id, latE6, lonE6).toByteArray());
    }
}
