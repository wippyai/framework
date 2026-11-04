local prompt = require("prompt")

local thinking = {}

-- Beta that admits thinking.block_binding and adds input_transformations to responses.
thinking.BINDING_BETA = "thinking-binding-controls-2026-08-01"

-- block_binding rides only on a thinking object of type adaptive or enabled; the API
-- rejects it alongside disabled or between_tools thinking and without a thinking object.
local BINDABLE_TYPES: {[string]: boolean} = { adaptive = true, enabled = true }

-- Sets drop_block on a thinking object that replays earlier thinking blocks, so the API
-- drops blocks bound to a different conversation instead of rejecting the request.
-- A block_binding the object already carries stays as set.
function thinking.bind_replayed_blocks(config: {[string]: any}?)
    if type(config) ~= "table" or not BINDABLE_TYPES[config.type] or config.block_binding ~= nil then
        return
    end
    config.block_binding = { prefix_mismatch_behavior = "drop_block" }
end

-- Whether a thinking object can carry block_binding.
function thinking.is_bindable(config: {[string]: any}?): boolean
    return type(config) == "table" and BINDABLE_TYPES[config.type] == true
end

-- Removes the wire blocks in `stale` from every message that holds one.
function thinking.remove_blocks(messages: {any}?, stale: {[any]: boolean}?)
    if not messages or not stale or next(stale) == nil then
        return
    end
    for _, message in ipairs(messages) do
        if type(message.content) == "table" then
            local kept = {}
            for _, block in ipairs(message.content) do
                if not stale[block] then table.insert(kept, block) end
            end
            if #kept ~= #message.content then
                message.content = kept
            end
        end
    end
end

-- Whether a thinking object carries block_binding, which the API admits only with BINDING_BETA.
function thinking.is_bound(config: {[string]: any}?): boolean
    return type(config) == "table" and config.block_binding ~= nil
end

-- Records where a response's blocks sit, given `entries` in response order: each
-- { kind = "thinking", block = <stored block> }, { kind = "text", text = ... } or
-- { kind = "tool_use", id = ... }. A thinking block keeps its position on itself and
-- the others come back as the list for metadata.content_positions. A response that
-- is thinking, then at most one text, then calls replays in that order without any
-- record, so it gets none.
function thinking.record_positions(entries: {any}): {any}?
    local present: {any} = {}
    for _, entry in ipairs(entries) do
        if entry.kind ~= "text" or (entry.text or "") ~= "" then
            table.insert(present, entry)
        end
    end

    local stages: {[string]: number} = { thinking = 1, text = 2, tool_use = 3 }
    local stage, texts = 1, 0
    local plain = true
    for _, entry in ipairs(present) do
        if stages[entry.kind] < stage then plain = false end
        stage = stages[entry.kind]
        if entry.kind == "text" then texts = texts + 1 end
    end
    if plain and texts <= 1 then
        return nil
    end

    local positions: {any} = {}
    for position, entry in ipairs(present) do
        if entry.kind == "thinking" then
            entry.block.position = position
        elseif entry.kind == "text" then
            table.insert(positions, { type = "text", position = position, text = entry.text })
        else
            table.insert(positions, { type = "tool_use", position = position, id = entry.id })
        end
    end
    return positions
end

local function row_text(content: any): string
    if type(content) == "string" then return content end
    local text = ""
    if type(content) == "table" then
        for _, part in ipairs(content) do
            if part.type == "text" and type(part.text) == "string" then
                text = text .. part.text
            end
        end
    end
    return text
end

local function without_outer_whitespace(text: string): string
    return text:match("^%s*(.-)%s*$") :: string
end

-- The position of the last block that still exists when calls outside `calls` are
-- gone, 0 when none does, or nil when the layout misses no call. Thinking behind that
-- block led to a call that no longer exists: the turn would end in thinking the
-- response did not end in, so it cannot be replayed.
local function last_standing(positions: {any}, calls: {[any]: boolean}): number?
    local last, missing = 0, false
    for _, entry in ipairs(positions) do
        if entry.type == "tool_use" and not calls[entry.id] then
            missing = true
        elseif entry.type == "tool_use" or not prompt.is_blank(entry.text) then
            last = math.max(last, entry.position)
        end
    end
    return missing and last or nil
end

