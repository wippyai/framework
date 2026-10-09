local models = require("models")
local providers = require("providers")
local contract = require("contract")
local security = require("security")
local evaluation = require("evaluation")
local route = require("route")
local fallback = require("fallback")
local output = require("output")
local time = require("time")
local logger = require("logger")

type Message = {
    role: string,
    content: any,
    name: string?,
    function_call: table?,
    function_call_id: string?,
    metadata: table?
}

type ToolCall = {
    id: string?,
    name: string,
    arguments: any
}

type TokenUsage = {
    prompt_tokens: number?,
    completion_tokens: number?,
    thinking_tokens: number?,
    total_tokens: number?,
    cache_read_input_tokens: number?,
    cache_read_tokens: number?,
    cache_creation_input_tokens: number?,
    cache_write_tokens: number?,
    context_tokens: number?
}

type UsageRecord = {
    usage_id: string
}

type GenerateResponse = {
    result: any,
    tokens: TokenUsage,
    finish_reason: string?,
    metadata: table?,
    tool_calls: {ToolCall}?,
    usage_record: UsageRecord?
}

type EmbedResponse = {
    result: {number} | {{number}},
    model: string?,
    tokens: TokenUsage,
    finish_reason: string?,
    metadata: table?,
    usage_record: UsageRecord?
}

type EvaluationSlot = {
    type: "choice" | "predicate" | "score",
    instructions: string | table,
    domain: any?
}

type EvaluationQuestions = { [string]: EvaluationSlot }

type ChoiceReading = {
    type: "choice",
    choice: string,
    probabilities: { [string]: number },
    confidence: number?
}

type PredicateReading = {
    type: "predicate",
    probability: number
}

type ScoreReading = {
    type: "score",
    score: number,
    level: number,
    probabilities: {number},
    confidence: number?
}

type EvaluationReading = ChoiceReading | PredicateReading | ScoreReading

type EvaluationResponse = {
    result: { [string]: EvaluationReading },
    tokens: table?,
    metadata: table?,
    usage_record: table?
}

type StatusResponse = {
    available: boolean?,
    latency: number?,
    model: string?
}

type ProviderRef = {
    id: string,
    provider_model: string?,
    context: table?,
    thinking: "adaptive" | "budget" | "none" | nil,
    sampling: boolean?,
    forced_tool_choice: boolean?,
    structured_output: "native" | "tool" | nil,
    options: table?,
    priority: number?
}

type ModelCard = {
    id: string,
    name: string,
    title: string,
    description: string,
    capabilities: {string},
    class: {string},
    priority: number,
    max_tokens: number,
    output_tokens: number,
    pricing: table,
    providers: {ProviderRef},
    dimensions: number?,
    fallback: {string}?,
    fallback_on: {string}?
}

type ModelClass = {
    id: string,
    name: string?,
    title: string?,
    description: string?
}


type GenerateOptions = {
    model: string,
    provider_id: string?,
    user: string?,
    tools: table?,
    tool_choice: any?,
    stream: boolean?,
    temperature: number?,
    max_tokens: number?,
    fallback: any?,
    route: table?,
    deadline_ms: number?
}

type EmbedOptions = {
    model: string,
    provider_id: string?,
    user: string?,
    dimensions: number?
}

type EvaluationOptions = {
    model: string,
    provider_id: string?,
    user: string?,
    timeout: number?,
    retry: table?
}

type StatusOptions = {
    model: string,
    provider_id: string?,
    user: string?
}

type TrackingOptions = {
    timestamp: number?,
    metadata: table?
}

type FailureEntry = {
    model: string,
    provider_id?: string,
    provider_model?: string,
    error_type?: string,
    message?: string,
    skipped?: boolean
}

type PromptInput = string | {Message} | table


local llm = {}

-- Contract constants
local USAGE_TRACKER_CONTRACT = "wippy.llm:usage_tracker"
local MODEL_RESOLVER_CONTRACT = "wippy.llm:model_resolver"
local CALL_OPTIONS = fallback.set_of({ "fallback", "route", "deadline_ms" })

-- Dependency injection fields
llm._models = nil
llm._providers = nil
llm._usage_tracker = nil
llm._model_resolver = nil
llm._clock = nil

---------------------------
-- Internal Helper Functions
---------------------------

