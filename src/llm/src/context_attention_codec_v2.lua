local json = require("json")
local time = require("time")
local hash = require("hash")

local codec = {}
codec.ATTENTION_V2_LIMITS = {
    dictionary = 4128, path = 32, candidates = 128, points = 4096,
    events = 32, omissions = 128, memberships = 4096, total_memberships = 16384,
    expanded_bytes = 256 * 1024,
}

local function only_keys(value, allowed)
    if type(value) ~= "table" then
        return false
    end
    for key, _ in pairs(value) do
        if not allowed[key] then
            return false
        end
    end
    return true
end

local function nonempty(value, max_length)
    return type(value) == "string" and value ~= "" and #value <= max_length
end

local function integer(value, minimum)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value % 1 == 0
        and value >= minimum
end

local function array(value)
    if type(value) ~= "table" then
        return false
    end
    local encoded, err = json.encode(value)
    return not err and string.sub(encoded, 1, 1) == "["
end

local function finite(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function timestamp(value)
    if not nonempty(value, 64) then
        return false
    end
    local parsed, err = time.parse(time.RFC3339, value)
    return parsed ~= nil and err == nil
end

local function rect(value)
    return type(value) == "table"
        and only_keys(value, { x = true, y = true, width = true, height = true })
        and finite(value.x)
        and finite(value.y)
        and finite(value.width)
        and value.width >= 0
        and finite(value.height)
        and value.height >= 0
end

local function canonical_json(value, depth)
    depth = depth or 0
    if depth > 32 then return nil end
    if type(value) ~= 'table' then return json.encode(value) end
    local parts = {}
    if array(value) then
        for _, child in ipairs(value) do
            local encoded = canonical_json(child, depth + 1)
            if not encoded then return nil end
            parts[#parts + 1] = encoded
        end
        return '[' .. table.concat(parts, ',') .. ']'
    end
    local keys = {}
    for key in pairs(value) do
        if type(key) ~= 'string' then return nil end
        keys[#keys + 1] = key
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local encoded = canonical_json(value[key], depth + 1)
        if not encoded then return nil end
        parts[#parts + 1] = json.encode(key) .. ':' .. encoded
    end
    return '{' .. table.concat(parts, ',') .. '}'
end

local function copy_without(value, excluded)
    local result = {}
    for key, child in pairs(value) do
        if not excluded[key] then result[key] = child end
    end
    return result
end

local function semantic_path(path)
    local result = {}
    local dynamic = { rect = true, clip_rect = true, local_to_parent = true, coordinate_quality = true }
    for index, segment in ipairs(path or {}) do
        result[index] = copy_without(segment, dynamic)
    end
    return result
end

local function matches_path_digest(path, digest)
    local semantic = canonical_json(semantic_path(path))
    if semantic then
        local semantic_hash, semantic_err = hash.sha256(semantic)
        if not semantic_err and digest == 'sha256:' .. semantic_hash then return true end
    end
    local legacy = canonical_json(path)
    if not legacy then return false end
    local legacy_hash, legacy_err = hash.sha256(legacy)
    return not legacy_err and digest == 'sha256:' .. legacy_hash
end

local function bounded_array(value, maximum, minimum)
    return array(value) and #value <= maximum and #value >= (minimum or 0)
end

local function query_point(value)
    return only_keys(value, { point_id = true, x = true, y = true })
        and nonempty(value.point_id, 128) and finite(value.x) and finite(value.y)
end

local function expand_attention_v2(payload: any, remaining_bytes: number?): (any, string?, number?)
    local limits = codec.ATTENTION_V2_LIMITS
    local invalid = 'invalid compressed Attention context'
    if not only_keys(payload, {
        schema = true, snapshot_id = true, host_instance_id = true, mount_generation = true,
        created_at = true, coordinate_space = true, capture = true, pointer = true,
        focus = true, recent_events = true, candidates = true, omissions = true, path_dictionary = true,
    }) or payload.schema ~= 'wippy.attention.v2'
        or not nonempty(payload.snapshot_id, 128) or not nonempty(payload.host_instance_id, 160)
        or not bounded_array(payload.path_dictionary, limits.dictionary)
        or not bounded_array(payload.candidates, limits.candidates)
        or not bounded_array(payload.recent_events, limits.events)
        or not bounded_array(payload.omissions, limits.omissions)
        or not canonical_json(payload) then
        return nil, invalid
    end
    invalid = 'invalid compressed Attention context: capture'
    local capture = payload.capture
    if not only_keys(capture, { radius_css_px = true, grid_step_css_px = true, sampled_points = true,
        points = true, point_encoding = true, duration_ms = true, complete = true })
        or not finite(capture.radius_css_px) or capture.radius_css_px < 0 or capture.radius_css_px > 100
        or not finite(capture.grid_step_css_px) or capture.grid_step_css_px < 1 or capture.grid_step_css_px > 100
        or not integer(capture.sampled_points, 0) or capture.sampled_points > limits.points
        or (capture.points == nil) == (capture.point_encoding == nil) then
        return nil, invalid
    end
    invalid = 'invalid compressed Attention context: observations'
    local observations = {}
    local function observation(event, focus)
        if type(event) ~= 'table' or not nonempty(event.event_id, 128) then return false end
        if not focus and not bounded_array(event.candidate_ids, limits.candidates) then return false end
        observations[event.event_id] = true
        return true
    end
    if payload.pointer ~= nil and not observation(payload.pointer) then return nil, invalid end
    if payload.focus ~= nil and not observation(payload.focus, true) then return nil, invalid end
    for _, event in ipairs(payload.recent_events) do
        if not observation(event) then return nil, invalid end
    end

    local output = copy_without(payload, { path_dictionary = true, candidates = true, focus = true, capture = true })
    output.schema, output.candidates = 'wippy.attention.v1', {}
    output.capture = copy_without(capture, { point_encoding = true, points = true })
    output.capture.points = {}
    if payload.focus ~= nil then
        if payload.focus.path ~= nil then return nil, invalid end
        output.focus = copy_without(payload.focus, { path_indices = true })
        output.focus.path = {}
    end
    local base = canonical_json(output)
    if not base then return nil, invalid end
    local used = #base
    local budget = math.min(remaining_bytes or limits.expanded_bytes, limits.expanded_bytes)
    local function charge(bytes)
        if bytes > budget - used then return false end
        used = used + bytes
        return true
    end
    if not charge(0) then return nil, 'Attention expansion byte budget exceeded' end

    invalid = 'invalid compressed Attention context: points'
    local point_ids, points = {}, output.capture.points
    local function append_point(point)
        if not query_point(point) or point_ids[point.point_id] or #points >= limits.points
            or observations[point.point_id] then return false end
        local encoded = canonical_json(point)
        if not encoded or not charge(#encoded + (#points > 0 and 1 or 0)) then return false end
        points[#points + 1], point_ids[point.point_id] = point, true
        return true
    end
    if capture.points ~= nil then
        if not bounded_array(capture.points, limits.points) then return nil, invalid end
        for _, point in ipairs(capture.points) do
            if not append_point(point) then return nil, invalid end
        end
    else
        local encoding = capture.point_encoding
        if not only_keys(encoding, { kind = true, origin = true, overrides = true, additional_points = true })
            or encoding.kind ~= 'css-euclidean-grid.v1'
            or not only_keys(encoding.origin, { x = true, y = true })
            or not finite(encoding.origin.x) or not finite(encoding.origin.y)
            or (encoding.overrides ~= nil and not bounded_array(encoding.overrides, limits.points))
            or (encoding.additional_points ~= nil and not bounded_array(encoding.additional_points, limits.points)) then
            return nil, invalid
        end
        local radius = capture.radius_css_px :: number
        local grid_step = capture.grid_step_css_px :: number
        local extent = math.floor(radius / grid_step)
        if (2 * extent + 1) ^ 2 > limits.points then return nil, invalid end
        local overrides = {}
        for _, override in ipairs(encoding.overrides or {}) do
            if not only_keys(override, { index = true, point = true }) or not integer(override.index, 0)
                or override.index >= limits.points or overrides[override.index] or not query_point(override.point) then
                return nil, invalid
            end
            overrides[override.index] = override.point
        end
        local count = 0
        for y = -extent, extent do
            for x = -extent, extent do
                local dx, dy = x * capture.grid_step_css_px, y * capture.grid_step_css_px
                if dx * dx + dy * dy <= capture.radius_css_px * capture.radius_css_px then
                    local point = overrides[count] or { point_id = 'p' .. tostring(count), x = encoding.origin.x + dx, y = encoding.origin.y + dy }
                    if not append_point(point) then return nil, invalid end
                    overrides[count], count = nil, count + 1
                end
            end
        end
        if next(overrides) then return nil, invalid end
        for _, point in ipairs(encoding.additional_points or {}) do
            if not append_point(point, true) then return nil, invalid end
        end
    end
    if #points ~= capture.sampled_points then return nil, invalid end

    invalid = 'invalid compressed Attention context: dictionary'
    local dictionary, encoded_segments, canonical_seen = payload.path_dictionary, {}, {}
    for index, segment in ipairs(dictionary) do
        if not only_keys(segment, { kind = true, mount_id = true, generation = true, label = true,
            panel_id = true, surface_id = true, artifact_id = true, page_id = true, package_id = true,
            tag_name = true, selector_hint = true, frame_origin = true, rect = true, clip_rect = true,
            local_to_parent = true, coordinate_quality = true })
            or not nonempty(segment.kind, 32) or not nonempty(segment.mount_id, 160)
            or not integer(segment.generation, 0) then return nil, invalid end
        local encoded = canonical_json(segment)
        if not encoded or canonical_seen[encoded] then return nil, invalid end
        encoded_segments[index], canonical_seen[encoded] = encoded, true
    end
    local used_segments, next_segment = {}, 1
    local function expand_path(indices)
        if not bounded_array(indices, limits.path, 1) then return nil end
        local path = {}
        for _, index in ipairs(indices) do
            if not integer(index, 0) or index >= #dictionary then return nil end
            local key = index + 1
            if not used_segments[key] then
                if key ~= next_segment then return nil end
                used_segments[key], next_segment = true, next_segment + 1
            end
            if not charge(#encoded_segments[key] + (#path > 0 and 1 or 0)) then return nil end
            path[#path + 1] = dictionary[key]
        end
        return path
    end
    invalid = 'invalid compressed Attention context: candidates'
    local candidate_ids, memberships = {}, 0
    for _, candidate in ipairs(payload.candidates) do
        if not only_keys(candidate, { target_id = true, path_indices = true, rect = true, clip_rect = true,
            sample_refs = true, occluded = true, summary = true, provenance = true, action_ref = true })
            or not nonempty(candidate.target_id, 128) or candidate_ids[candidate.target_id]
            or not bounded_array(candidate.sample_refs, limits.memberships, 1)
            or type(candidate.summary) ~= 'table' or not rect(candidate.rect) then return nil, invalid end
        local expanded = copy_without(candidate, { path_indices = true, sample_refs = true })
        expanded.path, expanded.sample_point_ids = {}, {}
        if not charge(#canonical_json(expanded) + (#output.candidates > 0 and 1 or 0)) then return nil, invalid end
        expanded.path = expand_path(candidate.path_indices)
        if not expanded.path then return nil, invalid end
        local seen = {}
        local function append_sample(id)
            if not id or seen[id] or #expanded.sample_point_ids >= limits.memberships
                or memberships >= limits.total_memberships then return false end
            if not charge(#json.encode(id) + (#expanded.sample_point_ids > 0 and 1 or 0)) then return false end
            expanded.sample_point_ids[#expanded.sample_point_ids + 1], seen[id] = id, true
            memberships = memberships + 1
            return true
        end
        for _, ref in ipairs(candidate.sample_refs) do
            if type(ref) == 'string' then
                if not observations[ref] or not append_sample(ref) then return nil, invalid end
            elseif type(ref) == 'number' then
                if not integer(ref, 0) or ref >= #points or not append_sample(points[ref + 1].point_id) then return nil, invalid end
            else
                if not bounded_array(ref, 2, 2) or not integer(ref[1], 0) or not integer(ref[2], 1)
                    or ref[1] + ref[2] > #points or ref[2] > limits.memberships - #expanded.sample_point_ids
                    or ref[2] > limits.total_memberships - memberships then return nil, invalid end
                for index = ref[1] + 1, ref[1] + ref[2] do
                    if not append_sample(points[index].point_id) then return nil, invalid end
                end
            end
        end
        local action = candidate.action_ref
        if action ~= nil then
            local leaf = expanded.path[#expanded.path]
            if type(action) ~= 'table' or action.snapshot_id ~= payload.snapshot_id
                or action.target_id ~= candidate.target_id or action.host_instance_id ~= payload.host_instance_id
                or action.mount_id ~= leaf.mount_id or action.generation ~= leaf.generation
                or not rect(action.rect) or canonical_json(action.rect) ~= canonical_json(candidate.rect)
                or not matches_path_digest(expanded.path, action.path_digest) then return nil, invalid end
        end
        output.candidates[#output.candidates + 1], candidate_ids[candidate.target_id] = expanded, true
    end
    invalid = 'invalid compressed Attention context: focus'
    if output.focus then
        output.focus.path = expand_path(payload.focus.path_indices)
        if not output.focus.path or (output.focus.candidate_id ~= nil and not candidate_ids[output.focus.candidate_id]) then return nil, invalid end
    end
    if next_segment ~= #dictionary + 1 then return nil, invalid end
    invalid = 'invalid compressed Attention context: links'
    local function linked(event)
        for _, id in ipairs(event.candidate_ids) do
            if not candidate_ids[id] then return false end
        end
        return true
    end
    if payload.pointer and not linked(payload.pointer) then return nil, invalid end
    for _, event in ipairs(payload.recent_events) do
        if not linked(event) then return nil, invalid end
    end
    -- Accounting uses the exact reconstructed canonical representation; this
    -- final equality is a guard against future fields bypassing incremental caps.
    invalid = 'invalid compressed Attention context: accounting'
    local encoded = canonical_json(output)
    if not encoded or #encoded ~= used or #encoded > budget then return nil, invalid end
    return output, nil, used
end

codec.expand_attention_v2 = expand_attention_v2

local v1_path_kinds = {
    host = true, panel = true, artifact = true, page = true, iframe = true,
    ['web-fragment'] = true, ['web-component'] = true, ['shadow-root'] = true, element = true,
}


codec.canonical_json = canonical_json

return codec
