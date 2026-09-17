local json = require("json")
local time = require("time")
local codec_v2 = require("codec_v2")

local codec = {}
local MAX_SELECTION_RANGES = 4
local MAX_SELECTION_TEXT_BYTES = 1024

local v1_path_kinds = {
    host = true, panel = true, artifact = true, page = true, iframe = true,
    ['web-fragment'] = true, ['web-component'] = true, ['shadow-root'] = true, element = true,
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

local function copy_without(value: any, excluded: any): table
    local result = {}
    for key, child in pairs(value) do
        if not excluded[key] then result[key] = child end
    end
    return result
end

local function bounded_array(value: any, maximum: number, minimum: number?): boolean
    return array(value) and #value <= maximum and #value >= (minimum or 0)
end

local function optional_string(value, maximum)
    return value == nil or (type(value) == 'string' and #value <= maximum)
end

local function frame_origin(value)
    return value == nil or value == 'about:srcdoc'
        or (type(value) == 'string' and #value > 0 and #value <= 2048
            and (string.match(value, '^http://[^/%?#@]+$') ~= nil
                or string.match(value, '^https://[^/%?#@]+$') ~= nil))
end

local function transform(value)
    if type(value) ~= 'table'
        or not only_keys(value, { matrix = true, convention = true, direction = true })
        or not bounded_array(value.matrix, 16, 16)
        or value.convention ~= 'dommatrix-column-major'
        or value.direction ~= 'local-to-parent' then
        return false
    end
    for _, member in ipairs(value.matrix) do
        if not finite(member) then return false end
    end
    return true
end

local function v1_segment(segment)
    return type(segment) == 'table'
        and only_keys(segment, { kind = true, mount_id = true, generation = true, label = true,
            panel_id = true, surface_id = true, artifact_id = true, page_id = true, package_id = true,
            tag_name = true, selector_hint = true, frame_origin = true, rect = true, clip_rect = true,
            local_to_parent = true, coordinate_quality = true })
        and v1_path_kinds[segment.kind]
        and nonempty(segment.mount_id, 160)
        and integer(segment.generation, 0)
        and optional_string(segment.label, 256)
        and optional_string(segment.panel_id, 128)
        and optional_string(segment.surface_id, 128)
        and optional_string(segment.artifact_id, 128)
        and optional_string(segment.page_id, 128)
        and optional_string(segment.package_id, 256)
        and optional_string(segment.tag_name, 128)
        and optional_string(segment.selector_hint, 512)
        and frame_origin(segment.frame_origin)
        and (segment.rect == nil or rect(segment.rect))
        and (segment.clip_rect == nil or rect(segment.clip_rect))
        and (segment.local_to_parent == nil or transform(segment.local_to_parent))
        and (segment.coordinate_quality == nil or segment.coordinate_quality == 'exact' or segment.coordinate_quality == 'approximate')
end

local function fixed_tuple(value, size)
    if type(value) ~= 'table' or #value ~= size then return false end
    for index = 1, size do
        if value[index] == nil then return false end
    end
    for key in pairs(value) do
        if not integer(key, 1) or key > size then return false end
    end
    return true
end

local v3_attribute_keys = {
    label = true, panel_id = true, surface_id = true, artifact_id = true, page_id = true,
    package_id = true, tag_name = true, selector_hint = true, frame_origin = true,
    rect = true, clip_rect = true, local_to_parent = true, coordinate_quality = true,
}

local function v3_rect(value)
    if not fixed_tuple(value, 4) or not finite(value[1]) or not finite(value[2])
        or not finite(value[3]) or value[3] < 0 or not finite(value[4]) or value[4] < 0 then
        return nil
    end
    return { x = value[1], y = value[2], width = value[3], height = value[4] }
end

local function v3_transform(value)
    if not fixed_tuple(value, 16) then return nil end
    local matrix = {}
    for index = 1, 16 do
        if not finite(value[index]) then return nil end
        matrix[index] = value[index]
    end
    return { matrix = matrix, convention = 'dommatrix-column-major', direction = 'local-to-parent' }
end

local function unpack_attention_v3_dictionary(dictionary)
    if not bounded_array(dictionary, codec_v2.ATTENTION_V2_LIMITS.dictionary) then
        return nil
    end
    local unpacked = {}
    for index, packed in ipairs(dictionary) do
        if not fixed_tuple(packed, 4) or type(packed[4]) ~= 'table' or not only_keys(packed[4], v3_attribute_keys)
            or not nonempty(packed[1], 32) or not nonempty(packed[2], 160) or not integer(packed[3], 0) then
            return nil
        end
        local attrs = packed[4]
        local segment = { kind = packed[1], mount_id = packed[2], generation = packed[3] }
        for key, value in pairs(attrs) do
            if key == 'rect' or key == 'clip_rect' then
                segment[key] = v3_rect(value)
                if not segment[key] then return nil end
            elseif key == 'local_to_parent' then
                segment[key] = v3_transform(value)
                if not segment[key] then return nil end
            else
                segment[key] = value
            end
        end
        if not v1_segment(segment) then return nil end
        unpacked[index] = segment
    end
    return unpacked
end

local function expand_attention_v3(payload: any, remaining_bytes: number?): (any, string?, number?)
    if type(payload) ~= 'table' or payload.schema ~= 'wippy.attention.v3' then
        return nil, 'invalid compressed Attention context: v3 envelope'
    end
    local dictionary = unpack_attention_v3_dictionary(payload.path_dictionary)
    if not dictionary then return nil, 'invalid compressed Attention context: v3 dictionary' end
    local normalized = copy_without(payload, {})
    normalized.schema, normalized.path_dictionary = 'wippy.attention.v2', dictionary
    return codec_v2.expand_attention_v2(normalized, remaining_bytes)
end

codec.expand_attention_v3 = expand_attention_v3

local selection_directions = { none = true, forward = true, backward = true }

local function selection_coordinate_space(value)
    return value == 'host-viewport'
        or (type(value) == 'table'
            and only_keys(value, { mount_id = true, generation = true })
            and nonempty(value.mount_id, 160)
            and integer(value.generation, 0))
end

local function valid_attention_selection(selection)
    if type(selection) ~= 'table'
        or not only_keys(selection, {
            selection_id = true, selected_at = true, kind = true, collapsed = true,
            direction = true, text = true, anchor_path = true, focus_path = true, ranges = true,
        })
        or not nonempty(selection.selection_id, 128)
        or not timestamp(selection.selected_at)
        or selection.kind ~= 'text'
        or selection.collapsed ~= false
        or not selection_directions[selection.direction]
        or type(selection.text) ~= 'string' or #selection.text > MAX_SELECTION_TEXT_BYTES
        or not bounded_array(selection.anchor_path, codec_v2.ATTENTION_V2_LIMITS.path, 1)
        or not bounded_array(selection.focus_path, codec_v2.ATTENTION_V2_LIMITS.path, 1)
        or not bounded_array(selection.ranges, MAX_SELECTION_RANGES) then
        return false
    end
    for _, segment in ipairs(selection.anchor_path) do
        if not v1_segment(segment) then return false end
    end
    for _, segment in ipairs(selection.focus_path) do
        if not v1_segment(segment) then return false end
    end
    for _, range in ipairs(selection.ranges) do
        if type(range) ~= 'table'
            or not only_keys(range, { rect = true, coordinate_space = true })
            or not rect(range.rect)
            or not selection_coordinate_space(range.coordinate_space) then
            return false
        end
    end
    return true
end

local function expand_attention_v4_selection(selection: any, packed_dictionary: any): (any, string?)
    if selection == nil then return nil end
    if type(selection) ~= 'table' then return nil, 'invalid compact Attention selection' end
    if selection.anchor_path ~= nil or selection.focus_path ~= nil then
        return selection
    end
    if not only_keys(selection, {
        selection_id = true, selected_at = true, kind = true, collapsed = true,
        direction = true, text = true, anchor_path_indices = true,
        focus_path_indices = true, ranges = true,
    }) then return nil, 'invalid compact Attention selection' end
    local dictionary = unpack_attention_v3_dictionary(packed_dictionary)
    if not dictionary then return nil, 'invalid compact Attention selection' end
    local function path(indices)
        if not bounded_array(indices, codec_v2.ATTENTION_V2_LIMITS.path) or #indices == 0 then return nil end
        local result = {}
        for _, index in ipairs(indices) do
            if not integer(index, 0) or dictionary[index + 1] == nil then return nil end
            table.insert(result, dictionary[index + 1])
        end
        return result
    end
    local anchor_path, focus_path = path(selection.anchor_path_indices), path(selection.focus_path_indices)
    if not anchor_path or not focus_path then return nil, 'invalid compact Attention selection' end
    local expanded = copy_without(selection, { anchor_path_indices = true, focus_path_indices = true })
    expanded.anchor_path, expanded.focus_path = anchor_path, focus_path
    if not valid_attention_selection(expanded) then return nil, 'invalid compact Attention selection' end
    return expanded
end

local function valid_attention_v4_dictionary_usage(payload)
    local dictionary = payload.path_dictionary
    if type(dictionary) ~= 'table' then return false end
    local seen, next_index = {}, 0
    local function use(indices)
        if type(indices) ~= 'table' then return false end
        for _, index in ipairs(indices) do
            if not integer(index, 0) or dictionary[index + 1] == nil then return false end
            if not seen[index] then
                if index ~= next_index then return false end
                seen[index], next_index = true, next_index + 1
            end
        end
        return true
    end
    for _, candidate in ipairs(payload.candidates or {}) do
        if type(candidate) ~= 'table' or not use(candidate.path_indices) then return false end
    end
    if payload.focus ~= nil and (type(payload.focus) ~= 'table' or not use(payload.focus.path_indices)) then
        return false
    end
    if payload.selection ~= nil then
        if type(payload.selection) ~= 'table'
            or not use(payload.selection.anchor_path_indices)
            or not use(payload.selection.focus_path_indices) then
            return false
        end
    end
    return next_index == #dictionary
end

local function compact_attention_v4_for_v3(payload)
    if type(payload) ~= 'table' or type(payload.path_dictionary) ~= 'table'
        or type(payload.candidates) ~= 'table' then
        return nil, 'invalid compressed Attention context: v4 envelope'
    end

    local dictionary, remap = {}, {}
    local function remap_path(indices)
        if type(indices) ~= 'table' then return nil, 'path' end
        local result = {}
        for _, index in ipairs(indices) do
            if not integer(index, 0) or payload.path_dictionary[index + 1] == nil then return nil, index end
            if remap[index] == nil then
                remap[index] = #dictionary
                dictionary[#dictionary + 1] = payload.path_dictionary[index + 1]
            end
            result[#result + 1] = remap[index]
        end
        return result
    end

    local compact = copy_without(payload, {
        selection = true,
        path_dictionary = true,
        candidates = true,
        focus = true,
    })
    compact.schema, compact.path_dictionary, compact.candidates = 'wippy.attention.v3', dictionary, {}
    for candidate_index, candidate in ipairs(payload.candidates) do
        if type(candidate) ~= 'table' then
            return nil, 'invalid compressed Attention context: v4 candidate ' .. tostring(candidate_index)
        end
        local normalized = copy_without(candidate, { path_indices = true })
        local missing_index
        normalized.path_indices, missing_index = remap_path(candidate.path_indices)
        if not normalized.path_indices then
            return nil, 'invalid compressed Attention context: v4 candidate remap '
                .. tostring(candidate_index) .. ':' .. tostring(missing_index)
        end
        compact.candidates[#compact.candidates + 1] = normalized
    end
    if payload.focus ~= nil then
        compact.focus = copy_without(payload.focus, { path_indices = true })
        local missing_index
        compact.focus.path_indices, missing_index = remap_path(payload.focus.path_indices)
        if not compact.focus.path_indices then
            return nil, 'invalid compressed Attention context: v4 focus remap ' .. tostring(missing_index)
        end
    end
    return compact
end

local function expand_attention_v4(payload: any, remaining_bytes: number?): (any, string?, number?)
    if type(payload) ~= 'table' or payload.schema ~= 'wippy.attention.v4'
        or not valid_attention_v4_dictionary_usage(payload) then
        return nil, 'invalid compressed Attention context: v4 envelope'
    end
    local selection, decode_err = expand_attention_v4_selection(payload.selection, payload.path_dictionary)
    if decode_err then return nil, decode_err end
    local compact_payload
    compact_payload, decode_err = compact_attention_v4_for_v3(payload)
    if not compact_payload then return nil, decode_err end
    local expanded, expansion_err = expand_attention_v3(compact_payload, remaining_bytes)
    if not expanded then return nil, expansion_err end
    expanded.selection = selection
    local expanded_json = codec_v2.canonical_json(expanded)
    local budget = math.min(remaining_bytes or codec_v2.ATTENTION_V2_LIMITS.expanded_bytes,
        codec_v2.ATTENTION_V2_LIMITS.expanded_bytes)
    if not expanded_json or #expanded_json > budget then
        return nil, 'expanded Attention context exceeds the byte limit'
    end
    return expanded, nil, #expanded_json
end

codec.expand_attention_v4 = expand_attention_v4
codec.valid_attention_selection = valid_attention_selection


return codec
