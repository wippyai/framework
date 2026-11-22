# Usage

Automatic token usage tracking for LLM applications.

## What it does

When enabled, this module automatically records token consumption for every LLM call in your application. It implements the `wippy.llm:usage_tracker` contract, so any LLM provider (OpenAI, Claude, Google) will report usage through this tracker.

Usage data is stored per-actor, allowing you to:
- Track costs per user/session
- Set usage limits and quotas
- Analyze token consumption patterns
- Bill users based on actual usage

## Installation

```yaml
entries:
  - name: usage
    kind: ns.dependency
    component: wippy/usage
    version: "*"
```

## Configuration

The `target_db` requirement specifies which database stores usage records. Defaults to `app:db`.

## Cache writes

`cache_write_tokens` counts every token written to the prompt cache. When a call reports a breakdown by cache lifetime (the `cache_write_by_ttl` tracking option, such as `{ ["5m"] = 100, ["1h"] = 200 }`), the tracker stores each lifetime with writes as a row of `token_usage_cache_writes` (`usage_id`, `ttl`, `tokens`) in the same transaction as the usage record. The counts are non-negative integers, parts of `cache_write_tokens`, and together must not exceed it; the tracker stores the usage record without a breakdown that breaks these rules and logs a warning. Providers bill each lifetime at its own rate, so price every row by its lifetime and the rest of `cache_write_tokens` at the base write rate. Reports return the sums by lifetime as `cache_write_by_ttl`: for the whole range in `get_summary`, and per period, model and user in the other reports. A report leaves `cache_write_by_ttl` out where nothing was written with a known lifetime.

Breakdown rows reference their usage record with `ON DELETE CASCADE`. SQLite enforces it only on connections with `PRAGMA foreign_keys = ON`, which a SQLite database enables only with `foreign_keys: true`, so code that deletes usage records on SQLite deletes their `token_usage_cache_writes` rows first.

## Retention

`wippy.usage:policy` declares how long usage records are kept and how many one prune deletes:

```yaml
- name: policy
  kind: registry.entry
  meta:
    retention:
      token_usage: "90d"       # 1d..3650d
      batch_token_usage: 500   # 1..500
```

Override the entry to change either value. An invalid policy fails closed: nothing is deleted and the owner returns an `INVALID` error.

`token_usage_repo.prune(cutoff, limit)` deletes at most `limit` records stamped at or before `cutoff` (Unix seconds), oldest first, together with their `token_usage_cache_writes` rows in one transaction, and returns `{ deleted, needs_continue, oldest }`, where `oldest` is the Unix timestamp of the oldest remaining record. Both engines use an indexed range.

On SQLite, the upgrade replaces the timestamp index with an index on the timestamp's Unix seconds. Retention and reports use that index for both UTC timestamps and historical values with a timezone offset. The upgrade builds the index once and preserves every usage row. PostgreSQL retention uses the stored timestamps as UTC. PostgreSQL's historical timestamp column discarded the offset on insert.

`wippy.usage:retention` applies the policy. It carries `meta.type: kickside.retention.owner`, so a host that discovers retention owners of that type calls it on its retention schedule; elsewhere nothing calls it. It runs as `system:wippy.usage.retention` with `db.get` on `target_db` and `registry.get` on the requirement and the policy, and returns `{ success = true, deleted, needs_continue, deadline_ms }`, where `deadline_ms` is the time the oldest remaining record expires and is absent while more expired records remain or when no record remains, or `{ success = false, error }`. Database failures are retryable.
