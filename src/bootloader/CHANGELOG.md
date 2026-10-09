# Changelog

## [0.3.18](https://github.com/wippyai/framework/compare/bootloader-v0.3.17...bootloader-v0.3.18) (2026-10-09)


### Bug Fixes

* shipped modules do not depend on wippy/test ([#161](https://github.com/wippyai/framework/issues/161)) ([1ec020b](https://github.com/wippyai/framework/commit/1ec020bea001b4413d1b517454e313aa86e0890a))

## [0.3.17](https://github.com/wippyai/framework/compare/bootloader-v0.3.16...bootloader-v0.3.17) (2026-10-01)

### Runtime requirement

* Requires **Wippy runtime v0.3.44a or newer**. Older runtimes reject `lifecycle.startup: complete`; upgrade the runtime before this module.

### Features

* The auto-start service uses `startup: complete`: application readiness waits for discovery and initialization to succeed. `wippy test` and `wippy run <command>` do not run their entrypoints on boot failure. Other services may start concurrently; this is not service-start ordering. ([#142](https://github.com/wippyai/framework/pull/142))
* The orchestrator's `run(options)` returns `stats, nil` on success and `nil, error` on discovery or execution failure. With no discovered bootloaders it returns empty statistics. Individual bootloaders still return status tables; `run_chain(entries, options, satisfied)` still returns `success, stats`.

### Bug Fixes

* Discovery and initialization failures reach the readiness gate instead of being returned as successful process completion. Execution failures identify the failed bootloader and its message.
* Document the runtime floor and clarify readiness versus service startup order.

## [0.3.16](https://github.com/wippyai/framework/compare/bootloader-v0.3.15...bootloader-v0.3.16) (2026-09-22)


### Features

* **bootloader:** run a given bootloader chain with satisfied prerequisites ([#132](https://github.com/wippyai/framework/issues/132)) ([8b4b5a0](https://github.com/wippyai/framework/commit/8b4b5a0673bcd4994a8f741289c2b44fbefaae1b))
