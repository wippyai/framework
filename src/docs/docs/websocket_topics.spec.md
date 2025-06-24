# WebSocket Topics Reference

This document describes the event-based protocol used by the Wippy backend. Every WebSocket frame is a JSON object with **two top-level fields**:

```jsonc
{
  "topic": "<topic-string>", // see tables below
  "data": { /* payload */ }
}
```

• `topic` – identifies **what** changed.  
• `data`  – carries the payload. All payloads MAY include `request_id` which links the event to a client-initiated action (e.g. a chat command).  

> **URI-encoding**  
> Dynamic segments inside the topic (e.g. `pageUUID`, `sessionUUID`) **must be URI-encoded** so they never contain the `:` separator.

---

## Core Prefixes

| Prefix | Purpose                                                                |
| ------ |------------------------------------------------------------------------|
| `pages` | Dynamic page list for navigation updated                               |
| `page` | Individual dynamic page updated (`page:<pageUUID>`)                    |
| `artifact` | Artifact created / updated (`artifact:<artifactUUID>`)                 |
| `upload` | File upload progress / updates (`upload:<uploadUUID>`)                 |
| `session` | Chat-session level events (see sub-topics below)                       |
| `session.opened` | Session opened notification                                            |
| `session.closed` | Session closed notification                                            |
| `error` | Global error events                                                    |
| `welcome` | Initial handshake event with counters & user id                        |
| `action` | UI actions requested by server (`action:navigate` \| `action:sidebar`) |
| `registry` | Registry changes (`registry:<command>`)                                |
| `entry` | Registry entry changes (`entry:<entryUUID>`)                           |

---

## Common Topic Patterns

| Pattern | Example | Notes                                                                                      |
| ------- | ------- |--------------------------------------------------------------------------------------------|
| `welcome` | `welcome` | Sent once after connecting with summary stats                                              |
| `pages` | `pages` | Entire dynamic-page list changed                                                           |
| `page:<pageUUID>` | `page:123e456…` | Single page content changed **(reload HTML/Markdown only when `content_version` changes)** |
| `artifact:<artifactUUID>` | `artifact:38fb…` | Artifact created / updated **(reload HTML/Markdown only when `content_version` changes)**  |
| `upload:<uploadUUID>` | `upload:a71c…` | Upload progress or completion                                                              |
| `session.opened` | `session.opened` | A chat session became active                                                               |
| `session.closed` | `session.closed` | A chat session was closed                                                                  |
| `session:<sessionUUID>` | `session:5d21…` | Session-level metadata update                                                              |
| `session:<sessionUUID>:message:<messageUUID>` | `session:5d21…:message:9f4a…` | New / updated chat message                                                                 |
| `action:navigate` | `action:navigate` | Ask client to navigate URL                                                                 |
| `action:sidebar` | `action:sidebar` | Open/close sidebar with artifact / session                                                 |
| `registry:<command>` | `registry:refresh` | Registry-level command result                                                              |
| `entry:<entryUUID>` | `entry:77aa…` | Registry entry changed **(reload content only when `content_version` changes)**            |
| `error` | `error` | Unexpected server-side error                                                               |

---

## Representative Payloads

Below are trimmed examples of what you can expect in the `data` object for key topics.  Fields not relevant to your use-case can be ignored; new fields may appear without notice.

### Welcome
```jsonc
{
  "active_session_ids": ["5d21…"],
  "active_sessions": 2,
  "client_count": 14,
  "user_id": "user-123",
  "request_id": "..." // optional
}
```

### Page update (`page:*`)
```jsonc
{
  "id": "123e456…",
  "title": "FAQ",
  "content_version": "v3",
  "request_id": "..." // optional
}
```

### Chat session metadata (`session:*`)
```jsonc
{
  "agent": "gpt-4o",
  "model": "openai-gpt-4o",
  "title": "Brainstorming",
  "last_message_date": 1714392020000,
  "type": "update",
  "public_meta": [
    { "id": "link", "title": "Docs", "url": "https://…" }
  ],
  "request_id": "..." // optional
}
```

### Chat message (`session:*:message:*`)
```jsonc
{
  "type": "content",        // other values: chunk, user, delegation, tool_call, …
  "content": "Hello there!",
  "message_id": "9f4a…",
  "file_uuids": ["a1b2…"],
  "request_id": "..." // optional
}
```

### Action (`action:navigate` / `action:sidebar`)
```jsonc
// action:navigate — replace main area content
{
  "path": "/keeper"
}

// action:sidebar — open an artifact
{
  "artifact_uuid": "1",
  "artifact_content_type": "text/markdown"
}

// action:sidebar — open a session
{
  "session_uuid": "1"
}

// action:sidebar — close sidebar
{}
```

### Error (`error`)
```jsonc
{
  "error": "InternalError",  // machine-readable
  "message": "Something went wrong", // human message or 18n key
  "request_id": "..." // optional, but mandatory for session open commands from user
}
```