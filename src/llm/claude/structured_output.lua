local claude_client = require("claude_client")
local output = require("output")
local json = require("json")
local hash = require("hash")

-- Create module table for exports
local structured_output = {}

-- Validate schema for completeness and correctness
function structured_output.validate_schema(schema)
    local errors = {}

    -- Check if root is an object
    if schema.type ~= "object" then
        table.insert(errors, "Root schema must be an object type")
    end

    -- Check if additionalProperties is false
    if schema.additionalProperties ~= false then
        table.insert(errors, "Root schema must have additionalProperties: false")
    end

    -- Check if all properties are marked as required
    if schema.properties then
        local properties = {}
        for prop_name, _ in pairs(schema.properties) do
            table.insert(properties, prop_name)
        end

        -- Check if required array exists and contains all properties
        if not schema.required then
            table.insert(errors, "Schema must have a required array listing all properties")
        else
            -- Check if all properties are in required array
            local missing_required = {}
            for _, prop_name in ipairs(properties) do
                local found = false
                for _, req_prop in ipairs(schema.required) do
                    if req_prop == prop_name then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(missing_required, prop_name)
                end
            end

            if #missing_required > 0 then
                table.insert(errors,
                    "The following properties must be marked as required: " .. table.concat(missing_required, ", "))
            end
        end
    end

    return #errors == 0, errors
end

-- Main handler for Claude Structured Output
function structured_output.handler(args)
    -- Validate required arguments
    if not args.model then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Model is required"
        }
    end

    -- Format messages
    local messages = args.messages or {}

    if #messages == 0 then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "No messages provided"
        }
    end

    -- Check for schema
    if not args.schema then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Schema is required for structured output"
        }
    end

    -- Validate the schema
    local schema_valid, schema_errors = structured_output.validate_schema(args.schema)
    if not schema_valid then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Invalid schema: " .. table.concat(schema_errors, "; ")
        }
    end

    -- Configure options
    local options = args.options or {}

    -- Create a tool definition using the schema - standard format for Claude
    local tool = {
        name = "structured_output",
        description = "Generate a structured response based on the provided schema. This tool MUST be used to format the response according to the exact schema specification. The response must be valid JSON that matches all required fields and data types defined in the schema. Use this tool to return a structured, machine-readable response that follows the schema exactly.",
        input_schema = args.schema
    }

    -- Force the model to use this tool - Claude's format
    local tool_choice = {
        type = "tool",
        name = "structured_output"
    }

    -- Add thinking if enabled and supported by the model
    local thinking_enabled = false
    local thinking_effort = nil
    if options.thinking_effort and options.thinking_effort > 0 then
        if args.model:match("claude%-3%-7") or args.model:match("claude%-3%.7") then
            thinking_enabled = true
            thinking_effort = options.thinking_effort
        end
    end

    -- Extract any system messages and convert them to a system parameter
    local system_content = nil
    local processed_messages = {}

    for _, msg in ipairs(messages) do
        if msg.role == "system" then
            -- Collect system message content
            if not system_content then
                -- If we have a string content, use it directly
                if type(msg.content) == "string" then
                    system_content = msg.content
                else
                    -- If content is an array, extract text parts
                    local text = ""
                    for _, part in ipairs(msg.content) do
                        if part.type == "text" then
                            text = text .. part.text
                        end
                    end
                    system_content = text
                end
            else
                -- If we already have system content, append this with a newline
                if type(msg.content) == "string" then
                    system_content = system_content .. "\n" .. msg.content
                else
                    for _, part in ipairs(msg.content) do
                        if part.type == "text" then
                            system_content = system_content .. "\n" .. part.text
                        end
                    end
                end
            end
        else
            -- Keep non-system messages
            table.insert(processed_messages, msg)
        end
    end

    -- Make the Claude API call with tool calling
    local response, err = claude_client.create_message({
        model = args.model,
        messages = processed_messages,
        system = system_content,   -- Pass system content as top-level parameter
        max_tokens = options.max_tokens,
        temperature = options.temperature,
        tools = { tool },
        tool_choice = tool_choice,
        thinking_enabled = thinking_enabled,
        thinking_effort = thinking_effort,
        api_key = args.api_key,
        api_version = args.api_version,
        timeout = args.timeout,
        beta_features = options.beta_features
    })

    -- Handle request errors
    if err then
        return claude_client.map_error(err)
    end

    -- Check response validity
    if not response then
        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Empty response from Claude API"
        }
    end

    -- Extract token usage
    local tokens = nil
    if response.usage then
        tokens = output.usage(
            response.usage.input_tokens or 0,
            response.usage.output_tokens or 0,
            0 -- Claude doesn't report separate thinking tokens
        )
    end

    -- Find tool use content blocks in response
    local tool_use_block = nil
    if response.content then
        for _, block in ipairs(response.content) do
            if block.type == "tool_use" and block.name == "structured_output" then
                tool_use_block = block
                break
            end
        end
    end

    -- If no tool use found, check for error cases and provide helpful debugging
    if not tool_use_block then
        local error_message = "Claude failed to use the structured_output tool. "

        if response.stop_reason then
            error_message = error_message .. "stop_reason: " .. response.stop_reason .. ". "
        end

        -- Check if model returned regular text instead of using the tool
        if response.content and #response.content > 0 then
            local has_text = false

            for _, block in ipairs(response.content) do
                if block.type == "text" and block.text then
                    has_text = true
                    local text_sample = block.text:sub(1, 100)
                    error_message = error_message .. "Model returned text instead of using tool: " .. text_sample
                    if #block.text > 100 then
                        error_message = error_message .. "..."
                    end
                    break
                end
            end

            if not has_text then
                error_message = error_message .. "Response contains content blocks but no text found."
            end
        else
            error_message = error_message .. "Response does not contain any content blocks."
        end

        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = error_message
        }
    end

    -- Parse the tool input as JSON
    local input = tool_use_block.input
    if not input then
        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Tool use block does not contain input."
        }
    end

    -- For Claude API, the input is already a parsed object, not a JSON string
    local result = input

    -- Map finish reason
    local finish_reason = claude_client.FINISH_REASON_MAP[response.stop_reason] or response.stop_reason

    -- Return successful response with the structured result
    return {
        result = result,
        tokens = tokens,
        metadata = response.metadata,
        finish_reason = finish_reason,
        provider = "anthropic",
        model = args.model
    }
end

-- Return the module
return structured_output