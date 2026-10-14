CREATE TABLE vehicle (
    id       bigint  PRIMARY KEY CHECK (id > 0 AND id <= 4294967295),
    pin_hash text    NOT NULL,
    active   boolean NOT NULL DEFAULT true
);
