# Changelog

## [0.5.9](https://github.com/wippyai/framework/compare/llm-v0.5.8...llm-v0.5.9) (2026-10-21)


### Bug Fixes

* classify payment and quota errors without stopping fallback ([#197](https://github.com/wippyai/framework/issues/197)) ([0faadc6](https://github.com/wippyai/framework/commit/0faadc666afe477de8c412af322ef1147bd8b0cd))
* preserve malformed tool argument diagnostics ([#196](https://github.com/wippyai/framework/issues/196)) ([5e10c11](https://github.com/wippyai/framework/commit/5e10c11575abc17d23840f0af73f4c6f5445db3e))
* propagate usage context through agent and llm ([#199](https://github.com/wippyai/framework/issues/199)) ([bcee7a5](https://github.com/wippyai/framework/commit/bcee7a5afd57a94dd58656d9a5ed96282c94f21f))

## [0.5.8](https://github.com/wippyai/framework/compare/llm-v0.5.7...llm-v0.5.8) (2026-10-19)


### Features

* **agent:** cancel in-flight model and tool calls ([c89e9e3](https://github.com/wippyai/framework/commit/c89e9e33719cec85707c62f04977d08e13e0ca49))
* **llm:** cancel in-flight generation through a caller channel ([a6029e0](https://github.com/wippyai/framework/commit/a6029e046532a98df15d7a0da52ec5a70e8fa567))
* **llm:** fail over provider routes and ranked model classes ([b520d29](https://github.com/wippyai/framework/commit/b520d297323648637389a14ecffd9effd53efa4b))
* **llm:** fall back through requested model classes by priority ([1f3760a](https://github.com/wippyai/framework/commit/1f3760a5b4cbd28b6297936bc46ae2c79c449746))


### Bug Fixes

* **llm:** cap every provider request by remaining call budget ([d93d588](https://github.com/wippyai/framework/commit/d93d58888eea05bdebbb2c19db3c2f518da48832))
* **llm:** give the first usable class route its initial call budget ([ee9c23d](https://github.com/wippyai/framework/commit/ee9c23da16476407f5db826608cde85de3811c2f))
* preserve completed calls and avoid dispatch after cancellation ([d348802](https://github.com/wippyai/framework/commit/d348802fe34d7e96b725286bfad0ea2de9fc30ca))

## [0.5.7](https://github.com/wippyai/framework/compare/llm-v0.5.6...llm-v0.5.7) (2026-10-14)


### Features

* **llm:** support OpenAI Decisions evaluation ([#166](https://github.com/wippyai/framework/issues/166)) ([a7baba6](https://github.com/wippyai/framework/commit/a7baba6b5f7e718aec42c1a66783791868d477c6))


### Bug Fixes

* harden Lua actor, relay, tool-round and runner behavior ([#165](https://github.com/wippyai/framework/issues/165)) ([d4607bb](https://github.com/wippyai/framework/commit/d4607bb274e09a1d0cc6bef533f45546846fb79b))
* **llm:** preserve positional messages through prompt mapping ([#177](https://github.com/wippyai/framework/issues/177)) ([199516b](https://github.com/wippyai/framework/commit/199516b9fe963541c1cad46ae5db728b948a7b0b))

## [0.5.6](https://github.com/wippyai/framework/compare/llm-v0.5.5...llm-v0.5.6) (2026-10-09)


### Bug Fixes

* **llm:** stream Bedrock ConverseStream events as they arrive ([#167](https://github.com/wippyai/framework/issues/167)) ([d623e6e](https://github.com/wippyai/framework/commit/d623e6eb7e68e9f4f4c90dc7a338270983963944))

## [0.5.5] (2026-10-07)

### Features

* Render validated Attention context as bounded, untrusted model input. Support kind/version dispatch and authorized visual attachments.
* Render bounded context without adding technical data to visible conversation text.

### Bug fixes

* Pass only the first search result to the context renderer test assertion, preserving compatibility with the current runtime's type checker.

## [0.5.4](https://github.com/wippyai/framework/compare/llm-v0.5.3...llm-v0.5.4) (2026-10-02)


### Bug Fixes

* preserve tool identity and canonical model feedback ([#158](https://github.com/wippyai/framework/issues/158)) ([0eaf9ab](https://github.com/wippyai/framework/commit/0eaf9ab516aa6436c3c2f3042793cbd8f7876b4b))

## [0.5.3](https://github.com/wippyai/framework/compare/llm-v0.5.2...llm-v0.5.3) (2026-10-01)


### Features

* **llm:** declare route facts on model providers ([#148](https://github.com/wippyai/framework/issues/148)) ([391e892](https://github.com/wippyai/framework/commit/391e892eb660570427eaed053f0b22960f0ff23f))


### Bug Fixes

* **llm:** keep caller options unchanged in public API calls ([#149](https://github.com/wippyai/framework/issues/149)) ([6bde772](https://github.com/wippyai/framework/commit/6bde772c62b0ae9ae61ceba9d06ed6752d07a7dd))
* prepare framework checks for runtime v0.3.44a ([c81aaa6](https://github.com/wippyai/framework/commit/c81aaa61985e699909f9793de598a1e409f425f3))

## [0.5.2](https://github.com/wippyai/framework/compare/llm-v0.5.1...llm-v0.5.2) (2026-09-26)


### Bug Fixes

* **llm:** preserve rolling history cache boundaries across providers ([#143](https://github.com/wippyai/framework/issues/143)) ([945264c](https://github.com/wippyai/framework/commit/945264c22c19101651c357352f61ae1381a6bf5f))

## [0.5.1](https://github.com/wippyai/framework/compare/llm-v0.5.0...llm-v0.5.1) (2026-09-25)


### Features

* **llm:** model profile for Claude models that cannot be forced ([#137](https://github.com/wippyai/framework/issues/137)) ([8d8df71](https://github.com/wippyai/framework/commit/8d8df7130926267eacd8c0dc9782cafd501c4961))
* **llm:** normalized context_tokens and public resolve_model ([#136](https://github.com/wippyai/framework/issues/136)) ([784e730](https://github.com/wippyai/framework/commit/784e73087037a9881b0157f355fa85e80e06250f))
