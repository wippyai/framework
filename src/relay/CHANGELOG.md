# Changelog

## [0.3.18](https://github.com/wippyai/framework/compare/relay-v0.3.17...relay-v0.3.18) (2026-10-29)


### Bug Fixes

* **relay:** preserve authenticated composed scopes ([#224](https://github.com/wippyai/framework/issues/224)) ([aeed650](https://github.com/wippyai/framework/commit/aeed650066fafa8c155b50744e2ceff4104501e6))

## [0.3.17](https://github.com/wippyai/framework/compare/relay-v0.3.16...relay-v0.3.17) (2026-10-14)


### Bug Fixes

* Browser disconnects now start a reconnect grace period, and reconnecting cancels pending retirement. Pair Relay 0.3.17 with Session 0.6.8 or newer so accepted model, tool, and handoff work drains before session exit.
* harden Lua actor, relay, tool-round and runner behavior ([#165](https://github.com/wippyai/framework/issues/165)) ([d4607bb](https://github.com/wippyai/framework/commit/d4607bb274e09a1d0cc6bef533f45546846fb79b))
* **relay:** drain sessions before idle hub cleanup ([#179](https://github.com/wippyai/framework/issues/179)) ([c6c8734](https://github.com/wippyai/framework/commit/c6c873448d73e3c8d16c943262b4461002e8f33f))
* **relay:** enforce connected-client ownership before command dispatch ([#176](https://github.com/wippyai/framework/issues/176)) ([b2f1e92](https://github.com/wippyai/framework/commit/b2f1e924980722694856a70d2b46165b3dd71ec7))
* **relay:** preserve sessions through disconnect grace ([#180](https://github.com/wippyai/framework/issues/180)) ([5208546](https://github.com/wippyai/framework/commit/520854662a4a32e52100c14013f338acf3b1bd86))

## [0.3.16] (2026-10-07)

### Bug fixes

* Forward the existing `attention_context_enabled` setting when opening a Session through the user relay. Omitted settings retain the existing behavior.
