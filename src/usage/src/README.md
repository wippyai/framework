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

Breakdown rows reference their usage record with `ON DELETE CASCADE`. SQLite enforces it only on connections with `PRAGMA foreign_keys = ON`, which the runtime does not set, so code that deletes usage records on SQLite deletes their `token_usage_cache_writes` rows first.
