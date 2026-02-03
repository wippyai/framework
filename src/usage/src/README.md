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