-- Optional model/provider resolver contract. When a binding exists it is tried
-- before the built-in registry-backed discovery; with no binding this returns nil
-- and resolution is unchanged. Mirrors the usage_tracker contract handling.
local function get_model_resolver(): any?
    if llm._model_resolver then
        return llm._model_resolver
    end

    local resolver_contract, err = contract.get(MODEL_RESOLVER_CONTRACT)
    if not err and resolver_contract then
        local instance, open_err = resolver_contract:open()
        if not open_err and instance then
            llm._model_resolver = instance
            return instance
        end
    end

    return nil
end

-- Cached input under the contract names, falling back to provider-specific names.
local function cached_input_tokens(tokens: TokenUsage): (number, number)
    local read = tokens.cache_read_input_tokens or tokens.cache_read_tokens or 0
    local write = tokens.cache_creation_input_tokens or tokens.cache_write_tokens or 0
    return read, write
end

local function current_ms(): number
    local clock: any = llm._clock
    if clock then
        return clock()
    end

    return math.floor(time.now():unix_nano() / 1000000)
end

-- Smart model resolution: name → class → error, plus "class:abc" syntax.
-- An optional resolver contract takes precedence when bound; if it returns no
-- card, resolution falls back to the built-in discovery below.
function llm.resolve_model(model_identifier: string): (ModelCard?, string?)
    local resolver = get_model_resolver()
    if resolver then
        local card, resolve_err = resolver:resolve({ model = model_identifier })
        if card and not resolve_err then
            return card :: ModelCard
        end
        -- resolver declined or errored: fall through to built-in discovery
    end

    local models_module = llm._models or models

    -- Check for explicit class syntax "class:abc"
    local class_name = model_identifier:match("^class:(.+)")
    if class_name then
        local class_models, err = models_module.get_by_class(class_name)
        if err then
            return nil, err
        end
        if class_models and #class_models > 0 then
            return class_models[1] -- First model (highest priority)
        end
        return nil, "No models found for class: " .. class_name
    end

    -- Try as model name first
    local model_card, err = models_module.get_by_name(model_identifier)
    if model_card then
        return model_card :: ModelCard
    end

    -- Try as class name
    local class_models, class_err = models_module.get_by_class(model_identifier)
    if not class_err and class_models and #class_models > 0 then
        return class_models[1] -- First model (highest priority)
    end

    return nil, "Model or class not found: " .. model_identifier
end

-- Convert prompt input to messages array in contract format
local function prepare_messages(prompt_input)
    if type(prompt_input) == "table" and prompt_input.build and type(prompt_input.build) == "function" then
        local prompt_result = prompt_input:build()
        return prompt_result.messages
    elseif type(prompt_input) == "table" and prompt_input.messages then
        return prompt_input.messages
    elseif type(prompt_input) == "table" and prompt_input.get_messages and type(prompt_input.get_messages) == "function" then
        return prompt_input:get_messages()
    elseif type(prompt_input) == "table" and #prompt_input > 0 then
        return prompt_input
    elseif type(prompt_input) == "string" then
        return {
            {
                role = "user",
                content = { { type = "text", text = prompt_input } }
            }
        }
    else
        return nil, "Invalid prompt input format"
    end
end

-- Normalize contract response to LLM format
local function normalize_response(raw_result)
    if not raw_result then
        return nil
    end

    local tokens = (raw_result.tokens or {}) :: TokenUsage
    local cache_read, cache_write = cached_input_tokens(tokens)
    tokens.context_tokens = (tokens.prompt_tokens or 0) + cache_read + cache_write

    local normalized = {
        tokens = tokens,
        finish_reason = raw_result.finish_reason,
        metadata = raw_result.metadata or {}
    }

    if raw_result.result then
        if type(raw_result.result) == "table" then
            if raw_result.result.content ~= nil then
                -- Generation response with content + tool_calls
                normalized.result = raw_result.result.content  -- Use 'result' not 'content'
                normalized.tool_calls = raw_result.result.tool_calls or {}
            elseif raw_result.result.data then
                -- Structured output response
                normalized.result = raw_result.result.data  -- Use 'result' not 'content'
            elseif raw_result.result.embeddings then
                -- Embeddings response
                normalized.result = raw_result.result.embeddings
            elseif raw_result.result.readings then
                -- Evaluation response: one reading per declared slot
                normalized.result = raw_result.result.readings
            else
                normalized.result = raw_result.result
            end
        else
            normalized.result = raw_result.result
        end
    elseif raw_result.content then
        -- Direct content field (fallback)
        normalized.result = raw_result.content
        normalized.tool_calls = raw_result.tool_calls or {}
    elseif raw_result.data then
        -- Direct data field (fallback)
        normalized.result = raw_result.data
    elseif raw_result.embeddings then
        -- Direct embeddings field (fallback)
        normalized.result = raw_result.embeddings
    end

    return normalized
