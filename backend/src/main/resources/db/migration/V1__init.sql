CREATE TABLE employee (
    id            BIGSERIAL PRIMARY KEY,
    document      VARCHAR(32)  NOT NULL,
    full_name     VARCHAR(120) NOT NULL,
    role          VARCHAR(16)  NOT NULL CHECK (role IN ('WORKER', 'SUPERVISOR')),
    password_hash VARCHAR(100) NOT NULL,
    active        BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX employee_document ON employee (lower(document));

CREATE TABLE worksite (
    id         BIGSERIAL PRIMARY KEY,
    name       VARCHAR(120)     NOT NULL,
    address    VARCHAR(250)     NOT NULL DEFAULT '',
    lat        DOUBLE PRECISION NOT NULL CHECK (lat BETWEEN -90 AND 90),
    lon        DOUBLE PRECISION NOT NULL CHECK (lon BETWEEN -180 AND 180),
    radius_m   INTEGER          NOT NULL CHECK (radius_m BETWEEN 20 AND 2000),
    active     BOOLEAN          NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ      NOT NULL DEFAULT now()
);

-- One shift per employee. days: bit 0 = Monday ... bit 6 = Sunday.
CREATE TABLE shift (
    id            BIGSERIAL PRIMARY KEY,
    employee_id   BIGINT   NOT NULL UNIQUE REFERENCES employee (id),
    worksite_id   BIGINT   NOT NULL REFERENCES worksite (id),
    start_time    TIME     NOT NULL,
    end_time      TIME     NOT NULL,
    days          SMALLINT NOT NULL CHECK (days BETWEEN 1 AND 127),
    grace_minutes SMALLINT NOT NULL CHECK (grace_minutes BETWEEN 0 AND 120)
);

-- Append-only: rejected attempts are kept for auditing.
CREATE TABLE attendance_mark (
    id          BIGSERIAL PRIMARY KEY,
    client_id   UUID             NOT NULL UNIQUE,
    employee_id BIGINT           NOT NULL REFERENCES employee (id),
    worksite_id BIGINT           REFERENCES worksite (id),
    type        VARCHAR(3)       NOT NULL CHECK (type IN ('IN', 'OUT')),
    recorded_at TIMESTAMPTZ      NOT NULL,
    captured_at TIMESTAMPTZ      NOT NULL,
    received_at TIMESTAMPTZ      NOT NULL,
    lat         DOUBLE PRECISION NOT NULL,
    lon         DOUBLE PRECISION NOT NULL,
    accuracy_m  REAL             NOT NULL,
    mocked      BOOLEAN          NOT NULL,
    distance_m  REAL,
    status      VARCHAR(16)      NOT NULL,
    rejection   VARCHAR(24),
    deferred    BOOLEAN          NOT NULL
);

CREATE INDEX attendance_mark_employee_time ON attendance_mark (employee_id, recorded_at);
CREATE INDEX attendance_mark_time ON attendance_mark (recorded_at);
CREATE INDEX attendance_mark_last_accepted ON attendance_mark (employee_id, recorded_at DESC) WHERE status <> 'REJECTED';
