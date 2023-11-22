WITH
    q_locked_rels AS (
        SELECT
            relation
        FROM
            pg_locks
        WHERE
            MODE = 'AccessExclusiveLock'
            AND GRANTED
    )
SELECT
    schemaname::TEXT AS SCHEMA,
    indexrelname::TEXT AS index_name,
    relname::TEXT AS table_name,
    COALESCE(idx_scan, 0) AS idx_scan,
    COALESCE(idx_tup_read, 0) AS idx_tup_read,
    COALESCE(idx_tup_fetch, 0) AS idx_tup_fetch,
    COALESCE(PG_RELATION_SIZE(indexrelid), 0) AS index_size_b,
    QUOTE_IDENT(schemaname) || '.' || QUOTE_IDENT(sui.indexrelname) AS index_full_name_val,
    REGEXP_REPLACE(
        REGEXP_REPLACE(
            PG_GET_INDEXDEF(sui.indexrelid),
            indexrelname,
            'X'
        ),
        '^CREATE UNIQUE',
        'CREATE'
    ) AS index_def,
    CASE
        WHEN NOT i.indisvalid THEN 1
        ELSE 0
    END AS is_invalid_int,
    CASE
        WHEN i.indisprimary THEN 1
        ELSE 0
    END AS is_pk_int,
    CASE
        WHEN i.indisunique
        OR indisexclusion THEN 1
        ELSE 0
    END AS is_uq_or_exc
FROM
    pg_stat_user_indexes sui
    JOIN pg_index i USING (indexrelid)
WHERE
    NOT schemaname LIKE E'pg\\_temp%'
    AND i.indrelid NOT IN (
        SELECT
            relation
        FROM
            q_locked_rels
    )
    AND i.indexrelid NOT IN (
        SELECT
            relation
        FROM
            q_locked_rels
    )
ORDER BY
    schemaname,
    relname,
    indexrelname;
