# Migration tests

The alias suite applies, skips, reports and rolls back registered fixture migrations
against SQLite. With `MIGRATION_TEST_POSTGRES=true`, it repeats the same cases
against `app:concurrent_pg_a`, using the same registered functions with PostgreSQL
implementations. It also checks tag-hidden collisions, malformed declarations and
rollback of an injected alias lookup failure. Each case clears its ledger rows
and fixture tables, including after an assertion fails.

`make test` runs the SQLite concurrency regression and the existing suites.
The concurrency test uses two independent database resource pools pointed at
one file, so runtime serialization within a single pool cannot hide the race.
Both runners start with the same pending plan for three migrations. Each
migration must apply once and skip once, including its after hook. The tests
check the ledger and table contents with both an existing and a missing ledger.

`make test-postgres` adds the same cases on PostgreSQL. Use a disposable database:

```sh
PGPASSWORD=kickside createdb -h localhost -p 5433 -U kickside up_migration_concurrency
make test-postgres
PGPASSWORD=kickside dropdb -h localhost -p 5433 -U kickside up_migration_concurrency
```

These are local test credentials; the two `app:concurrent_pg_*` entries in
`_index.yaml` configure the connection. To use a different server, override both
entries using `wippy test -o app:concurrent_pg_a:host=...` and the equivalent
options for `concurrent_pg_b`, with `MIGRATION_TEST_POSTGRES=true`.
The tests drop `_migrations` and their probe tables, so never use an application
database. CI provisions an isolated PostgreSQL service for these cases.

The PostgreSQL suite also checks that an existing ledger can be opened under
the built-in `pg_read_all_data` role without schema `CREATE` permission. The
test service user must be able to assume that role (CI's disposable database
uses the provisioned superuser). Discovery regressions distinguish real
`run_next` errors from successful empty or already-applied migration plans.

The batched migration suite runs on SQLite and, with the PostgreSQL option,
PostgreSQL. It checks interrupted-page resume through a new connection, applied
rerun skipping, final-hook rollback, invalid checkpoints, alias resume, rollback,
checkpoint-write failure, competing runners, invalid IDs, forced replay refusal,
and checkpoint ownership across PostgreSQL search paths. It also applies a
100,000-row repair in 500 pages. A second resource pool reads
each committed 200-row page and writes between commits; each page transaction
must finish within two seconds. The atomic-default regression confirms that
ordinary `up` callbacks still roll back their entire operation on failure.
