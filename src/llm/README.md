<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">LLM Module</h1>
<div align="center">

Unified interface for Large Language Models in Wippy Framework

![Latest Release](https://img.shields.io/github/v/release/wippyai/framework?style=flat-square)
[![Documentation](https://img.shields.io/badge/Wippy-Documentation-brightgreen.svg?style=flat-square)][wippy-documentation]


</div>


## Overview

The LLM module provides a single, consistent way to work with Large Language Models from multiple providers. Instead of learning different APIs for OpenAI, Anthropic, Google, and others, you use one interface that works across all of them.

It supports text generation, tool calling, structured output, embeddings, and streaming. Models can be referenced by name or by class (like "fast" or "reasoning"), and the system automatically picks the best available option. Usage tracking and cost calculation are automatic.

## Providers

- **OpenAI** - GPT-4o, GPT-4o-mini, O1 reasoning models, embeddings
- **Anthropic** - Claude 3.7 Sonnet (with extended thinking), Claude 3.5 Sonnet/Haiku
- **Google** - Gemini 2.0 Flash via Vertex AI, Gemini Pro via Generative AI API
- **Local models** - LM Studio, Ollama, or any OpenAI-compatible endpoint

## Features

**Smart model resolution** - Reference models by exact name (`gpt-4o`), class (`fast`), or explicit class syntax (`class:reasoning`). The system finds the right model automatically.

**Tool calling** - Models can call external functions. Define tools with JSON schemas, and the module handles the conversation flow.

**Structured output** - Get validated JSON responses matching your schema.

**Prompt caching** - For Claude models, mark parts of prompts for caching to reduce costs and latency on repeated calls.

**Usage tracking** - Automatic token and cost tracking per request with user attribution.

**Streaming** - Real-time response streaming via Wippy's process communication system.

**Discovery** - Query available models, capabilities, pricing, and provider status.

## Documentation

See **[src/docs/llm.spec.md](src/docs/llm.spec.md)** for complete API documentation, examples, and usage patterns.

## License

See [LICENSE](LICENSE) for details.

---

[wippy-documentation]: https://docs.wippy.ai
[wippy-framework]: https://github.com/wippyai/framework