end

-- Get usage tracker contract (cache it when opened)
local function get_usage_tracker()
    if llm._usage_tracker then
        return llm._usage_tracker
    end

    -- Try to get usage tracker contract if available
    local tracker_contract, err = contract.get(USAGE_TRACKER_CONTRACT)
    if not err and tracker_contract then
        local instance, open_err = tracker_contract:open()
        if not open_err then
            llm._usage_tracker = instance
            return instance
        end
    end

    return nil -- No usage tracking available
end

-- Returns a shallow copy of the caller's options with the actor id set as
-- `user`. The caller's table is never written to.
local function options_for_actor(options)
    local copy = {}
    for k, v in pairs(options) do
        copy[k] = v
    end

    local actor = security.actor()
    if actor then
        copy.user = actor:id()
    end

    return copy
end

-- Merge provider options into contract arguments
local function merge_provider_options(contract_args, provider_info)
    if provider_info and provider_info.options then
        for k, v in pairs(provider_info.options) do
            if k == "tools" or k == "tool_choice" or k == "stream" then
                contract_args[k] = v
            else
                contract_args.options[k] = v
            end
        end
    end
    if provider_info and provider_info.id then
        contract_args._provider_id = provider_info.id
    end
end

local function provider_open_context(provider_info)
    local merged = {}
    if provider_info and type(provider_info.context) == "table" then
        for k, v in pairs(provider_info.context) do
            merged[k] = v
        end
    end
    if provider_info and type(provider_info.options) == "table" then
        for k, v in pairs(provider_info.options) do
            merged[k] = v
        end
    end
    return merged
end

local function open_provider(providers_module, provider_info)
    return providers_module.open(provider_info.id, provider_open_context(provider_info))
end

-- Merge user options into contract arguments. On resolved-model calls the
-- model_profile (what the configured model accepts on the wire) comes only from
-- the model's provider options, so callers exclude it here.
local function merge_user_options(contract_args, user_options, exclude_keys)
    exclude_keys = exclude_keys or {}

    for k, v in pairs(user_options) do
        local should_exclude = CALL_OPTIONS[k] == true
        for _, exclude_key in ipairs(exclude_keys) do
            if k == exclude_key then
                should_exclude = true
                break
            end
        end

        if not should_exclude then
            if k == "tools" or k == "tool_choice" or k == "stream" then
                contract_args[k] = v
            else
                contract_args.options[k] = v
            end
        end
    end
end

local function apply_provider_transport(contract_args, provider_info)
    local context = provider_info and provider_info.context
    if type(context) ~= "table" then return end
    if contract_args.timeout == nil and context.timeout ~= nil then
        contract_args.timeout = context.timeout
    end
end

local function hoist_transport_options(contract_args)
    local opts = contract_args.options
    if type(opts) ~= "table" then return end
    if opts.timeout ~= nil then
        contract_args.timeout = opts.timeout
        opts.timeout = nil
    end
    if opts.retry ~= nil then
        contract_args.retry = opts.retry
        opts.retry = nil
    end
end

---------------------------
-- Constants (Backward Compatibility)
---------------------------

llm.CAPABILITY = {
    GENERATE = "generate",
    TOOL_USE = "tool_use",
    STRUCTURED_OUTPUT = "structured_output",
    EMBED = "embed",
    EVALUATE = "evaluate",
    THINKING = "thinking",
    VISION = "vision",
    CACHING = "caching"
}

llm.ERROR_TYPE = output.ERROR_TYPE

llm.FINISH_REASON = {
    STOP = "stop",
    LENGTH = "length",
    CONTENT_FILTER = "filtered",
    TOOL_CALL = "tool_call",
    ERROR = "error"
}

---------------------------
-- Public API Methods
---------------------------

