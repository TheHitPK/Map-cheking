-- Gross pay per hour in US cents; NULL while not set.
ALTER TABLE employee ADD COLUMN hourly_rate_cents INTEGER CHECK (hourly_rate_cents BETWEEN 0 AND 100000);

-- A weekly pay period (Monday to Sunday) exists here only once it has been paid.
CREATE TABLE pay_period (
    start_date  DATE        PRIMARY KEY,
    end_date    DATE        NOT NULL,
    paid_on     DATE        NOT NULL,
    paid_by     BIGINT      NOT NULL REFERENCES employee (id),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (end_date = start_date + 6),
    CHECK (paid_on > end_date)
);

-- What each worker was paid, frozen at payment time (later rate changes do not alter it).
CREATE TABLE payroll_line (
    period_start      DATE    NOT NULL REFERENCES pay_period (start_date),
    employee_id       BIGINT  NOT NULL REFERENCES employee (id),
    hourly_rate_cents INTEGER NOT NULL,
    regular_minutes   INTEGER NOT NULL,
    overtime_minutes  INTEGER NOT NULL,
    gross_cents       BIGINT  NOT NULL,
    PRIMARY KEY (period_start, employee_id)
);

CREATE INDEX payroll_line_employee ON payroll_line (employee_id, period_start DESC);
