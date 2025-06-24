# WebSocket Integration Guide for Wippy Runtime

## 1. Setup Overview

The Wippy Runtime WebSocket system consists of:
- Lua HTTP handler (authentication)
- Go WebSocket relay middleware
- Lua hub process (connection management)

## 2. Authentication Endpoint

Create a Lua HTTP handler (`ws_auth.lua`):

```lua
local http = require("http")
local json = require("json")

function handler()
    local req = http.request()
    local res = http.response()
    
    -- Look up hub process by name
    local hub_pid = process.registry.lookup("my_ws_hub")
    
    -- Create relay configuration
    local relay_config = {
        target_pid = hub_pid,
        message_topic = "ws.message",
        metadata = {
            client_type = "web",
            version = "1.0"
        }
    }
    
    -- Set special header for relay middleware
    local config_json, err = json.encode(relay_config)
    if err then
        res:set_status(500)
        res:write_json({ error = "Failed to encode config" })
        return
    end
    
    res:set_header("X-WS-Relay", config_json)
end

return { handler = handler }
```

## 3. Hub Process Implementation

Create the hub process (`ws_hub_process.lua`):

```lua
local json = require("json")

function run()
    -- Register this process with a name for discovery
    process.registry.register("my_ws_hub")
    print("WebSocket hub started with PID:", process.pid())
    
    -- Store connected clients
    local clients = {}
    local client_count = 0
    
    -- Create message inbox
    local inbox = process.inbox()
    local events = process.events()
    
    -- Main event loop
    while true do
        local result = channel.select({
            inbox:case_receive(),
            events:case_receive()
        })
        
        if result.channel == inbox then
            local msg = result.value
            if not msg then goto continue end
            
            local topic = msg:topic()
            local payload = msg:payload() and msg:payload():data()
            local sender = msg:from() or "unknown"
            
            if topic == "ws.join" then
                -- Parse client info from JSON
                if type(payload) == "string" then
                    local client_info, err = json.decode(payload)
                    if err then
                        print("Error decoding join payload:", err)
                        goto continue
                    end
                    
                    local client_pid = client_info.ClientPID
                    if not client_pid then
                        print("Missing ClientPID in join payload")
                        goto continue
                    end
                    
                    print("Client joined:", client_pid)
                    
                    -- Store client with metadata
                    clients[client_pid] = {
                        connected_at = os.time(),
                        metadata = client_info.Metadata or {}
                    }
                    client_count = client_count + 1
                    
                    -- Send welcome message
                    process.send(client_pid, "welcome", {
                        message = "Connected successfully",
                        client_count = client_count
                    })
                end
                
            elseif topic == "ws.leave" then
                -- Handle client disconnect
                if type(payload) == "string" then
                    local client_info, err = json.decode(payload)
                    if err then
                        print("Error decoding leave payload:", err)
                        goto continue
                    end
                    
                    local client_pid = client_info.ClientPID
                    if not client_pid then 
                        print("Missing ClientPID in leave payload")
                        goto continue
                    end
                    
                    if clients[client_pid] then
                        clients[client_pid] = nil
                        client_count = client_count - 1
                        print("Client left:", client_pid)
                    end
                end
                
            elseif topic == "ws.message" then
                -- Process application messages
                if type(payload) == "string" then
                    local data, err = json.decode(payload)
                    if err then
                        print("Error decoding message payload:", err)
                        goto continue
                    end
                    
                    -- Handle different message types
                    if data.type == "command" then
                        processCommand(data, sender, clients)
                    elseif data.type == "chat" then
                        broadcastChat(data, sender, clients)
                    end
                end
                
            elseif topic == "ws.heartbeat" then
                -- Update client heartbeat information
                if type(payload) == "string" then
                    local heartbeat_info, err = json.decode(payload)
                    if err then
                        print("Error decoding heartbeat payload:", err)
                        goto continue
                    end
                    
                    local client_pid = heartbeat_info.ClientPID
                    if client_pid and clients[client_pid] then
                        clients[client_pid].last_heartbeat = os.time()
                        clients[client_pid].uptime = heartbeat_info.Uptime
                    end
                end
            end
        elseif result.channel == events then
            -- Handle process events
            local event = result.value
            if event.kind == process.event.CANCEL then
                break
            end
        end
        ::continue::
    end
    
    return { status = "shutdown", clients = client_count }
end

-- Example function for processing commands
function processCommand(data, sender, clients)
    if data.command == "broadcast" and data.message then
        -- Broadcast message to all clients
        for client_pid, _ in pairs(clients) do
            process.send(client_pid, "broadcast", {
                from = "system",
                message = data.message
            })
        end
    end
end

-- Example function for broadcasting chat messages
function broadcastChat(data, sender, clients)
    if data.message then
        -- Get sender nickname from metadata
        local nickname = "Anonymous"
        if clients[sender] and clients[sender].metadata.nickname then
            nickname = clients[sender].metadata.nickname
        end
        
        -- Broadcast to all clients
        for client_pid, _ in pairs(clients) do
            process.send(client_pid, "chat", {
                from = nickname,
                message = data.message,
                timestamp = os.time()
            })
        end
    end
end

return { run = run }
```

