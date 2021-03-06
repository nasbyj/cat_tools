\set ECHO none

\i test/setup.sql

\set s cat_tools
CREATE TEMP VIEW func_calls AS
  SELECT * FROM (VALUES
    ('pg_attribute__get'::name, $$'pg_class', 'relname'$$::text)
  ) v(fname, args)
;
GRANT SELECT ON func_calls TO public;

SELECT plan(
  0
  -- Perms
  + (SELECT count(*)::int FROM func_calls)

  + 4 -- pg_attribute__get()
);

SET LOCAL ROLE :no_use_role;

SELECT throws_ok(
      format(
        $$SELECT %I.%I( %s )$$
        , :'s', fname
        , args
      )
      , '42501'
      , NULL
      , 'Verify public has no perms'
    )
  FROM func_calls
;

SET LOCAL ROLE :use_role;

/*
 * pg_attribute__get()
 */

-- See definition of _cat_tools.pg_attribute_v for details
SELECT 'SELECT ' || array_to_string(array(
      SELECT
          CASE attname
            WHEN 'attmissingval' THEN 'attmissingval::text AS attmissingval_text'
            ELSE attname
          END
        FROM pg_attribute
        WHERE attrelid='pg_attribute'::regclass
          AND attnum>=0
        ORDER BY attnum
    )
    , ', '
  ) AS attribute_select
\gset
\set call :attribute_select ' FROM %I.%I( %L, %L )'
\set n pg_attribute__get
SELECT throws_ok(
  format(
    :'call', :'s', :'n'
    , 'pg_catalog.foobar'
    , 'foobar'
  )
  , '42P01'
  , NULL
  , 'Non-existent relation throws error'
);
SELECT throws_ok(
  format(
    :'call', :'s', :'n'
    , 'pg_catalog.pg_class'
    , 'foobar'
  )
  , '42703'
  , 'column "foobar" of relation "pg_class" does not exist'
  , 'Non-existent column throws error'
);

SELECT results_eq(
  format(
    :'call', :'s', :'n'
    , 'pg_catalog.pg_class'
    , 'relname'
  )
  , :'attribute_select' || $$ FROM pg_attribute WHERE attrelid = 'pg_class'::regclass AND attname='relname'$$
  , 'Verify details of pg_class.relname'
);
SELECT results_eq(
  format(
    :'call', :'s', :'n'
    , 'pg_catalog.pg_tables'
    , 'tablename'
  )
  , :'attribute_select' || $$ FROM pg_attribute WHERE attrelid = 'pg_tables'::regclass AND attname='tablename'$$
  , 'Verify details of pg_tables.tablename'
);


\i test/pgxntool/finish.sql

-- vi: expandtab ts=2 sw=2
