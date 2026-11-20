# Session Util

The Wippy Web Host chat calls two routes in every app, and this module serves both of them. The
composer reads start prompts from `GET /agents/details`, and the tool-call rows read titles from
`GET /tools/by-name`. An app gets the routes only when it lists this module as a dependency.

## Installation

```yaml
- name: dep.wippy.session_util
  kind: ns.dependency
  component: wippy/session-util
  version: ">=v0.0.1"
  parameters:
    - name: api_router
      value: app:api
```

The `api_router` parameter is required. It names the `http.router` that serves both routes, so the
paths below are relative to that router's prefix. The module also loads `wippy/agent` and
`wippy/session`.

Both routes run as the signed-in caller. They answer `401` with
`{"success":false,"error":"Authentication required"}` when there is no caller, and `400` when the
query parameter is missing or empty. Every answer has `Cache-Control: no-store`.

## GET /agents/details

The query is `?agent=<registry id or name>`, with an optional `&session_id=<id>`. A found agent
gives this answer:

```json
{"success":true,"agent":{"id":"app:helper","name":"helper","title":"Helper","start_prompts":["Summarize this page"]}}
```

The `title` falls back to `name` when the title is empty, and `start_prompts` holds only the string
items of the agent's list. When the agent is unknown or hidden, the answer is still `200`, with
`{"success":true,"agent":null}`, so the caller can't tell whether a hidden agent exists.

Without a binding, the module looks the agent up by registry id first and by `meta.name` second, and
it hides agents with `meta.private: true`. When `session_id` names a session that the caller can
read and that session runs the requested agent, the module answers with that agent even when it is
private. Otherwise the module ignores `session_id` and uses the normal lookup.

## GET /tools/by-name

The query is `?tools=a,b`, a comma-separated list of the names that tool calls carry. The module
trims each name and drops empty items. The answer maps each known name to the tool's name and title:

```json
{"success":true,"tools":{"search_docs":{"name":"search_docs","title":"Search docs"}}}
```

Unknown names are left out, and an empty result is `{}`. Without a binding, a name matches a tool's
LLM name (`meta.llm_alias`, or the sanitized id name) or its full registry id. The title is
`meta.title`, or the LLM name when the title is empty. Private tools are left out. When two tools
share an LLM name, the module leaves that name out, because a tool call can't say which tool ran,
but both registry ids still match. A registry failure gives `500` with
`{"success":false,"error":"tool lookup failed"}`.

## Optional catalog contract

An app whose agents or tools are not plain registry entries, or that hides them by its own rules,
binds the `wippy.session_util:catalog` contract. When a binding exists, both routes ask it instead
of using the built-in rules. The binding runs as the caller.

```yaml
- name: session_catalog
  kind: contract.binding
  contracts:
    - contract: wippy.session_util:catalog
      default: true
      methods:
        agent_details: app:catalog_agent_details
        tool_titles: app:catalog_tool_titles
```

The `agent_details` method gets `{agent = "<id or name>"}` and returns
`{id, name, title, start_prompts}`, or nil to answer with a null agent. The `tool_titles` method gets
`{names = {...}}` and returns a map from each name to `{name, title}`. The module returns only the
names that the request asked for. When a bound catalog fails to open, the routes answer with no agent
and no tools, and they don't fall back to the built-in rules.

## Warnings

An app that serves its own copy of either route must remove that copy in the same commit that adds
this module. The runtime refuses to boot with `route pattern conflicts detected` when two entries
serve the same path on one router.

Adding a route to this module later is a breaking change, because every app that already serves that
path on the same router would stop booting.