local function output_limit(card: any): number?
    if type(card) ~= "table" then
        return nil
    end
    local limit = tonumber(card.output_tokens)
    if limit ~= nil and limit > 0 then
        return limit
    end
    return nil
end

local function prepare_route(contract_args, provider_info: any, options, providers_module, card: any?)
    local legacy_reasoning_flag, flag_err = providers_module.driver_declares_legacy_reasoning_flag(provider_info.id)
    if flag_err then return nil, flag_err end
    local accepts, err = route.accepts(provider_info :: table, options,
        options.provider_id and "direct" or "resolved", legacy_reasoning_flag :: boolean?)
    if not accepts then return nil, err end
    contract_args.accepts = accepts
    contract_args.options = route.clean_options(contract_args.options)
    local strict = contract_args.options.strict == true
    contract_args.options.strict = nil
    contract_args._strict = strict
    local adjusted: { [string]: any } = {}
    local function remove(key)
        local value = contract_args.options[key]
        if value ~= nil then
            adjusted[key] = { requested = value }
            contract_args.options[key] = nil
        end
    end
    if accepts.sampling == false then
        remove("temperature")
        remove("top_p")
        remove("top_k")
    end
    if accepts.thinking == "none" and (contract_args.options.thinking_effort or 0) > 0 then
        remove("thinking_effort")
    end

    local limit = output_limit(card)
    local requested = tonumber(contract_args.options.max_tokens)
    if limit ~= nil and requested ~= nil and requested > limit then
        adjusted.max_tokens = { requested = requested, sent = limit }
        contract_args.options.max_tokens = limit
    end

    local strict_err = route.strict_error(tostring(provider_info.id), strict, adjusted)
    if strict_err then return nil, strict_err end

    return adjusted, nil
end

-- The forced tool choice rule is provider-agnostic: a route declaring
-- forced_tool_choice = false rejects a caller tool_choice of "any" or a tool
-- name, unless the caller permits sending it as "auto" instead. Only
-- llm.generate takes a caller tool_choice; structured output always forces
-- its own extraction tool internally.
local function apply_forced_tool_choice(contract_args): (table?, string?)
    local accepts = contract_args.accepts
    if not accepts or accepts.forced_tool_choice ~= false then return nil, nil end
    if not contract_args.tools or #contract_args.tools == 0 then return nil, nil end
    local choice = contract_args.tool_choice
    if choice == nil or choice == "auto" or choice == "none" then return nil, nil end

    if contract_args.options.tool_choice_fallback == "auto" then
        contract_args.tool_choice = "auto"
        return { requested = choice, sent = "auto" }, nil
    end

    return nil, "Model does not accept a forced tool choice (forced_tool_choice = false): tool_choice '"
        .. tostring(choice) .. "' needs tool_choice_fallback = \"auto\" from a caller that enforces tool use itself"
end

local function merge_adjustments(raw_result, adjusted)
    if not raw_result or next(adjusted) == nil then return end
    raw_result.metadata = raw_result.metadata or {}
    local merged = raw_result.metadata.adjusted or {}
    for key, value in pairs(adjusted) do
        if merged[key] then
            merged[key].requested = value.requested
        else
            merged[key] = value
        end
    end
    raw_result.metadata.adjusted = merged
end

-- Reports the "any" / named tool_choice a route could not honor, sent as
-- "auto" instead, the same shape merge_adjustments gives metadata.adjusted.
local function merge_tool_choice(raw_result, tool_choice)
    if not raw_result or not tool_choice then return end
    raw_result.metadata = raw_result.metadata or {}
    raw_result.metadata.tool_choice = tool_choice
end

local function call_deadline(options): number?
    local budget: number = tonumber(options.deadline_ms) or 0
    if budget <= 0 then
        return nil
    end

    return current_ms() + budget
end

local function stream_target(contract_args): any?
    local stream = contract_args.stream
    if type(stream) == "table" and stream.reply_to ~= nil then
        return stream
    end

    return nil
end

local function emit_deferred_error(stream: any?, details: any?)
    if stream == nil or details == nil or details.deferred_error_type == nil then
        return
    end

    local streamer = output.streamer(tostring(stream.reply_to), tostring(stream.topic), stream.buffer_size or 10)
    if streamer then
        streamer:send_error(tostring(details.deferred_error_type), tostring(details.deferred_error_message or ""), nil)
    end
end

