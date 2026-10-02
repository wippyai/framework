# Migration tests

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
