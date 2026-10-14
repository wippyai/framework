<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">Relay Module</h1>
<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/wippyai/module-relay?style=flat-square)][releases-page]
[![License](https://img.shields.io/github/license/wippyai/module-relay?style=flat-square)](LICENSE)
[![Documentation](https://img.shields.io/badge/Wippy-Documentation-brightgreen.svg?style=flat-square)][wippy-documentation]

</div>

> [!NOTE]
> This repository is read-only.
> The code is generated from the [wippyai/framework][wippy-framework] repository.

## Idle hub cleanup

The last client leaving requests session-plugin shutdown. Sessions finish their
accepted work before exiting. The central inactivity sweep asks the user hub to
retire and waits for its monitored session plugin to exit before hub cleanup.
Reconnect cancels pending retirement and resumes the same plugin. Empty hubs
exit immediately; retirement adds no timers or background coroutines.

Use this with a session release that drains lifecycle finishes. Explicit service
cancellation remains a forced shutdown and follows the session recovery path.

[wippy-documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/module-relay/releases
[wippy-framework]: https://github.com/wippyai/framework