-- Takes the calls out of a response's metadata when the caller discards them, along
-- with the thinking that led to them. `text` is the response's text.
function thinking.discard_calls(metadata: any, text: any)
    local blocks = metadata.thinking_blocks
    local positions = metadata.content_positions
    if type(positions) ~= "table" then
        if prompt.is_blank(text) then
            metadata.thinking_blocks = {}
        end
        return
    end

    local limit = last_standing(positions, {}) or math.huge
    local kept_blocks = {}
    for _, block in ipairs(type(blocks) == "table" and blocks or {}) do
        if block.position and block.position < limit then
            table.insert(kept_blocks, block)
        end
    end
    local kept_positions = {}
    for _, entry in ipairs(positions) do
        if entry.type == "text" then
            table.insert(kept_positions, entry)
        end
    end
    metadata.thinking_blocks = kept_blocks
    metadata.content_positions = limit > 0 and kept_positions or nil
end

-- A row's recorded layout, or nil when it has none or its text is no longer the
-- text the layout recorded: the row is what the host stands behind. Providers
-- compare neither whitespace-only text blocks nor the outer whitespace of a block, so
-- the layout holds only visible text, and whitespace a host stripped from the row's
-- ends is not an edit. A call the conversation no longer holds leaves the layout, and
-- thinking_limit bounds the thinking that can still be replayed.
local function read_layout(msg: any, calls: {[any]: boolean}): any?
    local positions = type(msg.metadata) == "table" and msg.metadata.content_positions or nil
    if type(positions) ~= "table" then
        return nil
    end
    local layout = { texts = {}, calls = {} }
    local text = ""
    for _, entry in ipairs(positions) do
        if entry.type == "text" then
            if not prompt.is_blank(entry.text) then
                table.insert(layout.texts, entry)
            end
            text = text .. entry.text
        elseif entry.type == "tool_use" then
            if calls[entry.id] then
                layout.calls[entry.id] = entry.position
            end
        end
    end
    layout.thinking_limit = last_standing(positions, calls)
    if without_outer_whitespace(text) ~= without_outer_whitespace(row_text(msg.content)) then
        return nil
    end
    return layout
end

-- Tracks the wire blocks of assistant rows against their recorded layouts and
-- rebuilds response order once the rows are consolidated into one turn.
function thinking.new_turn_order(messages: {any})
    local placed: {[any]: any} = {}
    local active: any = nil
    local order = {}

    local calls: {[any]: boolean} = {}
    for _, msg in ipairs(messages) do
        if msg.function_call then
            calls[msg.function_call.id] = true
        elseif type(msg.content) == "table" then
            for _, part in ipairs(msg.content) do
                if part.type == "function_call" then calls[part.id] = true end
            end
        end
    end

    -- Returns the row's own layout, whose text blocks replace the row's text.
    function order.enter_row(msg: any): any?
        local layout = read_layout(msg, calls)
        if layout then active = layout end
        return layout
    end

    function order.leave_turn()
        active = nil
    end

    function order.keeps_thinking(stored_block: any): boolean
        local limit = active and active.thinking_limit
        return not (limit and stored_block.position and stored_block.position > limit)
    end

    function order.place_thinking(wire_block: any, stored_block: any)
        if active and stored_block.position then
            placed[wire_block] = { layout = active, position = stored_block.position }
        end
    end

    function order.place_text(wire_block: any, position: number)
        if active then
            placed[wire_block] = { layout = active, position = position }
        end
    end

    function order.place_call(wire_block: any, id: any)
        local position = active and active.calls[id]
        if position then
            placed[wire_block] = { layout = active, position = position }
        end
    end

    -- A block that belongs right behind `anchor`, wherever the anchor ends up.
    function order.place_behind(wire_block: any, anchor: any)
        local place = placed[anchor]
        if place then
            placed[wire_block] = { layout = place.layout, position = place.position + 0.5 }
        end
    end

    -- The content with each run of blocks from one layout in response order. Blocks
    -- with no recorded place keep theirs, and they end a run.
    function order.rebuild(content: {any}): {any}
        if next(placed) == nil then
            return content
        end
        local rebuilt: {any} = {}
        local index = 1
        while index <= #content do
            local place = placed[content[index]]
            if not place then
                table.insert(rebuilt, content[index])
                index = index + 1
            else
                local run: {any} = {}
                while content[index] and placed[content[index]] and placed[content[index]].layout == place.layout do
                    table.insert(run, content[index])
                    index = index + 1
                end
                table.sort(run, function(a, b) return placed[a].position < placed[b].position end)
                for _, block in ipairs(run) do table.insert(rebuilt, block) end
            end
        end
        return rebuilt
    end

    return order
end

function thinking.effort_level(effort: number): string
    if effort >= 100 then return "max" end
    if effort >= 80 then return "xhigh" end
    if effort > 50 then return "high" end
    if effort >= 20 then return "medium" end
    return "low"
end

return thinking