local function log_failure(options, message: string)
    logger:named("llm"):error("llm call failed", {
        model = options.model,
        provider = options.provider_id,
        error = message
    })
end

local function card_name(card: any): string
    return tostring(card.name or card.id)
end

local function declares_capability(card: any, capability: string): boolean
    if type(card.capabilities) ~= "table" then
        return false
    end

    for _, declared in ipairs(card.capabilities) do
        if declared == capability then
            return true
        end
    end

    return false
end

local function execute(spec, candidate: any, options, deadline_at: number?, providers_module)
    local route_info = candidate.route
    local open_context = {}

    if not candidate.direct then
        open_context = provider_open_context(route_info)
    end

    if deadline_at ~= nil then
        open_context.deadline_at = deadline_at
    end

    local provider_instance, open_err = providers_module.open(route_info.id, open_context)
    if not provider_instance then
        return nil, { preflight = true, message = "Failed to open provider: " .. (open_err or "unknown error") }
    end

    local wire_model = candidate.direct and options.model or route_info.provider_model
    local contract_args = spec.build(wire_model, candidate.card)

    if not candidate.direct then
        -- Provider options first (from the model card), caller options on top.
        merge_provider_options(contract_args, route_info)
        apply_provider_transport(contract_args, route_info)
    end

    merge_user_options(contract_args, options, candidate.direct and spec.direct_exclude or spec.exclude)
    hoist_transport_options(contract_args)

    if candidate.direct then
        contract_args._provider_id = route_info.id
    end

    if deadline_at ~= nil then
        contract_args.timeout = fallback.capped_timeout(contract_args.timeout, deadline_at - current_ms())
    end

    local state = nil
    if spec.prepare then
        local prepared, prepare_err = spec.prepare(contract_args, route_info, options, providers_module, candidate.card)
        if prepare_err ~= nil then
            return nil, { preflight = true, message = tostring(prepare_err) }
        end
        state = prepared
    end

    -- Each candidate gets fresh contract arguments; the messages table is
    -- shared, which is safe because a contract call hands the driver a copy.
    local raw_result, err = (provider_instance as any)[spec.method](provider_instance, contract_args)
    if spec.finish then
        spec.finish(raw_result, state)
    end
    if err then
        return nil, {
            message = fallback.error_message(err),
            details = fallback.error_details(err),
            stream = stream_target(contract_args)
        }
    end

    local normalized = normalize_response(raw_result)
    if not normalized then
        return nil, { message = "Failed to normalize provider response" }
    end

    if spec.complete then
        spec.complete(normalized, raw_result, wire_model)
    end

    return normalized
end

-- Calls the caller's provider_id directly: no model resolution, no fallback.
local function call_direct(spec, options)
    if spec.before then
        local before_err = spec.before()
        if before_err then
            return nil, before_err
        end
    end

    local candidate = { route = { id = options.provider_id }, primary = true, direct = true }
    local result, failure = execute(spec, candidate, options, call_deadline(options), llm._providers or providers)
    if result then
        local usage_id = llm.track_usage(result, options.model, options)
        if usage_id then
            result.usage_record = { usage_id = usage_id }
        end
        return result
    end

    emit_deferred_error(failure.stream, failure.details)
    log_failure(options, failure.message)
    return nil, failure.message
end

local function fallback_references(spec, options, model_card): {string}
    if not spec.model_fallback or options.fallback == false or options.route ~= nil then
        return {}
    end

    if type(options.fallback) == "table" then
        return fallback.string_list(options.fallback) or {}
    end

    return fallback.string_list(model_card.fallback) or {}
end

local function plan(spec, model_card, first_routes: {any}, references: {string}, failures: {FailureEntry})
    local seen: { [string]: boolean } = {}
    seen[card_name(model_card)] = true
    local card = model_card
    local routes = first_routes
    local route_index = 0
    local reference_index = 0
    local produced = 0

    return function(): any?
        while produced < fallback.MAX_CANDIDATES do
            route_index = route_index + 1
            local next_route = routes[route_index]
            if next_route ~= nil then
                produced = produced + 1
                return { card = card, route = next_route, primary = produced == 1 }
            end

            reference_index = reference_index + 1
            local reference = references[reference_index]
            if reference == nil then
                return nil
            end

            local resolved, resolve_err = llm.resolve_model(reference)
            if not resolved then
                local skipped: FailureEntry = { model = reference, skipped = true, message = tostring(resolve_err or "model not found") }
                table.insert(failures, skipped)
            elseif not seen[card_name(resolved)] then
                seen[card_name(resolved)] = true
                local eligible, reason = spec.eligible(resolved)
                if not eligible then
                    local skipped: FailureEntry = { model = card_name(resolved), skipped = true, message = tostring(reason) }
                    table.insert(failures, skipped)
                else
                    card = resolved
                    routes = fallback.ordered_routes(resolved)
                    route_index = 0
                    if #routes == 0 then
                        local skipped: FailureEntry = { model = card_name(resolved), skipped = true, message = "no configured providers" }
                        table.insert(failures, skipped)
                    end
                end
            end
        end
        return nil
    end
