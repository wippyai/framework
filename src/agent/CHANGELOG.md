# Changelog

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
