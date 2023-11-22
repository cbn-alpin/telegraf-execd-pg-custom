WITH
    q_locks AS (
        SELECT
            *
        FROM
            pg_locks
        WHERE
            pid != PG_BACKEND_PID()
            AND DATABASE = (
                SELECT
                    oid
                FROM
                    pg_database
                WHERE
                    datname = CURRENT_DATABASE()
            )
    )
SELECT
    lockmodes AS lockmode,
    COALESCE(
        (
            SELECT
                COUNT(*)
            FROM
                q_locks
            WHERE
                MODE = lockmodes
        ),
        0
    ) AS COUNT
FROM
    UNNEST(
        '{AccessShareLock, ExclusiveLock, RowShareLock, RowExclusiveLock, ShareLock, ShareRowExclusiveLock,  AccessExclusiveLock, ShareUpdateExclusiveLock}'::TEXT[]
    ) lockmodes;
