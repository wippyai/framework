<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">Bootloader Module</h1>
<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/wippyai/module-bootloader?style=flat-square)][releases-page]
[![License](https://img.shields.io/github/license/wippyai/module-bootloader?style=flat-square)](LICENSE)
[![Documentation](https://img.shields.io/badge/Wippy-Documentation-brightgreen.svg?style=flat-square)][wippy-documentation]

</div>


> [!NOTE]
> This repository is read-only.
> The code is generated from the [wippyai/framework][wippy-framework] repository.


The bootloader module handles database migrations during application startup.
It connects to the configured database, finds pending migrations, and applies them in the correct order.
The module ensures database schema changes are applied safely before the main application starts.

The bootloader performs these tasks:
- Connects to the database using the APP_DB environment variable
- Discovers migration files from the migration registry
- Sorts migrations by timestamp and name to ensure correct execution order
- Checks which migrations have already been applied
- Executes pending migrations one by one
- Tracks migration status and provides detailed logging
- Stops execution when errors occur to prevent data corruption
- Reports statistics about applied, failed, and skipped migrations

The module runs automatically during application startup and must complete successfully before other services start.
It handles connection cleanup and provides clear error messages when migrations fail.


[wippy-documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/module-bootloader/releases
[wippy-framework]: https://github.com/wippyai/framework
