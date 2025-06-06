<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">Framework</h1>
<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/wippyai/framework?style=for-the-badge)][releases-page]
[![License](https://img.shields.io/github/license/wippyai/framework?style=for-the-badge)](LICENSE)
[![Documentation](https://img.shields.io/badge/documentation-0F6640.svg?style=for-the-badge&logo=gitbook)][documentation]

</div>

A comprehensive monorepo of essential Lua components that expose Wippy's core functionality and abstractions.
Provides the foundational building blocks for developing concurrent AI agent applications,
including actor model primitives, LLM integration, HTTP services, data storage, security,
and configuration management — enabling developers to build sophisticated multiagent systems through Wippy's configuration-driven architecture.

## Modules

### Framework Modules

| Module                          | Description                                                                                                                  |
|---------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| [actor][module-actor]           | Implementation of the actor model pattern for Wippy Runtime with state management, message handling, and channel operations  |
| [agent][module-agent]           | Library for running LLM agents with conversation management, tool calling, delegation capabilities, and token usage tracking |
| [bootloader][module-bootloader] | System initialization and component bootstrapping for Wippy Runtime                                                          |
| [llm][module-llm]               | Unified interface for working with large language models, providing text generation, tool calling, and embeddings            |
| [migration][module-migration]   | Database migration system with structured patterns for reliable, reversible schema changes                                   |
| [relay][module-relay]           | Message relay and routing system for distributed communication                                                               |
| [security][module-security]     | Authentication, authorization, and access control framework with support for actors, scopes, and policies                    |
| [terminal][module-terminal]     | Terminal interface and command processing capabilities                                                                       |
| [test][module-test]             | BDD-style testing framework for Lua applications with assertions, lifecycle hooks, and mocking capabilities                  |
| [views][module-views]           | UI view management and rendering system                                                                                      |
| [usage][module-usage]           | Usage tracking and analytics for system monitoring                                                                           |

### Separated Modules

| Module                          | Description                                        |
|---------------------------------|----------------------------------------------------|
| [session][module-session]       | Session management and state persistence           |
| [uploads][module-uploads]       | File upload handling and management system         |
| [embeddings][module-embeddings] | Vector embeddings and semantic search capabilities |

### Core Modules

| Module           | Description                                                                                                        |
|------------------|--------------------------------------------------------------------------------------------------------------------|
| **http**         | HTTP requests and responses within web server context with headers, query params, and streaming                    |
| **http_client**  | HTTP client for making requests with various methods, batch operations, and streaming responses                    |
| **sql**          | Database interface for SQL operations across different engines with queries, transactions, and prepared statements |
| **fs**           | Universal filesystem abstraction layer supporting file operations and multi-backend storage systems                |
| **json**         | JSON encoding and decoding between Lua values and JSON strings                                                     |
| **yaml**         | YAML encoding and decoding with multiline string support                                                           |
| **crypto**       | Cryptographic functions including encryption, HMAC, JWT handling, and security utilities                           |
| **logger**       | Structured logging interface with different log levels and contextual fields                                       |
| **process**      | Actor-model API for concurrent processing with message passing and supervision                                     |
| **channel**      | Go-like channel system for coroutine communication and synchronization                                             |
| **events**       | Channel-based API for subscribing to Wippy event bus system                                                        |
| **registry**     | Distributed registry system for querying and managing entries with versioning                                      |
| **store**        | Key-value store interface supporting various backends with TTL support                                             |
| **time**         | Comprehensive time utilities for dates, timers, durations, and timezone handling                                   |
| **uuid**         | UUID generation, validation, and manipulation across different versions                                            |
| **hash**         | Cryptographic and non-cryptographic hash functions (MD5, SHA, FNV)                                                 |
| **base64**       | Base64 encoding and decoding for string conversion                                                                 |
| **excel**        | Excel file manipulation with workbook operations and sheet management                                              |
| **templates**    | Template rendering system with variable substitution                                                               |
| **jet**          | Jet templating system with inheritance patterns                                                                    |
| **websocket**    | WebSocket client implementation for real-time communication                                                        |
| **system**       | Go runtime information access including memory statistics and garbage collection                                   |
| **exec**         | External process execution with input/output streams and process control                                           |
| **env**          | Environment variable access interface                                                                              |
| **ctx**          | Shared context system for component communication                                                                  |
| **funcs**        | Task execution interface with async support and cancellation                                                       |
| **stream**       | Data streaming interface with chunked reading support                                                              |
| **cloudstorage** | Cloud storage provider interface for S3-like operations                                                            |

[module-actor]: https://github.com/wippyai/module-actor
[module-agent]: https://github.com/wippyai/module-agent
[module-bootloader]: https://github.com/wippyai/module-bootloader
[module-migration]: https://github.com/wippyai/module-migration
[module-relay]: https://github.com/wippyai/module-relay
[module-security]: https://github.com/wippyai/module-security
[module-terminal]: https://github.com/wippyai/module-terminal
[module-test]: https://github.com/wippyai/module-test
[module-views]: https://github.com/wippyai/module-views
[module-usage]: https://github.com/wippyai/module-usage
[module-llm]: https://github.com/wippyai/module-llm
[module-session]: https://github.com/wippyai/module-session
[module-uploads]: https://github.com/wippyai/module-uploads
[module-embeddings]: https://github.com/wippyai/module-embeddings
[documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/framework/releases
