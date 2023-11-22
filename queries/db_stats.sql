select
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
  extract(epoch from (now() - pg_postmaster_start_time()))::int8
    as postmaster_uptime_s,
  case when pg_is_in_recovery() then 1 else 0 end
    as in_recovery_int
from
  pg_stat_database, pg_control_system()
where
  datname = current_database();
