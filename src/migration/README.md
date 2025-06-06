<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">Migration Module</h1>
<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/wippyai/module-migration?style=flat-square)][releases-page]
[![License](https://img.shields.io/github/license/wippyai/module-migration?style=flat-square)](LICENSE)
[![Documentation](https://img.shields.io/badge/Wippy-Documentation-brightgreen.svg?style=flat-square)][wippy-documentation]

</div>

> [!NOTE]
> This repository is read-only.
> The code is generated from the [wippyai/framework][wippy-framework] repository.


The migration module provides a complete database schema management system for Wippy applications. It handles creating, executing, and tracking database migrations with support for multiple database engines and rollback capabilities.

The module consists of several components:
- **Core DSL** - Domain-specific language for defining migrations with `migration()`, `database()`, `up()`, and `down()` functions
- **Repository** - Tracks applied migrations in a `_migrations` table with timestamps and descriptions
- **Registry** - Discovers migration files from the registry system based on database targets and tags
- **Runner** - High-level API for executing pending migrations, rolling back changes, and checking status
- **Migration API** - Main interface for running individual migration definitions with transaction support

Key features include:
- Transaction-based execution ensures migrations are applied atomically
- Cross-database support for PostgreSQL, SQLite, and MySQL with engine-specific implementations
- Automatic migration tracking and duplicate detection
- Forward and backward migration support with rollback capabilities
- Registry integration for discovering migrations by target database and tags
- Isolated execution environment with proper error handling and cleanup

The module is used by the bootloader during application startup and can be used programmatically for database schema management tasks.


[wippy-documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/module-migration/releases
[wippy-framework]: https://github.com/wippyai/framework
