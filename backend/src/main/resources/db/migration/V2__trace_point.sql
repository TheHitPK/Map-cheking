CREATE TABLE trace_point (
    veh  bigint                NOT NULL,
    ts   timestamptz           NOT NULL,
    line text                  NOT NULL,
    geom geometry(Point, 4326) NOT NULL,
    spd  smallint              NOT NULL,
    hdg  smallint              NOT NULL,
    PRIMARY KEY (veh, ts)
);

-- Rows arrive roughly in time order: BRIN is tiny and good enough for time-range scans.
CREATE INDEX trace_point_ts_brin ON trace_point USING brin (ts);
-- Phase 2: learning routes from the traces of each line.
CREATE INDEX trace_point_line_ts ON trace_point (line, ts);
