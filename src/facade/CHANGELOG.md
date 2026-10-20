# Changelog

## [0.6.47](https://github.com/wippyai/framework/compare/facade-v0.6.46...facade-v0.6.47) (2026-10-20)


### Features

* add opt-in Attention context and browser tools ([3cdba7e](https://github.com/wippyai/framework/commit/3cdba7e62e141f96d1b9bb32dafc19a5a7cb0891))


### Bug Fixes

* **facade:** expose shared chat policy for Host 1.0.62 ([#168](https://github.com/wippyai/framework/issues/168)) ([6aa84fe](https://github.com/wippyai/framework/commit/6aa84fe9057b859e430910922c413dad98f91978))
* **facade:** let the config and CSS handlers call an app-bound resolver ([b8d8f6a](https://github.com/wippyai/framework/commit/b8d8f6a1e2c6f48814701f6c8c216b93e66802ed))
* **facade:** release 0.6.46 for Web Host 1.0.66 with resolver permissions ([8cf400b](https://github.com/wippyai/framework/commit/8cf400b535de3618ef57704d699494ffbae79089))
* **facade:** remove unused SQL module and preserve test runner compatibility ([60e579a](https://github.com/wippyai/framework/commit/60e579a1e46eac50d3f731416d8c612aa686ba7d))
* shipped modules do not depend on wippy/test ([#161](https://github.com/wippyai/framework/issues/161)) ([1ec020b](https://github.com/wippyai/framework/commit/1ec020bea001b4413d1b517454e313aa86e0890a))
* update facade Web Host URL to 1.0.59 ([#146](https://github.com/wippyai/framework/issues/146)) ([126ef1e](https://github.com/wippyai/framework/commit/126ef1e812b287a80456bb28460d4e8d807df2b2))

## [0.6.46](https://github.com/wippyai/framework/compare/facade-v0.6.45...facade-v0.6.46) (2026-10-20)

- Grant the config and CSS variable handlers only the resolver contract permissions they use.
- Do not cache CSS variables because resolver output can vary by request.
- Test the resolver permissions in each handler's combined security scope.
- Target Web Host 1.0.66.

## [0.6.45](https://github.com/wippyai/framework/compare/facade-v0.6.44...facade-v0.6.45) (2026-10-19)

- Compose module settings through generic configuration contributors, so a module can supply Facade requirement values without a Facade dependency on that module.
- Compose installed CDN source choices through Facade.
- Remove the unused SQL module and keep the test runner compatible.
- Target Web Host 1.0.64.

## [0.6.44](https://github.com/wippyai/framework/compare/facade-v0.6.43...facade-v0.6.44) (2026-10-12)

- Forward frontend providers and import maps through Facade with the `iconify` and `import_map` requirements, which need Web Host 1.0.63 or newer.
- Target Web Host 1.0.63.

## [0.6.43](https://github.com/wippyai/framework/compare/facade-v0.6.42...facade-v0.6.43) (2026-10-09)

- Target Web Host 1.0.62 and forward model selection, session selector visibility, and sanitizer tags as shared top-level policy. Existing requirement names stay unchanged.
- Preserve older and private hosts with automatic legacy policy mirroring; add `host_policy_mode` for explicit legacy or shared policy.
- Use schema 2.0 for legacy policy and schema 2.1 for shared policy in both shells, with a schema 2.0 fallback for older backends.
- Preserve Attention configuration and the existing transport and theming scopes.


### Bug Fixes

* **facade:** expose shared chat policy for Host 1.0.62 ([#168](https://github.com/wippyai/framework/issues/168)) ([6aa84fe](https://github.com/wippyai/framework/commit/6aa84fe9057b859e430910922c413dad98f91978))

## [0.6.42](https://github.com/wippyai/framework/compare/facade-v0.6.41...facade-v0.6.42) (2026-10-09)


### Features

* add opt-in Attention context and browser tools ([3cdba7e](https://github.com/wippyai/framework/commit/3cdba7e62e141f96d1b9bb32dafc19a5a7cb0891))


### Bug Fixes

* shipped modules do not depend on wippy/test ([#161](https://github.com/wippyai/framework/issues/161)) ([1ec020b](https://github.com/wippyai/framework/commit/1ec020bea001b4413d1b517454e313aa86e0890a))

## [0.6.41](https://github.com/wippyai/framework/compare/facade-v0.6.40...facade-v0.6.41) (2026-10-01)


### Bug Fixes

* update facade Web Host URL to 1.0.59 ([#146](https://github.com/wippyai/framework/issues/146)) ([126ef1e](https://github.com/wippyai/framework/commit/126ef1e812b287a80456bb28460d4e8d807df2b2))
