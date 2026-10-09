# Changelog

## Unreleased

- Target Web Host 1.0.62 and schema wippy-context-2.1.json.
- Forward model selection, session selector visibility, and sanitizer tags as shared top-level policy. Existing requirement names stay unchanged.
- Preserve older and private hosts with automatic legacy policy mirroring; add `host_policy_mode` for explicit legacy or shared policy.
- Preserve Attention configuration and the existing transport and theming scopes.

## [0.6.42](https://github.com/wippyai/framework/compare/facade-v0.6.41...facade-v0.6.42) (2026-10-09)


### Features

* add opt-in Attention context and browser tools ([3cdba7e](https://github.com/wippyai/framework/commit/3cdba7e62e141f96d1b9bb32dafc19a5a7cb0891))


### Bug Fixes

* shipped modules do not depend on wippy/test ([#161](https://github.com/wippyai/framework/issues/161)) ([1ec020b](https://github.com/wippyai/framework/commit/1ec020bea001b4413d1b517454e313aa86e0890a))

## [0.6.41](https://github.com/wippyai/framework/compare/facade-v0.6.40...facade-v0.6.41) (2026-10-01)


### Bug Fixes

* update facade Web Host URL to 1.0.59 ([#146](https://github.com/wippyai/framework/issues/146)) ([126ef1e](https://github.com/wippyai/framework/commit/126ef1e812b287a80456bb28460d4e8d807df2b2))