end

local function fail_chain(options, failures: {FailureEntry}, last: any?)
    local message = "No usable route for model: " .. tostring(options.model)

    if last ~= nil then
        message = tostring(last.message)
        emit_deferred_error(last.stream, last.details)
    end

    if #failures > 1 then
        message = message .. " (fallback: " .. fallback.summary(failures) .. ")"
    end

    log_failure(options, message)
    return nil, message
end

local function run_chain(spec, options, model_card, first_routes: {any})
    local providers_module = llm._providers or providers
    local deadline_at = call_deadline(options)
    local fallback_on = fallback.switch_set(model_card.fallback_on)
    local failures: {FailureEntry} = {}
    local next_candidate = plan(spec, model_card, first_routes, fallback_references(spec, options, model_card), failures)
    local last: any = nil

    while true do
        local candidate = next_candidate()
        if candidate == nil then
            break
        end

        local entry: FailureEntry = {
            model = card_name(candidate.card),
            provider_id = tostring(candidate.route.id)
        }

        if candidate.route.provider_model ~= nil then
            entry.provider_model = tostring(candidate.route.provider_model)
        end

        if not candidate.primary and deadline_at ~= nil
            and deadline_at - current_ms() < fallback.MIN_FALLBACK_BUDGET_MS then
            entry.skipped = true
            entry.message = "call budget exhausted"
            table.insert(failures, entry)
            break
        end

        local result, failure = execute(spec, candidate, options, deadline_at, providers_module)
        if result then
            result.metadata.route = {
                model = entry.model,
                provider_id = entry.provider_id,
                provider_model = entry.provider_model
            }
            if #failures > 0 then
                result.metadata.fallbacks = failures
            end

            local usage_id = llm.track_usage(result, entry.model, options)
            if usage_id then
                result.usage_record = { usage_id = usage_id }
            end

            return result
        end

        if failure.preflight then
            if candidate.primary then
                -- A primary route the call cannot use fails the call, as before fallback.
                log_failure(options, failure.message)
                return nil, failure.message
            end
            entry.skipped = true
            entry.message = failure.message
            table.insert(failures, entry)
        else
            local details = failure.details
            entry.error_type = details and details.error_type or nil
            entry.message = failure.message
            table.insert(failures, entry)
            last = failure
            if not fallback.should_switch(details, candidate.primary, failure.stream ~= nil, fallback_on) then
                break
            end
        end
    end

    return fail_chain(options, failures, last)
end

local function call_resolved(spec, options)
    local model_card, first_routes
    if options.route ~= nil then
        local pin = options.route
        if type(pin) ~= "table" or type(pin.model) ~= "string" or pin.model == ""
            or type(pin.provider_id) ~= "string" or pin.provider_id == "" then
            return nil, "options.route requires model and provider_id"
        end

        local resolve_err
        model_card, resolve_err = llm.resolve_model(pin.model)
        if not model_card then
            return nil, resolve_err
        end

        local provider_model: string? = nil
        if type(pin.provider_model) == "string" then
            provider_model = tostring(pin.provider_model)
        end

        local pinned = fallback.find_route(model_card, tostring(pin.provider_id), provider_model)
        if not pinned then
            return nil, "Route not found: " .. pin.model .. " via " .. pin.provider_id
        end
        first_routes = { pinned }
    else
        local resolve_err
        model_card, resolve_err = llm.resolve_model(options.model :: string)
        if not model_card then
            return nil, resolve_err
        end
    end

    if spec.check then
        local check_err = spec.check(model_card)
        if check_err then
            return nil, check_err
        end
    end

    if not model_card.providers or #model_card.providers == 0 then
        return nil, "Model has no configured providers: " .. options.model
    end
    if first_routes == nil then
        first_routes = fallback.ordered_routes(model_card)
        if options.fallback == false then
            first_routes = { first_routes[1] }
        end
    end
    if #first_routes == 0 then
        return nil, "Model has no configured providers: " .. options.model
    end

    if spec.before then
        local before_err = spec.before()
        if before_err then
            return nil, before_err
        end
    end

    return run_chain(spec, options, model_card, first_routes)
