-- Seed schema for Tier 2 (query-folding) tests. Loaded by s2ms_cluster.py `start <db>`.
-- Kept intentionally small: enough rows to exercise LIMIT/OFFSET, WHERE, and GROUP BY folding,
-- plus the SingleStore-specific column types (json / geography / geographypoint) that
-- Helpers[FixOdbcColumnRow] fixes up end-to-end.
--
-- NOTE: s2ms_cluster.py splits this file on ";" and runs one statement per driver call, so keep
-- each statement terminated by a single ";" and avoid ";" inside string/JSON literals.
--
-- ROWSTORE is required: SingleStore defaults new tables to columnstore (COLUMNAR), which does NOT
-- support GEOGRAPHY / GEOGRAPHYPOINT columns ("Feature 'GEOGRAPHY column type in COLUMNAR TABLE'
-- is not supported"). The primary key (id) becomes the shard key.

CREATE ROWSTORE TABLE folding_types (
    id           INT             NOT NULL,
    region       VARCHAR(32)     NOT NULL,
    amount       DECIMAL(10, 2)  NOT NULL,
    created_at   DATETIME        NOT NULL,
    payload      JSON            NULL,
    location     GEOGRAPHYPOINT  NULL,
    area         GEOGRAPHY       NULL,
    PRIMARY KEY (id)
);

-- TODO (PLAT-8100): expand type coverage so we can confirm every datatype round-trips / folds smoothly.
-- Add temporal columns:
--     `date` DATE, `time` TIME, `time_6` TIME(6),
--     `datetime` DATETIME, `datetime_6` DATETIME(6),
--     `timestamp` TIMESTAMP, `timestamp_6` TIMESTAMP(6)
-- Add numeric edge cases with MIN and MAX (and huge) values:
--     bigint / unsigned bigint at their limits, double, real, decimal
-- Seed rows should include the minimum, maximum, and representative mid-range values for each,
-- so folding + type fixup is verified at the boundaries, not just for typical data.

INSERT INTO folding_types (id, region, amount, created_at, payload, location, area) VALUES
    (1, 'US-East', 100.50, '2026-01-01 10:00:00', '{"tier":"gold","n":1}',   'POINT(-73.9857 40.7484)', 'POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))'),
    (2, 'US-East', 200.00, '2026-01-02 11:30:00', '{"tier":"silver","n":2}', 'POINT(-71.0589 42.3601)', 'POLYGON((0 0, 2 0, 2 2, 0 2, 0 0))'),
    (3, 'US-West', 300.75, '2026-01-03 09:15:00', '{"tier":"gold","n":3}',   'POINT(-122.4194 37.7749)', 'POLYGON((1 1, 3 1, 3 3, 1 3, 1 1))'),
    (4, 'US-West', 150.25, '2026-01-04 14:45:00', '{"tier":"bronze","n":4}', 'POINT(-118.2437 34.0522)', 'POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))'),
    (5, 'EU-West', 500.00, '2026-01-05 08:00:00', '{"tier":"gold","n":5}',   'POINT(-0.1276 51.5072)', 'POLYGON((2 2, 4 2, 4 4, 2 4, 2 2))'),
    (6, 'EU-West', 250.50, '2026-01-06 16:20:00', '{"tier":"silver","n":6}', 'POINT(2.3522 48.8566)', 'POLYGON((0 0, 3 0, 3 3, 0 3, 0 0))');

-- Dimension table for JOIN folding tests. `region_code` matches folding_types.region 1:1, mirroring
-- a Power BI relationship (fact.region -> dim.region_code). A fold-capable connector must push an
-- INNER JOIN to the server; if it can't, DirectQuery reports over relationships break.
CREATE ROWSTORE TABLE regions (
    region_code  VARCHAR(32)  NOT NULL,
    region_name  VARCHAR(64)  NOT NULL,
    country      VARCHAR(64)  NOT NULL,
    PRIMARY KEY (region_code)
);

INSERT INTO regions (region_code, region_name, country) VALUES
    ('US-East', 'United States (East)', 'USA'),
    ('US-West', 'United States (West)', 'USA'),
    ('EU-West', 'Europe (West)', 'Ireland');

-- Table with a NULLABLE column that actually contains NULLs, for null-check predicate folding.
-- folding_types columns are all populated, so an `IS NULL` / `IS NOT NULL` filter there can't
-- return a meaningful subset; this dedicated table (like `regions` for JOIN) keeps folding_types
-- and its goldens untouched. `note` is NULL for ids 2 and 4, set for 1 and 3.
CREATE ROWSTORE TABLE nullable_probe (
    id    INT          NOT NULL,
    note  VARCHAR(32)  NULL,
    PRIMARY KEY (id)
);

INSERT INTO nullable_probe (id, note) VALUES
    (1, 'alpha'),
    (2, NULL),
    (3, 'gamma'),
    (4, NULL);
