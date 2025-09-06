local uuid = require("uuid")
local json = require("json")
local consts = require("consts")

-- Default dependencies
local default_deps = {
    data_reader = require("data_reader")
}

local iterator = {}

---Remap template configuration to use iteration UUIDs
---@param config table|nil Original template config
---@param uuid_mapping table<string, string> Map of template_id -> actual_node_id
---@return table Remapped configuration
function iterator.remap_template_config(config, uuid_mapping)
    if not config then
        return {}
    end

    local remapped = {}
    for k, v in pairs(config) do
        remapped[k] = v
    end

    if config.data_targets then
        remapped.data_targets = {}
        for _, target in ipairs(config.data_targets) do
            local remapped_target = {}
            for tk, tv in pairs(target) do
                remapped_target[tk] = tv
            end

            if target.node_id and uuid_mapping[target.node_id] then
                remapped_target.node_id = uuid_mapping[target.node_id]
            end

            table.insert(remapped.data_targets, remapped_target)
        end
    end

    if config.error_targets then
        remapped.error_targets = {}
        for _, target in ipairs(config.error_targets) do
            local remapped_target = {}
            for tk, tv in pairs(target) do
                remapped_target[tk] = tv
            end

            if target.node_id and uuid_mapping[target.node_id] then
                remapped_target.node_id = uuid_mapping[target.node_id]
            end

            table.insert(remapped.error_targets, remapped_target)
        end
    end

    return remapped
end

---@class IterationInfo
---@field iteration number Index of this iteration (1-based)
---@field input_item any The input item for this iteration
---@field uuid_mapping table<string, string> Map of template_id -> actual_node_id
---@field root_nodes table Array of root node IDs created for this iteration
---@field child_path table List of ancestor node IDs for child nodes

---Create nodes for a single iteration
---@param parent_node any Parent node instance
---@param template_graph any Template graph instance
---@param input_item any Input item for this iteration
---@param iteration_index number Index of this iteration
---@param iteration_input_key string Key to use for iteration input
---@param deps table|nil Optional dependencies for testing
---@return IterationInfo
function iterator.create_iteration(parent_node, template_graph, input_item, iteration_index, iteration_input_key, deps)
    deps = deps or default_deps

    local uuid_mapping = {}
    for template_id, _ in pairs(template_graph.nodes) do
        uuid_mapping[template_id] = uuid.v7()
    end

    local child_path = {}
    for _, ancestor_id in ipairs(parent_node.path or {}) do
        table.insert(child_path, ancestor_id)
    end
    table.insert(child_path, parent_node.node_id)

    local root_nodes = {}
    local template_roots = template_graph:get_roots()

    for template_id, template in pairs(template_graph.nodes) do
        local actual_node_id = uuid_mapping[template_id]

        local remapped_config = iterator.remap_template_config(template.config, uuid_mapping)

        -- Merge original template metadata with iteration metadata
        local merged_metadata = {}

        -- Copy original template metadata if it exists
        if template.metadata then
            for k, v in pairs(template.metadata) do
                merged_metadata[k] = v
            end
        end

        -- Add iteration-specific metadata
        merged_metadata.iteration = iteration_index
        merged_metadata.template_source = template_id

        -- Handle title with iteration suffix
        if merged_metadata.title then
            merged_metadata.title = merged_metadata.title .. " (#" .. iteration_index .. ")"
        end

        parent_node:command({
            type = consts.COMMAND_TYPES.CREATE_NODE,
            payload = {
                node_id = actual_node_id,
                node_type = template.type,
                parent_node_id = parent_node.node_id,
                status = consts.STATUS.PENDING,
                config = remapped_config,
                metadata = merged_metadata
            }
        })

        local is_root = false
        for _, root_template_id in ipairs(template_roots) do
            if template_id == root_template_id then
                is_root = true
                break
            end
        end

        if is_root then
            table.insert(root_nodes, actual_node_id)

            parent_node:data(consts.DATA_TYPE.NODE_INPUT, input_item, {
                node_id = actual_node_id,
                key = iteration_input_key
            })
        end
    end

    return {
        iteration = iteration_index,
        input_item = input_item,
        uuid_mapping = uuid_mapping,
        root_nodes = root_nodes,
        child_path = child_path
    }
end

---Create a batch of iterations
---@param parent_node any Parent node instance
---@param template_graph any Template graph instance
---@param items table Array of input items
---@param batch_start number Start index (1-based)
---@param batch_end number End index (1-based, inclusive)
---@param iteration_input_key string Key to use for iteration input
---@param deps table|nil Optional dependencies for testing
---@return table|nil iterations Array of IterationInfo or nil on error
---@return string|nil error Error message if failed
function iterator.create_batch(parent_node, template_graph, items, batch_start, batch_end, iteration_input_key, deps)
    deps = deps or default_deps

    if not parent_node or not template_graph or not items then
        return nil, "Missing required parameters"
    end

    if batch_start < 1 or batch_end > #items or batch_start > batch_end then
        return nil, "Invalid batch range"
    end

    local iterations = {}

    for i = batch_start, batch_end do
        local iteration_info = iterator.create_iteration(
            parent_node, template_graph, items[i], i, iteration_input_key, deps
        )
        table.insert(iterations, iteration_info)
    end

    return iterations, nil
end

---Parse content based on content type
---@param content any Raw content from database
---@param content_type string Content type indicator
---@return any Parsed content
local function parse_content(content, content_type)
    -- Parse JSON content if needed
    if (content_type == consts.CONTENT_TYPE.JSON or content_type == "application/json")
       and type(content) == "string" then
        local parsed, err = json.decode(content)
        if not err then
            return parsed
        else
            -- If JSON parsing fails, return original content
            return content
        end
    end

    return content
end

---Collect results from an iteration (FIXED VERSION with JSON parsing)
---@param parent_node any Parent node instance
---@param iteration_info IterationInfo Iteration information
---@param deps table|nil Optional dependencies for testing
---@return any|nil result Iteration result or nil on error
---@return string|nil error Error message if failed
function iterator.collect_results(parent_node, iteration_info, deps)
    deps = deps or default_deps

    local iteration_node_ids = {}
    for _, actual_node_id in pairs(iteration_info.uuid_mapping) do
        table.insert(iteration_node_ids, actual_node_id)
    end

    local reader, reader_err = deps.data_reader.with_dataflow(parent_node.dataflow_id)
    if reader_err then
        return nil, "Failed to create data reader: " .. reader_err
    end

    local output_data, query_err = reader
        :with_nodes(iteration_node_ids)
        :with_data_types(consts.DATA_TYPE.NODE_OUTPUT)
        :fetch_options({ replace_references = true })
        :all()

    if query_err then
        return nil, "Failed to query output data: " .. query_err
    end

    if #output_data == 0 then
        return nil, "No output data found for iteration"
    end

    local results = {}
    for _, output in ipairs(output_data) do
        -- FIXED: Parse content based on content_type
        local parsed_content = parse_content(output.content, output.content_type)

        table.insert(results, {
            key = output.key,
            content = parsed_content,  -- Now properly parsed
            node_id = output.node_id,
            discriminator = output.discriminator
        })
    end

    if #results == 1 then
        return results[1].content, nil  -- Returns parsed content
    else
        return results, nil
    end
end

return iterator