end

local function always_eligible(_card): (boolean, string?)
    return true, nil
end

local function prepare_route_facts(contract_args, provider_info, options, providers_module, card)
    local adjusted, route_err = prepare_route(contract_args, provider_info, options, providers_module, card)
    if not adjusted then
        return nil, route_err
    end

    return { adjusted = adjusted }, nil
end

local function call(spec, options)
    if options.provider_id then
        -- A direct call bypasses the catalog, so a pin on a catalog route is a caller bug.
        if options.route ~= nil then
            return nil, "options.route cannot be combined with provider_id"
        end
        return call_direct(spec, options)
    end

    return call_resolved(spec, options)
end

function llm.generate(prompt_input, options)
    if not options or type(options.model) ~= "string" or options.model == "" then
        return nil, "Model is required in options"
    end

    options = options_for_actor(options)

    local messages = nil
    local result, err = call({
        method = "generate",
        exclude = { "model", "model_profile" },
        direct_exclude = { "model", "provider_id" },
        model_fallback = true,
        eligible = always_eligible,
        before = function(): string?
            local prepared, prepare_err = prepare_messages(prompt_input)
            if not prepared then
                return prepare_err
            end
            messages = prepared
            return nil
        end,
        build = function(wire_model, _card)
            return { messages = messages, model = wire_model, options = {} }
        end,
        prepare = function(contract_args, provider_info, call_options, providers_module, card)
            local adjusted, route_err = prepare_route(contract_args, provider_info, call_options, providers_module, card)
            if not adjusted then
                return nil, route_err
            end
            local tool_choice, tool_choice_err = apply_forced_tool_choice(contract_args)
            if tool_choice_err then
                return nil, tool_choice_err
            end
            return { adjusted = adjusted, tool_choice = tool_choice }, nil
        end,
        finish = function(raw_result, state)
            merge_adjustments(raw_result, state.adjusted)
            merge_tool_choice(raw_result, state.tool_choice)
        end
    }, options)

    return result :: GenerateResponse?, err
end

function llm.structured_output(schema, prompt_input, options): (GenerateResponse?, string?)
    if not options or type(options.model) ~= "string" or options.model == "" then
        return nil, "Model is required in options"
    end

    if not schema then
        return nil, "Schema is required"
    end

    options = options_for_actor(options)

    local messages = nil
    local result, err = call({
        method = "structured_output",
        exclude = { "model", "schema", "model_profile" },
        direct_exclude = { "model", "provider_id", "schema" },
        model_fallback = true,
        eligible = always_eligible,
        before = function(): string?
            local prepared, prepare_err = prepare_messages(prompt_input)
            if not prepared then
                return prepare_err
            end
            messages = prepared
            return nil
        end,
        build = function(wire_model, _card)
            return { messages = messages, model = wire_model, schema = schema, options = {} }
        end,
        prepare = prepare_route_facts,
        finish = function(raw_result, state)
            merge_adjustments(raw_result, state.adjusted)
        end
    }, options)

    return result :: GenerateResponse?, err
end

function llm.embed(text, options)
    if not options or type(options.model) ~= "string" or options.model == "" then
        return nil, "Model is required in options"
    end

    options = options_for_actor(options)

    local result, err = call({
        method = "embed",
        exclude = { "model", "dimensions", "model_profile" },
        direct_exclude = { "model", "provider_id" },
        model_fallback = false,
        eligible = always_eligible,
        build = function(wire_model, card)
            local contract_args = { input = text, model = wire_model, options = {} }
            if options.dimensions then
                contract_args.options.dimensions = options.dimensions
            elseif card and card.dimensions then
                contract_args.options.dimensions = card.dimensions
            end
            return contract_args
        end,
        complete = function(normalized, raw_result, wire_model)
            normalized.model = raw_result.model or wire_model
        end
    }, options)

    return result :: EmbedResponse?, err
