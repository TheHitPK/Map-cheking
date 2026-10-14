package com.transmcbo.ingest;

import com.transmcbo.proto.Pos;

/** Decoded position. ts in epoch seconds (unsigned on the wire), lat/lon in degrees * 1e6. */
public record Fix(String line, int veh, long ts, int lat, int lon, int spd, int hdg) {

    public static Fix of(String line, Pos p) {
        return new Fix(line, p.getVeh(), Integer.toUnsignedLong(p.getTs()), p.getLat(), p.getLon(), p.getSpd(), p.getHdg());
    }
}
