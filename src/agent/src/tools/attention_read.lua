local json = require("json")

local M = {}
local PREFIX = "wippy.agent.tools:"
M.receipt_id = PREFIX .. "attention_read_receipt"
M.tools = {
    attention_find_semantic = "find", attention_find_css = "find", attention_get_node = "find",
    attention_get_tree = "tree", attention_get_geometry = "geometry", attention_get_cursor = "cursor",
    attention_get_focus = "focus", attention_get_selection = "selection", attention_hit_test = "point",
}

-- The removed attention_inspect tool has no registry entry or runtime authority.
-- Its ID is still recognized so stored history can be read and budgeted; a new
-- call to it can only become a refusal receipt.
function M.is_read(id)
    if id == PREFIX .. "attention_inspect" then return true end
    for name in pairs(M.tools) do if id == PREFIX .. name then return true end end
    return false
end

local function object(value, allowed)
    if type(value) ~= "table" then return false end
    for key in pairs(value) do if not allowed[key] then return false end end
    return true
end

local function text(value, limit)
    return type(value) == "string" and #value > 0 and #value <= limit
end

local function integer(value, low, high)
    return type(value) == "number" and value >= low and value <= high and value % 1 == 0
end

function M.is_ref(value)
    return object(value, {host_instance_id=true, node_id=true, mount_id=true, generation=true})
        and text(value.host_instance_id, 160) and text(value.node_id, 256) and text(value.mount_id, 256)
        and integer(value.generation, 1, 9007199254740991)
end