end

function llm.evaluate(state, questions, options): (EvaluationResponse?, string?)
    if not options or type(options.model) ~= "string" or options.model == "" then
        return nil, "Model is required in options"
    end

    local questions_err = evaluation.validate(state, questions, options.model)
    if questions_err then
        return nil, questions_err
    end

    options = options_for_actor(options)

    local result, err = call({
        method = "evaluate",
        exclude = { "model", "model_profile" },
        direct_exclude = { "model", "provider_id" },
        model_fallback = true,
        check = function(card): string?
            if not declares_capability(card, llm.CAPABILITY.EVALUATE) then
                return "Model does not declare the evaluate capability: " .. card_name(card)
            end
            return nil
        end,
        eligible = function(card): (boolean, string?)
            if declares_capability(card, llm.CAPABILITY.EVALUATE) then
                return true, nil
            end
            return false, "does not declare the evaluate capability"
        end,
        build = function(wire_model, _card)
            return { state = state, questions = questions, model = wire_model, options = {} }
        end
    }, options)

    return result :: EvaluationResponse?, err
end

function llm.status(options)
    if not options or type(options.model) ~= "string" or options.model == "" then
        return nil, "Model is required in options"
    end

    options = options_for_actor(options)

    local contract_args = { model = options.model, options = {} }
    local provider_info = nil

    if options.provider_id then
        provider_info = { id = options.provider_id, options = {} }
    else
        local model_card, err = llm.resolve_model(options.model :: string)
        if not model_card then
            return nil, err
        end

        -- Get first provider (highest priority)
        if not model_card.providers or #model_card.providers == 0 then
            return nil, "Model has no configured providers: " .. options.model
        end
        provider_info = model_card.providers[1] as any
        merge_provider_options(contract_args, provider_info)
        apply_provider_transport(contract_args, provider_info)
    end

    local providers_module = llm._providers or providers
    local provider_instance, err = open_provider(providers_module, provider_info)
    if not provider_instance then
        return nil, "Failed to open provider: " .. (err or "unknown error")
    end

    merge_user_options(contract_args, options, {"model", "provider_id"})
    hoist_transport_options(contract_args)

    local result, err = (provider_instance as any):status(contract_args)

    return result :: StatusResponse, err
end

function llm.available_models(capability: string?): ({ModelCard}?, string?)
    local models_module = llm._models or models
    local all_models, err = models_module.get_all()
    if not all_models then
        return nil, err
    end

    if not capability then
        return all_models :: {ModelCard}
    end

    -- Filter by capability
    local filtered = {}
    for _, model in ipairs(all_models) do
        if model.capabilities then
            for _, cap in ipairs(model.capabilities) do
                if cap == capability then
                    table.insert(filtered, model)
                    break
                end
            end
        end
    end

    return filtered :: {ModelCard}
end

function llm.get_classes(): ({ModelClass}?, string?)
    local models_module = llm._models or models
    local result, err = models_module.get_all_classes()
    if err then
        return nil, err
    end
    return result :: {ModelClass}
end

function llm.track_usage(response, model_id, options): (string?, string?)
    local tracker = get_usage_tracker()
    if not tracker then
        -- No usage tracking available
        return nil, nil
    end

    options = options or {}

    -- Extract token information from response
    local prompt_tokens = 0
    local completion_tokens = 0
    local thinking_tokens = 0
    local cache_read_tokens = 0
    local cache_write_tokens = 0

    if response and response.tokens then
        prompt_tokens = response.tokens.prompt_tokens or 0
        completion_tokens = response.tokens.completion_tokens or 0
        thinking_tokens = response.tokens.thinking_tokens or 0
        cache_read_tokens, cache_write_tokens = cached_input_tokens(response.tokens)
    end

    -- Prepare tracking options
    local tracking_options = {}

    if options.timestamp then
        tracking_options.timestamp = options.timestamp
    end

    if options.metadata then
        tracking_options.metadata = options.metadata
    end

    -- Call usage tracker contract
    local usage_id, err = tracker:track_usage(
        model_id,
        prompt_tokens,
        completion_tokens,
        thinking_tokens,
        cache_read_tokens,
        cache_write_tokens,
        tracking_options
    )

    return usage_id :: string, err
end

return llm
