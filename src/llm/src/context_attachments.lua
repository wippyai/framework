local json = require("json")
local hash = require("hash")
local time = require("time")
local base64 = require("base64")
local prompt = require("prompt")
local codec = require("codec")
local attention_renderer = require("attention_renderer")

local DEFAULT_MAX_RENDER_BYTES = 32 * 1024
local MAX_ATTACHMENTS = 8
local VISUAL_MAX_BYTES = 1024 * 1024
local VISUAL_MAX_DIMENSION = 2048
local VISUAL_MAX_PIXELS = 4194304

local context_attachments = {
    ATTENTION_V2_LIMITS = codec.ATTENTION_V2_LIMITS,
    expand_attention_v2 = codec.expand_attention_v2,
    expand_attention_v3 = codec.expand_attention_v3,
    expand_attention_v4 = codec.expand_attention_v4,
}
local handlers = {}

local function handler_key(kind, version)
    return tostring(kind) .. "@" .. tostring(version)
end

local function byte_length(value)
    return #(value or "")
end

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

local function visual_payload(value)
    if type(value) ~= "table"
        or not only_keys(value, {
            schema = true,
            capture_id = true,
            snapshot_id = true,
            host_instance_id = true,
            created_at = true,
            expires_at = true,
            candidate_ids = true,
            region = true,
            media = true,
            reference = true,
            authorization = true,
            redactions_applied = true,
        })
        or value.schema ~= "wippy.attention.visual.v1"
        or not nonempty(value.capture_id, 160)
        or not nonempty(value.snapshot_id, 160)
        or not nonempty(value.host_instance_id, 160)
        or not timestamp(value.created_at)
        or not timestamp(value.expires_at)
        or not array(value.candidate_ids)
        or #value.candidate_ids == 0
        or #value.candidate_ids > 128
        or not rect(value.region)
        or not integer(value.redactions_applied, 0)
        or value.redactions_applied > 4096 then
        return false
    end
    local ids = {}
    for _, candidate_id in ipairs(value.candidate_ids) do
        if not nonempty(candidate_id, 160) or ids[candidate_id] then
            return false
        end
        ids[candidate_id] = true
    end
    local media = value.media
    if type(media) ~= "table"
        or not only_keys(media, { content_type = true, content_bytes = true, content_hash = true, pixel_width = true, pixel_height = true })
        or media.content_type ~= "image/png" and media.content_type ~= "image/webp"
        or not integer(media.content_bytes, 1)
        or media.content_bytes > VISUAL_MAX_BYTES
        or not nonempty(media.content_hash, 71)
        or string.match(media.content_hash, "^sha256:[a-f0-9]+$") == nil
        or #media.content_hash ~= 71
        or not integer(media.pixel_width, 1)
        or media.pixel_width > VISUAL_MAX_DIMENSION
        or not integer(media.pixel_height, 1)
        or media.pixel_height > VISUAL_MAX_DIMENSION
        or media.pixel_width * media.pixel_height > VISUAL_MAX_PIXELS then
        return false
    end
    return type(value.reference) == "table"
        and only_keys(value.reference, { kind = true, opaque_id = true })
        and value.reference.kind == "upload"
        and nonempty(value.reference.opaque_id, 160)
        and type(value.authorization) == "table"
        and only_keys(value.authorization, { scope = true, session_id = true, audience = true, expires_at = true })
        and value.authorization.scope == "session"
        and nonempty(value.authorization.session_id, 160)
        and value.authorization.audience == "agent-context"
        and timestamp(value.authorization.expires_at)
        and value.authorization.expires_at == value.expires_at
end

local function copy_without(value, excluded)
    local result = {}
    for key, child in pairs(value) do
        if not excluded[key] then result[key] = child end
    end
    return result
end

