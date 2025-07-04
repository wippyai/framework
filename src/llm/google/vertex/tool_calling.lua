local json = require("json")
local vertex = require("vertex_client")
local output = require("output")
local tools = require("tools") -- Assuming 'tools.lua' handles tool schema resolution by ID
local prompt_mapper = require("prompt_mapper")

-- Create module table
local tool_handler = {}

-- Remove elements that are not supported by Vertex
local function filter_schema(schema)
    local function recursive_filter(obj)
        if type(obj) ~= "table" then
            return obj
        end

        obj.multipleOf = nil

        for key, value in pairs(obj) do
            if type(value) == "table" then
                obj[key] = recursive_filter(value)
            end
        end

        return obj
    end

    schema.examples = nil

    return recursive_filter(schema)
end

-- Main handler function
function tool_handler.handler(args)
    -- Validate required arguments
    if not args or not args.model then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Model is required in arguments"
        }
    end

    -- Initialize messages safely
    local messages_internal = args.messages or {}
    if #messages_internal == 0 then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "No messages provided"
        }
    end

    -- Map messages to Vertex AI format using the prompt mapper
    -- This now returns TWO values
    local contents, system_instruction = prompt_mapper.map_to_vertex(messages_internal)

    -- Configure options objects for easier management
    local options = args.options or {}

    -- Configure request payload
    local payload = {
        contents = contents,
        -- systemInstruction added below if present
        generationConfig = {
            -- Include common options, filter out nil values later
            stopSequences = options.stop_sequences,
            maxOutputTokens = options.max_tokens,
            temperature = options.temperature,
            topP = options.top_p,
            seed = options.seed,
            presencePenalty = options.presence_penalty,
        }
    }

    -- Add system instruction if generated by the mapper
    if system_instruction then
        payload.systemInstruction = system_instruction
    end

    -- Clean up nil values from generationConfig
    local cleaned_gen_config = {}
    for key, value in pairs(payload.generationConfig) do
        if value ~= nil then
            cleaned_gen_config[key] = value
        end
    end
    -- Only include generationConfig if it's not empty
    if next(cleaned_gen_config) then
        payload.generationConfig = cleaned_gen_config
    else
        payload.generationConfig = nil
    end

    -- Process tool schemas (either from tool_ids or direct tool_schemas)
    local request_tools = {}       -- For payload.tools[1].functionDeclarations
    local tool_name_to_id_map = {} -- Map tool names back to our internal registry IDs

    -- Helper to add a tool schema to the request list if valid
    local function add_tool_to_request(id, tool_schema)
        -- Basic validation of the provided schema structure
        if tool_schema and type(tool_schema) == "table" and
            tool_schema.name and type(tool_schema.name) == "string" and
            tool_schema.schema and type(tool_schema.schema) == "table" then
            table.insert(request_tools, {
                name = tool_schema.name,
                description = tool_schema.description or "", -- Ensure description is string or empty
                parameters = filter_schema(tool_schema.schema)
            })
            -- Remember the mapping from tool name to internal ID for response processing
            tool_name_to_id_map[tool_schema.name] = tool.registry_id or id
        else
            -- Log or handle error for invalid tool schema?
            print("Warning: Invalid or incomplete tool schema provided for ID: " .. tostring(id))
            return false -- Indicate failure
        end
        return true      -- Indicate success
    end

    -- If tool IDs are provided, resolve them using the 'tools' library
    if args.tool_ids and type(args.tool_ids) == "table" and #args.tool_ids > 0 then
        -- Assuming tools.get_tool_schemas returns { id1 = schema1, ... }, { id2 = error2, ... }
        local resolved_schemas, errors = tools.get_tool_schemas(args.tool_ids)

        -- Handle errors during schema resolution
        if errors and next(errors) then
            local err_msg_parts = {}
            for id, err in pairs(errors) do
                table.insert(err_msg_parts, id .. " (" .. tostring(err) .. ")")
            end
            return {
                error = output.ERROR_TYPE.INVALID_REQUEST,
                error_message = "Failed to resolve tool schemas: " .. table.concat(err_msg_parts, ", ")
            }
        end

        -- Add resolved tools to the request list
        if resolved_schemas then
            for id, schema in pairs(resolved_schemas) do
                if not add_tool_to_request(id, schema) then
                    -- Option to fail early if any schema is invalid
                    -- return { error = output.ERROR_TYPE.INVALID_REQUEST, error_message = "Invalid schema found for tool ID: " .. id }
                end
            end
        end
    end

    -- If tool schemas are provided directly, use them
    if args.tool_schemas and type(args.tool_schemas) == "table" and next(args.tool_schemas) then
        for id, tool in pairs(args.tool_schemas) do
            if not add_tool_to_request(id, tool) then
                -- Option to fail early
                -- return { error = output.ERROR_TYPE.INVALID_REQUEST, error_message = "Invalid schema provided directly for tool ID: " .. id }
            end
        end
    end

    -- Add tools configuration to payload if any valid tools were defined
    if #request_tools > 0 then
        -- Vertex expects tools wrapped in an outer array
        payload.tools = {
            { functionDeclarations = request_tools }
        }

        -- Set tool_choice (toolConfig in Vertex) based on args.tool_call
        local tool_config = { functionCallingConfig = {} } -- Initialize inner table
        local mode_set = false

        if args.tool_call == "none" then
            tool_config.functionCallingConfig.mode = "NONE"
            mode_set = true
        elseif args.tool_call == "auto" or args.tool_call == "any" or not args.tool_call then
            -- Treat "any", "auto", or nil/missing as AUTO (let the model decide)
            tool_config.functionCallingConfig.mode = "AUTO"
            mode_set = true
        elseif type(args.tool_call) == "string" then -- Specific tool name expected
            local specific_tool_name = args.tool_call
            local found = false
            for _, func_decl in ipairs(request_tools) do
                if func_decl.name == specific_tool_name then
                    found = true
                    break
                end
            end

            if not found then
                return {
                    error = output.ERROR_TYPE.INVALID_REQUEST,
                    error_message = "Specified tool_call name '" ..
                    specific_tool_name .. "' not found in the provided function declarations."
                }
            else
                -- Force calling this specific function
                tool_config.functionCallingConfig.mode = "ANY" -- ANY mode allows specifying allowed functions
                tool_config.functionCallingConfig.allowedFunctionNames = { specific_tool_name }
                mode_set = true
            end
        else
            -- Invalid tool_call value (e.g., a table, number)
            return {
                error = output.ERROR_TYPE.INVALID_REQUEST,
                error_message = "Invalid tool_call value type: " .. type(args.tool_call)
            }
        end

        -- Only add toolConfig to payload if a specific mode was determined
        if mode_set then
            payload.toolConfig = tool_config
        end
        -- Else: No tools defined, so no payload.tools or payload.toolConfig needed
    end

    -- Make the API request using the vertex client library
    local request_options = {
        timeout = args.timeout or 120,
        location = args.location or nil,
        project = args.project or nil
    }

    local response, err = vertex.request(
        vertex.DEFAULT_GENERATE_CONTENT_ENDPOINT,
        args.model,
        payload,
        request_options
    )

    -- Handle client/request errors using the centralized mapper
    if err then
        if vertex.map_error then
            return vertex.map_error(err)
        else
            return { error = output.ERROR_TYPE.SERVER_ERROR, error_message = err.message or "Vertex client error" }
        end
    end

    -- Check response validity and structure
    if not response or not response.candidates or #response.candidates == 0 then
        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Invalid or empty response structure from Vertex AI"
        }
    end

    -- Process the first candidate (tool calling usually uses the first)
    local first_candidate = response.candidates[1]

    -- Check finish reason early for critical issues like safety
    local finish_reason_key = first_candidate.finishReason or "UNKNOWN"
    local mapped_finish_reason = vertex.FINISH_REASON_MAP[finish_reason_key] or output.FINISH_REASON.UNKNOWN

    if mapped_finish_reason == output.FINISH_REASON.CONTENT_FILTER then
        return {
            error = output.ERROR_TYPE.CONTENT_FILTER,
            error_message = "Response blocked due to safety filters (Reason: " .. finish_reason_key .. ")",
            finish_reason = mapped_finish_reason,
            provider = "vertex",
            model = args.model,
            metadata = response.metadata
        }
    elseif mapped_finish_reason == output.FINISH_REASON.ERROR then
        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Vertex AI reported an error (Reason: " .. finish_reason_key .. ")",
            finish_reason = mapped_finish_reason,
            provider = "vertex",
            model = args.model,
            metadata = response.metadata
        }
    end

    -- Validate candidate content structure before processing parts
    if not first_candidate.content or not first_candidate.content.parts then
        -- Check if finish reason gives a clue (e.g., MAX_TOKENS before content)
        if mapped_finish_reason == output.FINISH_REASON.LENGTH then
            return {
                error = output.ERROR_TYPE.SERVER_ERROR,  -- Or maybe INVALID_RESPONSE?
                error_message = "Invalid candidate content structure (no parts) despite finish reason: MAX_TOKENS",
                finish_reason = mapped_finish_reason,
                provider = "vertex",
                model = args.model,
                metadata = response.metadata
            }
        else
            return {
                error = output.ERROR_TYPE.SERVER_ERROR,
                error_message = "Invalid candidate content structure (no parts) in Vertex AI response"
            }
        end
    end

    -- Extract token usage information
    local tokens = nil
    if response.usageMetadata then
        tokens = output.usage(
            response.usageMetadata.promptTokenCount or 0,
            response.usageMetadata.candidatesTokenCount or 0,
            response.usageMetadata.thoughtsTokenCount or 0,
            0, -- cache_write_tokens
            0  -- cache_read_tokens
        )
    end

    -- Process response parts: extract text and function calls
    local tool_calls_extracted = {}
    local content_text = ""

    for _, part in ipairs(first_candidate.content.parts) do
        if part.text then
            content_text = content_text .. part.text
        elseif part.functionCall then
            local function_call = part.functionCall
            -- Basic validation of the received function call part
            if function_call and function_call.name then
                local arguments = function_call.args or {} -- Default to empty table if args is nil/missing

                -- Generate a unique-enough ID for this call within this response
                local call_id = (function_call.name or "func") .. "_" .. os.time() .. "_" .. math.random(1000, 9999)

                table.insert(tool_calls_extracted, {
                    id = call_id,                                         -- Generate an ID as Vertex doesn't provide one here
                    name = function_call.name,
                    arguments = arguments,                                -- Arguments should already be a table from Vertex
                    registry_id = tool_name_to_id_map[function_call.name] -- Add back our internal ID if found
                })
            else
                -- Log warning about malformed function call part?
                print("Warning: Received malformed functionCall part from Vertex: " .. json.encode(part))
            end
        end
    end

    -- Determine the final outcome based on whether tool calls were extracted
    if #tool_calls_extracted > 0 then
        -- If tool calls were generated, the logical finish reason is TOOL_CALL
        return {
            result = {
                content = content_text, -- Include any text generated alongside the tool call
                tool_calls = tool_calls_extracted
            },
            tokens = tokens,
            metadata = response.metadata or {},             -- Ensure metadata exists
            finish_reason = output.FINISH_REASON.TOOL_CALL, -- Standardized reason
            provider = "vertex",
            model = args.model
        }
    else
        -- No tool calls, treat as a standard text response
        -- Use the finish reason reported by the API (already mapped)
        return {
            result = content_text,
            tokens = tokens,
            metadata = response.metadata or {},   -- Ensure metadata exists
            finish_reason = mapped_finish_reason, -- Use the mapped reason from the API
            provider = "vertex",
            model = args.model
        }
    end
end

-- Return the module table containing the handler
return tool_handler
