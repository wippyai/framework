# Changelog

## Unreleased

### Bug Fixes

* Label per-step recalled memory as background rather than a user message or new request. It supports the current user task without replacing it. After installing the release containing this fix, users can remove their local memory-label override; the companion Session fix preserves the task across mid-turn checkpoints. This change is not included in Agent 0.5.4.

## [0.5.7](https://github.com/wippyai/framework/compare/agent-v0.5.6...agent-v0.5.7) (2026-10-22)


### Features

* **agent:** add after_persist lifecycle phase, persisted event refs and recall diagnostics ([fa607e6](https://github.com/wippyai/framework/commit/fa607e6de45a95253ef0f57c6700002b48c2a266))


### Bug Fixes

* **agent:** keep authority test database in memory ([a60a800](https://github.com/wippyai/framework/commit/a60a80034d27aa267b489b966ecf60dc87794a8d))

## [0.5.6](https://github.com/wippyai/framework/compare/agent-v0.5.5...agent-v0.5.6) (2026-10-21)


### Bug Fixes

* preserve malformed tool argument diagnostics ([#196](https://github.com/wippyai/framework/issues/196)) ([5e10c11](https://github.com/wippyai/framework/commit/5e10c11575abc17d23840f0af73f4c6f5445db3e))
* propagate usage context through agent and llm ([#199](https://github.com/wippyai/framework/issues/199)) ([bcee7a5](https://github.com/wippyai/framework/commit/bcee7a5afd57a94dd58656d9a5ed96282c94f21f))

## [0.5.5](https://github.com/wippyai/framework/compare/agent-v0.5.4...agent-v0.5.5) (2026-10-19)


### Features

* **agent:** cancel in-flight model and tool calls ([c89e9e3](https://github.com/wippyai/framework/commit/c89e9e33719cec85707c62f04977d08e13e0ca49))
* **agent:** cancel in-flight model and tool calls through the host channel ([f6b2d9f](https://github.com/wippyai/framework/commit/f6b2d9f3734fafe20887bdfd3c52ff6a534d8a7d))
* **llm:** fail over provider routes and ranked model classes ([b520d29](https://github.com/wippyai/framework/commit/b520d297323648637389a14ecffd9effd53efa4b))


### Bug Fixes

* **agent:** identify recalled memory as background context ([5505567](https://github.com/wippyai/framework/commit/55055671683ae3c401066a0c890241366f141a6d))
* **agent:** label memory recall as background context ([61c596a](https://github.com/wippyai/framework/commit/61c596a0e4aa2475117f64b23f9b729d2a19621a))
* preserve completed calls and avoid dispatch after cancellation ([d348802](https://github.com/wippyai/framework/commit/d348802fe34d7e96b725286bfad0ea2de9fc30ca))

## [0.5.4](https://github.com/wippyai/framework/compare/agent-v0.5.3...agent-v0.5.4) (2026-10-14)


### Bug Fixes

* Permission refresh is opt-in: bind the execution identity resolver and set refresh_perms to true. Parallel tools share one refresh per batch; sequential tools refresh at each call boundary. Stop is checked again after prompt construction and before provider generation.
* **agent:** opt in to authority refresh at tool boundaries ([#173](https://github.com/wippyai/framework/issues/173)) ([3b92e76](https://github.com/wippyai/framework/commit/3b92e76d8f8d51343d3a1b5d94483ddf5d8285c9))
* harden Lua actor, relay, tool-round and runner behavior ([#165](https://github.com/wippyai/framework/issues/165)) ([d4607bb](https://github.com/wippyai/framework/commit/d4607bb274e09a1d0cc6bef533f45546846fb79b))

## [0.5.3] (2026-10-07)

### Features

* Add opt-in Attention traits and separate tools for semantic search, scoped CSS search, pointer, focus, selection and browser actions.
* Scope browser authority to each permitted tool call. Bound read results and remove expired or superseded observations through existing stale metadata.
* Support highlight, confirmation and approved capture. Capture prepares a removable draft for a later explicit Send.

### Dependencies

* Require LLM 0.5.5 for the validated Attention context renderer. Agents without Attention traits retain ordinary tool execution.

## [0.5.2](https://github.com/wippyai/framework/compare/agent-v0.5.1...agent-v0.5.2) (2026-10-02)


### Features

* **agent:** unify behavior lifecycle transitions ([#144](https://github.com/wippyai/framework/issues/144)) ([e9365b9](https://github.com/wippyai/framework/commit/e9365b9809e74ee582a58c73326b7909ce4ca2c7))


### Bug Fixes

* **agent:** normalize explicit tool failure results ([#157](https://github.com/wippyai/framework/issues/157)) ([15acebe](https://github.com/wippyai/framework/commit/15acebef9ae4d245823257eb3d2831dc7a630770))
* preserve tool identity and canonical model feedback ([#158](https://github.com/wippyai/framework/issues/158)) ([0eaf9ab](https://github.com/wippyai/framework/commit/0eaf9ab516aa6436c3c2f3042793cbd8f7876b4b))

## [0.5.1](https://github.com/wippyai/framework/compare/agent-v0.5.0...agent-v0.5.1) (2026-09-25)


### Features

* **agent:** cache breakpoint on the conversation tail ([#138](https://github.com/wippyai/framework/issues/138)) ([76c561f](https://github.com/wippyai/framework/commit/76c561f590a28cb0529c5004f35e7fde6cb45c31))
* **llm:** model profile for Claude models that cannot be forced ([#137](https://github.com/wippyai/framework/issues/137)) ([8d8df71](https://github.com/wippyai/framework/commit/8d8df7130926267eacd8c0dc9782cafd501c4961))
