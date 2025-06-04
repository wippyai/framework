local bapp = {}

-- Create common key bindings.
function bapp.create_keys(bindings)
    local keys = {}
    keys.quit = btea.bind({
        keys = bindings.quit or { "ctrl+c" },
        help = { key = "^C", desc = "quit" }
    })
    for name, binding in pairs(bindings) do
        if name ~= "quit" then
            keys[name] = btea.bind(binding)
        end
    end
    return keys
end

-- Instantiate a new base app.
function bapp.new(init_cmd)
    local app = {
        cmd_channel = channel.new(128),
        is_running = false,
        window = { width = 80, height = 24 },
        events_ch = btea.events(),
        done = channel.new()
    }

    -- Dispatch a single command.
    function app:dispatch(cmd)
        if cmd then self.cmd_channel:send(cmd) end
    end

    function app:upstream(msg)
        upstream.send(msg)
    end

    for _, cmd in ipairs(init_cmd or {}) do
        app:dispatch(cmd)
    end

    -- Dispatch multiple commands.
    function app:dispatch_many(cmds)
        if cmds and #cmds > 0 then
            self.cmd_channel:send(btea.batch(cmds))
        end
    end

    function app:update_window_size(size)
        self.window.width = size.width
        self.window.height = size.height
    end

    function app:init_terminal()
        self:dispatch_many({
            btea.commands.enter_alt_screen,
            btea.commands.hide_cursor
        })
    end

    function app:cleanup_terminal()
        self:dispatch_many({
            btea.commands.show_cursor,
            btea.commands.exit_alt_screen
        })
        self.done:send(true)
        self.done:close()
    end

    -- Command processor: listens on cmd_channel and executes commands.
    function app:start_command_processor()
        coroutine.spawn(function()
            while true do
                local result = channel.select({
                    self.cmd_channel:case_receive(),
                    self.done:case_receive()
                })
                if not result.ok then break end
                if result.channel == self.done then break end

                local cmd = result.value
                if cmd then
                    local msg = cmd:execute()
                    if msg then upstream.send(msg) end
                end
            end
        end)
    end

    -- Main run loop: processes tasks from the unified events channel.
    function app:run(update_fn, view_fn)
        self.is_running = true
        self:init_terminal()
        self:start_command_processor()

        while self.is_running do
            local result = channel.select({
                self.events_ch:case_receive(),
                self.done:case_receive()
            })

            if not result.ok or result.channel == self.done then
                self.done:send(true)
                break
            end

            local event = result.value
            if not event then
                self.done:send(true)
                break
            end

            if type(event) == "table" and event.type and event.task then
                local eventType = event.type
                local task = event.task
                if eventType == "update" then
                    local msg = task:input()
                    if type(msg) == "table" then
                        if msg.window_size then
                            self:update_window_size(msg.window_size)
                        end
                        local should_quit = update_fn(self, msg)
                        if should_quit then
                            task:complete("ok")
                            break
                        end
                    end
                    task:complete("ok")
                elseif eventType == "view" then
                    task:complete(view_fn(self))
                elseif eventType == "cancel" then
                    self.is_running = false
                    task:complete("cancel")
                else
                    task:complete("unknown task")
                end
            else
                -- Invalid event format; ignore or log if needed.
            end
        end

        self:cleanup_terminal()
    end

    return app
end

return bapp
