WITH
    sa_snapshot AS (
        SELECT
            *
        FROM
            pg_stat_activity
        WHERE
            datname = CURRENT_DATABASE()
            AND NOT query LIKE 'autovacuum:%'
            AND pid != PG_BACKEND_PID()
    )
SELECT
    (
        SELECT
            COUNT(*)
        FROM
            sa_snapshot
    ) AS total,
    (
        SELECT
            COUNT(*)
        FROM
            pg_stat_activity
        WHERE
            pid != PG_BACKEND_PID()
    ) AS instance_total,
    CURRENT_SETTING('max_connections')::INT AS max_connections,
    (
        SELECT
            COUNT(*)
        FROM
            sa_snapshot
        WHERE
            state = 'active'
    ) AS active,
    (
        SELECT
            COUNT(*)
        FROM
            sa_snapshot
        WHERE
            state = 'idle'
    ) AS idle,
    (
        SELECT
            COUNT(*)
        FROM
            sa_snapshot
        WHERE
            state = 'idle in transaction'
    ) AS idleintransaction,
    (
        SELECT
            COUNT(*)
        FROM
            sa_snapshot
        WHERE
            wait_event_type IN ('LWLockNamed', 'Lock', 'BufferPin')
    ) AS waiting,
    (
        SELECT
            EXTRACT(
                epoch
                FROM
                    MAX(NOW() - query_start)
            )::INT
        FROM
            sa_snapshot
        WHERE
            wait_event_type IN ('LWLockNamed', 'Lock', 'BufferPin')
    ) AS longest_waiting_seconds,
    (
        SELECT
            EXTRACT(
                epoch
                FROM
                    (NOW() - backend_start)
            )::INT
        FROM
            sa_snapshot
        ORDER BY
            backend_start
        LIMIT
            1
    ) AS longest_session_seconds,
    (
        SELECT
            EXTRACT(
                epoch
                FROM
                    (NOW() - xact_start)
            )::INT
        FROM
            sa_snapshot
        WHERE
            xact_start IS NOT NULL
        ORDER BY
            xact_start
        LIMIT
            1
    ) AS longest_tx_seconds,
    (
        SELECT
            EXTRACT(
                epoch
                FROM
                    (NOW() - xact_start)
            )::INT
        FROM
            pg_stat_activity
        WHERE
            query LIKE 'autovacuum:%'
        ORDER BY
            xact_start
        LIMIT
            1
    ) AS longest_autovacuum_seconds,
    (
        SELECT
            EXTRACT(
                epoch
                FROM
                    MAX(NOW() - query_start)
            )::INT
        FROM
            sa_snapshot
        WHERE
            state = 'active'
    ) AS longest_query_seconds,
    (
        SELECT
            MAX(age (backend_xmin))::int8
        FROM
            sa_snapshot
    ) AS max_xmin_age_tx,
    (
        SELECT
            COUNT(*)
        FROM
            pg_stat_activity
        WHERE
            datname = CURRENT_DATABASE()
            AND query LIKE 'autovacuum:%'
    ) AS av_workers;