local function visual_handler(attachment, _, options)
    if attachment.content_type ~= "application/json" or type(attachment.content) ~= "string" then
        return nil, "visual attachment content is not JSON"
    end
    local payload, decode_err = json.decode(attachment.content)
    if decode_err or not visual_payload(payload) then
        return nil, "visual attachment content is invalid"
    end
    if type(options.session_id) ~= "string"
        or payload.authorization.session_id ~= options.session_id then
        return nil, "visual attachment is not authorized for this session"
    end
    local expires = time.parse(time.RFC3339, tostring(payload.expires_at))
    if not expires or not expires:after(options.now or time.now()) then
        return nil, "visual attachment has expired"
    end
    if type(options.visual_resolver) ~= "function" then
        return nil, "authorized visual resolver is unavailable"
    end

    local ok, resolved = pcall(options.visual_resolver, {
        reference = payload.reference,
        authorization = payload.authorization,
        media = payload.media,
    })
    if not ok or type(resolved) ~= "table"
        or not only_keys(resolved, { data = true, content_type = true })
        or type(resolved.data) ~= "string"
        or resolved.content_type ~= payload.media.content_type
        or #resolved.data ~= payload.media.content_bytes
        or #resolved.data > VISUAL_MAX_BYTES then
        return nil, "visual dereference was denied or returned invalid data"
    end
    local digest, digest_err = hash.sha256(tostring(resolved.data))
    if digest_err or "sha256:" .. digest ~= payload.media.content_hash then
        return nil, "visual dereference hash mismatch"
    end

    return { prompt.image_base64(resolved.content_type, base64.encode(resolved.data)) }, nil
end

function context_attachments.register(kind, version, handler)
    if type(kind) ~= "string" or kind == "" then
        return nil, "kind is required"
    end
    if type(version) ~= "number" or version < 1 or version % 1 ~= 0 then
        return nil, "version must be a positive integer"
    end
    if type(handler) ~= "function" then
        return nil, "handler must be a function"
    end

    handlers[handler_key(kind, version)] = handler
    return true, nil
end

function context_attachments.supports(kind, version)
    return type(kind) == 'string' and integer(version, 1)
        and handlers[handler_key(kind, version)] ~= nil
end

function context_attachments.render(attachments, options)
    options = copy_without(options or {}, { _attention_expansion = true })
    options._attention_expansion = { remaining = context_attachments.ATTENTION_V2_LIMITS.expanded_bytes }
    local max_bytes = DEFAULT_MAX_RENDER_BYTES
    if finite(options.max_bytes) then
        max_bytes = math.max(0, math.min(math.floor(options.max_bytes), DEFAULT_MAX_RENDER_BYTES))
    end
    local parts = {}
    local diagnostics = {}
    local used_bytes = 0

    if type(attachments) ~= "table" then
        return parts, diagnostics
    end

    for index, attachment in ipairs(attachments) do
        if index > MAX_ATTACHMENTS then
            table.insert(diagnostics, { code = "attachment_limit", attachment_id = attachment.attachment_id })
            break
        end

        local handler = handlers[handler_key(attachment.kind, attachment.version)]
        if not handler then
            table.insert(diagnostics, { code = "unsupported", attachment_id = attachment.attachment_id })
        else
            local rendered_parts, err = handler(attachment, max_bytes - used_bytes, options)
            if err then
                table.insert(diagnostics, { code = "render_failed", attachment_id = attachment.attachment_id, message = err })
            else
                for _, part in ipairs(rendered_parts or {}) do
                    if part.type == prompt.CONTENT_TYPE.TEXT then
                        used_bytes = used_bytes + byte_length(part.text)
                    end
                    table.insert(parts, part)
                end
            end
        end
    end

    return parts, diagnostics
end

context_attachments.register("wippy.attention", 1, attention_renderer.handle)
context_attachments.register("wippy.attention", 2, attention_renderer.handle)
context_attachments.register("wippy.attention", 3, attention_renderer.handle)
context_attachments.register("wippy.attention", 4, attention_renderer.handle)
context_attachments.register("wippy.attention.visual", 1, visual_handler)

return context_attachments
