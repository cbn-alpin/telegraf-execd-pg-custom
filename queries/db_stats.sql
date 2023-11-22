SELECT
    numbackends,
    xact_commit,
    xact_rollback,
    blks_read,
    blks_hit,
    tup_returned,
    tup_fetched,
    tup_inserted,
    tup_updated,
    tup_deleted,
    conflicts,
    temp_files,
    temp_bytes,
    deadlocks,
    blk_read_time,
    blk_write_time,
    EXTRACT(
        epoch
        FROM
            (NOW() - PG_POSTMASTER_START_TIME())
    )::int8 AS postmaster_uptime_s,
    CASE
        WHEN PG_IS_IN_RECOVERY() THEN 1
        ELSE 0
    END AS in_recovery_int
FROM
    pg_stat_database,
    PG_CONTROL_SYSTEM()
WHERE
    datname = CURRENT_DATABASE();
