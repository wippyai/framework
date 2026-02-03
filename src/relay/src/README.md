# Relay

WebSocket relay hub for real-time user connections with plugin support.

## Installation

```yaml
entries:
  - name: relay
    kind: ns.dependency
    component: wippy/relay
    version: "*"
    parameters:
      - name: application_host
        value: app:processes
      - name: user_security_scope
        value: app.security:user
```

## Architecture

- **Central Hub**: Manages user-specific relay hubs, handles client routing
- **User Hub**: Per-user hub managing WebSocket connections and plugins
- **Plugins**: Extensible message handlers registered via discovery

## Configuration

```yaml
parameters:
  - name: max_connections_per_user
    value: "5"
  - name: queue_multiplier
    value: "100"
  - name: user_hub_inactivity_timeout
    value: "7200s"
```

## WebSocket Topics

- `ws.join` - Client connection
- `ws.leave` - Client disconnection
- `hub.activity_update` - Activity tracking

## Plugins

Register plugins via discovery:

```yaml
entries:
  - name: my_plugin
    kind: registry.entry
    meta:
      type: relay.plugin
      name: my_plugin
    handler: my_namespace:plugin_handler
```
