SELECT
    QUOTE_IDENT(schemaname) AS SCHEMA,
    QUOTE_IDENT(ut.relname) AS table_name,
    PG_TABLE_SIZE(relid) AS table_size_b,
    ABS(
        GREATEST(CEIL(LOG((PG_TABLE_SIZE(relid) + 1) / 10 ^ 6)), 0)
    )::TEXT AS table_size_cardinality_mb, -- i.e. 0=<1MB, 1=<10MB, 2=<100MB,..
    PG_TOTAL_RELATION_SIZE(relid) AS total_relation_size_b,
    CASE
        WHEN reltoastrelid != 0 THEN PG_TOTAL_RELATION_SIZE(reltoastrelid)
        ELSE 0::int8
    END AS toast_size_b,
    (
        EXTRACT(
            epoch
            FROM
                NOW() - GREATEST(last_vacuum, last_autovacuum)
        )
    )::int8 AS seconds_since_last_vacuum,
    (
        EXTRACT(
            epoch
            FROM
                NOW() - GREATEST(last_analyze, last_autoanalyze)
        )
    )::int8 AS seconds_since_last_analyze,
    CASE
        WHEN 'autovacuum_enabled=off' = ANY (c.reloptions) THEN 1
        ELSE 0
    END AS no_autovacuum,
    seq_scan,
    seq_tup_read,
    COALESCE(idx_scan, 0) AS idx_scan,
    COALESCE(idx_tup_fetch, 0) AS idx_tup_fetch,
    n_tup_ins,
    n_tup_upd,
    n_tup_del,
    n_tup_hot_upd,
    n_live_tup,
    n_dead_tup,
    vacuum_count,
    autovacuum_count,
    analyze_count,
    autoanalyze_count,
    age (relfrozenxid) AS tx_freeze_age,
    relpersistence
FROM
    pg_stat_user_tables ut
    JOIN pg_class c ON c.oid = ut.relid
WHERE
    -- leaving out fully locked tables as pg_relation_size
    -- also wants a lock and would wait
    NOT EXISTS (
        SELECT
            1
        FROM
            pg_locks
        WHERE
            relation = relid
            AND MODE = 'AccessExclusiveLock'
            AND GRANTED
    )
    AND c.relpersistence != 't';

-- and temp tables