## 4. Application Configuration (in _index.yaml)

```yaml
version: "1.0"
namespace: app.websocket.myapp

entries:
  # Hub Process Service
  - name: ws_hub.service
    kind: process.service
    process: ws_hub.process
    host: system:processes
    lifecycle:
      auto_start: true
      
  # Process Implementation
  - name: ws_hub.process
    kind: process.lua
    source: file://ws_hub_process.lua
    method: run
    modules: [ time, json ]

  # Auth Function
  - name: ws_auth
    kind: function.lua
    source: file://ws_auth.lua
    method: handler
    modules: [ http, json ]

  # HTTP Endpoint
  - name: ws_auth.endpoint
    kind: http.endpoint
    method: GET
    path: /ws/connect
    func: ws_auth
```

## 5. Client-Side Connection (JavaScript)

```javascript
// Connect to WebSocket endpoint
const socket = new WebSocket('ws://your-server.com/api/v1/ws/connect');

// Handle connection open
socket.addEventListener('open', (event) => {
    console.log('Connected to server');
    
    // Send metadata update
    socket.send(JSON.stringify({
        type: 'update_metadata',
        nickname: 'User123',
        avatar: 'default'
    }));
});

// Handle messages from server
socket.addEventListener('message', (event) => {
    const message = JSON.parse(event.data);
    
    // Handle message topics
    if (message.topic === 'welcome') {
        console.log('Welcome message:', message.data.message);
    } else if (message.topic === 'chat') {
        console.log(`${message.data.from}: ${message.data.message}`);
    } else if (message.topic === 'broadcast') {
        console.log(`BROADCAST: ${message.data.message}`);
    }
});

// Send a chat message
function sendChat(message) {
    socket.send(JSON.stringify({
        type: 'chat',
        message: message
    }));
}

// Close connection
function disconnect() {
    socket.close();
}
```

## 6. Reconfiguring WebSocket Connections

To change WebSocket target PID or other options:

```lua
-- Send a control message to the WebSocket connection
function reconfigureConnection(client_pid, new_target_pid)
    -- Create control command
    local control_cmd = {
        target_pid = new_target_pid,
        message_topic = "ws.new_topic", -- Optional
        metadata = {
            new_property = "value"
        }
    }
    
    -- Encode command to JSON
    local cmd_json, err = json.encode(control_cmd)
    if err then
        print("Error encoding control command:", err)
        return false
    end
    
    -- Send control message
    local controlMsg = pubsub.message.new(
        process.pid(),
        client_pid,
        "ws.control",
        cmd_json
    )
    
    return pubsub.send(controlMsg)
end
```

## 7. Key WebSocket Topics

- `ws.join`: Client connected to server
- `ws.leave`: Client disconnected from server
- `ws.message`: Application messages
- `ws.control`: Connection control commands
- `ws.heartbeat`: Regular connection status updates
- `ws.close`: Force close a connection
