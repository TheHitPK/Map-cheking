CREATE TABLE line (
    id     text    PRIMARY KEY CHECK (id ~ '^[a-z0-9-]{1,32}$'),
    name   text    NOT NULL,
    active boolean NOT NULL DEFAULT true
);

-- Sample data; real lines are loaded by hand until phase 2 learns them from traces.
INSERT INTO line (id, name) VALUES
    ('bella-vista', 'Bella Vista'),
    ('circunvalacion-2', 'Circunvalación 2'),
    ('santa-rosa', 'Santa Rosa'),
    ('la-limpia', 'La Limpia'),
    ('milagro-norte', 'Milagro Norte'),
    ('san-jacinto', 'San Jacinto');