local function finite(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function M.normalize(name, args)
    local operation = M.tools[name]
    if not operation or type(args) ~= "table" then return nil, "invalid-request" end
    local allowed = {scope=true}
    local query = {}
    local call = {operation=operation, scope={fromRoot=true}, args=table.create(0,1)}
    if name == "attention_find_semantic" then
        for _, key in ipairs({"role", "name", "text", "resource_id"}) do
            allowed[key] = true
            if args[key] ~= nil then
                if not text(args[key], 256) then return nil, "invalid-request" end
                query[key] = args[key]
            end
        end
        if next(query) == nil then return nil, "semantic-filter-required" end
        call.args.query = query
    elseif name == "attention_find_css" then
        allowed = {selector=true, root=true}
        if not text(args.selector, 512) or not M.is_ref(args.root) then return nil, "css-root-required" end
        call.args.query = {css=args.selector, scope=args.root}
    elseif name == "attention_get_node" then
        allowed.node_id = true
        if not text(args.node_id, 256) then return nil, "node-id-required" end
        call.args.query = {node_id=args.node_id}
        call.args.limit = 1
    elseif name == "attention_get_geometry" then
        allowed = {node=true}
        if not M.is_ref(args.node) then return nil, "node-reference-required" end
        call.args.node = args.node
    elseif name == "attention_hit_test" then
        for _, key in ipairs({"x", "y", "coordinate_space", "radius_css_px", "step_css_px"}) do allowed[key] = true end
        if not finite(args.x) or not finite(args.y) then return nil, "point-required" end
        if args.coordinate_space ~= nil and args.coordinate_space ~= "host-viewport" and not M.is_ref(args.coordinate_space) then
            return nil, "invalid-coordinate-space"
        end
        for _, key in ipairs({"radius_css_px", "step_css_px"}) do
            if args[key] ~= nil and (not finite(args[key]) or args[key] < 0 or (key == "step_css_px" and args[key] == 0) or args[key] > 100) then
                return nil, "invalid-point-budget"
            end
        end
        for key in pairs(allowed) do if key ~= "scope" then call.args[key] = args[key] end end
    end
    if name == "attention_get_tree" or name == "attention_find_semantic" or name == "attention_find_css" then
        allowed.limit, allowed.continuation = true, true
        local limit = name == "attention_get_tree" and 32 or 8
        if args.limit ~= nil and not integer(args.limit, 1, limit) then return nil, "invalid-page-limit" end
        if args.continuation ~= nil and not text(args.continuation, 256) then return nil, "invalid-continuation" end
        call.args.limit, call.args.continuation = args.limit or limit, args.continuation
    end
    if name == "attention_get_tree" then
        allowed.depth = true
        if args.depth ~= nil and not integer(args.depth, 0, 32) then return nil, "invalid-depth" end
        call.args.depth = args.depth or 2
    end
    if not object(args, allowed) then return nil, "unexpected-field" end
    if args.scope ~= nil then
        if not M.is_ref(args.scope) then return nil, "invalid-scope" end
        call.scope.node = args.scope
    end
    return call, nil
end

-- Sorted serialization is used only for local deduplication, never as authority.
function M.canonical(value: any): string
    if type(value) ~= "table" then return json.encode(value) or "null" end
    local keys, out = {}, {}
    for key in pairs(value) do keys[#keys+1] = tostring(key) end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local child = value[key]
        if child == nil then child = value[tonumber(key)] end
        out[#out+1] = (json.encode(key) or '""') .. ":" .. M.canonical(child)
    end
    return "{" .. table.concat(out, ",") .. "}"
end

M.validation_errors = {
    ["invalid-request"]=true, ["semantic-filter-required"]=true, ["css-root-required"]=true,
    ["node-id-required"]=true, ["node-reference-required"]=true, ["point-required"]=true,
    ["invalid-coordinate-space"]=true, ["invalid-point-budget"]=true, ["invalid-page-limit"]=true,
    ["invalid-continuation"]=true, ["invalid-depth"]=true, ["unexpected-field"]=true, ["invalid-scope"]=true,
}

function M.receipt(reason, original_id)
    local instruction = "Use the available evidence. Do not repeat a refused Attention read."
    if M.validation_errors[reason] then
        instruction = "Correct the arguments once within the remaining read budget. Two invalid attempts end repair."
        if original_id == PREFIX .. "attention_get_cursor" or original_id == PREFIX .. "attention_get_focus"
            or original_id == PREFIX .. "attention_get_selection" then
            instruction = instruction .. " For the whole Host, pass {}. The only optional field is scope (a full NodeRef)."
        end
    end
    return {schema="wippy.attention.model.v1", status="rejected", reason=reason,
        original_registry_id=original_id, instruction=instruction}
end

local function pick(value, keys)
    local out = {}
    if type(value) == "table" then for _, key in ipairs(keys) do out[key] = value[key] end end
    return out
end

function M.project(result: table, name: string): any
    local inspection = result.inspection
    local out = {schema="wippy.attention.model.v1", status=result.status, reason=result.reason}
    if type(inspection) ~= "table" then return out end
    out.outcome, out.revisions, out.measured_at = inspection.outcome, inspection.revisions, inspection.measured_at
    out.omissions, out.continuation = inspection.omissions, inspection.continuation
    for _, omission in ipairs(inspection.omissions or {}) do
        if omission.reason == "invalid-request" then out.invalid = true end
    end
    local data = type(inspection.data) == "table" and inspection.data or {}
    local mounts, mount_ids, segments, segment_ids = {}, {}, {}, {}
    local nodes, refs = {}, {}
    out.host = result.host_instance_id
    local function ref(value)
        if not M.is_ref(value) then return false end
        local key = M.canonical({value.host_instance_id, value.mount_id, value.generation})
        if not mount_ids[key] then
            mounts[#mounts+1] = {value.host_instance_id, value.mount_id, value.generation}
            mount_ids[key] = #mounts
        end
        return {value.node_id, mount_ids[key]}
    end
    local function path(value)
        local indices = {}
        for _, segment in ipairs(type(value) == "table" and value or {}) do
            -- Preserve every identity/semantic field, but geometry belongs to geometry reads.
            local compact = {}
            for key, child in pairs(segment) do
                if key ~= "rect" and key ~= "clip" and key ~= "clip_rect" and key ~= "local_to_parent" and key ~= "geometry" then compact[key] = child end
            end
            local key = M.canonical(compact)
            if not segment_ids[key] then
                segments[#segments+1] = compact
                segment_ids[key] = #segments
            end
            indices[#indices+1] = segment_ids[key]
        end
        return indices
    end
    local function node(value)
        if type(value) ~= "table" or not M.is_ref(value.ref) then return end
        refs[value.ref.node_id] = {ref=value.ref, leaf=type(value.path) == "table" and value.path[#value.path] or nil}
        nodes[#nodes+1] = {ref(value.ref), ref(value.parent), value.kind or false, value.state or false,
            value.summary or {}, path(value.path), value.resource or false, value.layout or false}
    end
    for _, value in ipairs(data.nodes or {}) do node(value) end
    if type(data.node) == "table" and data.node.ref then node(data.node) end
    if #nodes > 0 then
        out.columns = {"ref", "parent", "kind", "state", "summary", "path", "resource", "layout"}
        out.nodes = nodes
    end
    if M.is_ref(data.root) then out.root = ref(data.root) end
    if name == "attention_get_geometry" then
        out.geometry = pick(data, {"rect", "clip", "visible", "offscreen", "quality", "coordinate_space"})
        out.geometry.node = ref(data.node)
    elseif name == "attention_get_selection" then
        -- Selection text is already privacy-filtered and bounded by the Host.
        out.selection = data.selection and pick(data.selection, {"selection_id", "selected_at", "kind", "collapsed", "direction", "text", "ranges"}) or false
        if type(data.selection) == "table" then
            out.selection.anchor_path = path(data.selection.anchor_path)
            out.selection.focus_path = path(data.selection.focus_path)
        end
        out.anchor, out.focus = ref(data.anchor), ref(data.focus)
    elseif name == "attention_get_focus" then
        out.focus = data.focus and pick(data.focus, {"focused_at", "event_id", "sequence", "summary", "candidate_id"}) or false
        if type(data.focus) == "table" then out.focus.path = path(data.focus.path) end
    elseif name == "attention_get_cursor" then
        out.event = data.event and pick(data.event, {"event_id", "type", "sequence", "observed_at", "point", "pointer_type", "candidate_ids"}) or false
    elseif name == "attention_hit_test" then
        out.point = data.point
    end
    if #mounts > 0 then out.mounts = mounts; out.ref_columns = {"node_id", "mount_index"}; out.mount_columns = {"host_instance_id", "mount_id", "generation"} end
    if #segments > 0 then out.paths = segments end
    -- A unique returned node may be actionable. The join must never use array position.
    if #nodes == 1 then
        for _, target in ipairs(result.targets or {}) do
            local known = refs[target.target_id]
            -- Existing immutable action references bind the terminal path mount;
            -- NodeRef.mount_id names the owning inspection realm. They can differ.
            local mount = known and (known.leaf or known.ref)
            if known and known.ref.host_instance_id == target.host_instance_id and mount.mount_id == target.mount_id and mount.generation == target.generation then
                out.target_ref = target
                break
            end
        end
    end
    local encoded = json.encode(out)
    if not encoded or #encoded > 8192 then
        -- Dropping page rows invalidates its already-advanced continuation.
        return {schema="wippy.attention.model.v1", status=result.status, outcome="partial",
            revisions=inspection.revisions, measured_at=inspection.measured_at,
            omissions={{reason="byte-limit"}}, reason="Required result exceeds 8 KiB; request a smaller scoped page or an exact node. No continuation retained."}
    end
    return out
end

return M
