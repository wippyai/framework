local map_reduce = {}

-- Exposed dependencies for testing
map_reduce._deps = {
    node = require("node"),
    template_graph = require("template_graph"),
    iterator = require("iterator"),
    funcs = require("funcs")
}

-- Constants
map_reduce.DEFAULTS = {
    BATCH_SIZE = 1,
    ITERATION_INPUT_KEY = "default",
    FAILURE_STRATEGY = "fail_fast"
}

map_reduce.FAILURE_STRATEGIES = {
    FAIL_FAST = "fail_fast",
    IGNORE_FAILURES = "ignore_failures",
    COLLECT_ERRORS = "collect_errors"
}

map_reduce.ITEM_PIPELINE_STEPS = {
    MAP = "map",
    FILTER = "filter"
}

map_reduce.REDUCTION_PIPELINE_STEPS = {
    MAP = "map",
    FILTER = "filter",
    GROUP = "group",
    REDUCE_GROUPS = "reduce_groups",
    AGGREGATE = "aggregate",
    FLATTEN = "flatten"
}

map_reduce.EXTRACTORS = {
    SUCCESSES = "successes",
    FAILURES = "failures",
    ALL = "all"
}

map_reduce.ERRORS = {
    MISSING_SOURCE_ARRAY_KEY = "MISSING_SOURCE_ARRAY_KEY",
    NO_INPUT_DATA = "NO_INPUT_DATA",
    NO_TEMPLATES = "NO_TEMPLATES",
    INVALID_INPUT_STRUCTURE = "INVALID_INPUT_STRUCTURE",
    ITERATION_FAILED = "ITERATION_FAILED",
    PIPELINE_FAILED = "PIPELINE_FAILED",
    ITEM_PIPELINE_FAILED = "ITEM_PIPELINE_FAILED",
    TEMPLATE_DISCOVERY_FAILED = "TEMPLATE_DISCOVERY_FAILED",
    INVALID_FAILURE_STRATEGY = "INVALID_FAILURE_STRATEGY",
    INVALID_BATCH_SIZE = "INVALID_BATCH_SIZE",
    INVALID_PIPELINE_STEP = "INVALID_PIPELINE_STEP",
    INVALID_EXTRACTOR = "INVALID_EXTRACTOR",
    INCOMPATIBLE_PIPELINE_DATA = "INCOMPATIBLE_PIPELINE_DATA"
}

-- Built-in extractors that convert map-reduce structures to business data
local extractors = {
    [map_reduce.EXTRACTORS.SUCCESSES] = function(map_reduce_result)
        local items = {}
        for _, success in ipairs(map_reduce_result.successes or {}) do
            table.insert(items, success.result)
        end
        return items
    end,

    [map_reduce.EXTRACTORS.FAILURES] = function(map_reduce_result)
        local items = {}
        for _, failure in ipairs(map_reduce_result.failures or {}) do
            table.insert(items, {
                item = failure.item,
                error = failure.error,
                iteration = failure.iteration
            })
        end
        return items
    end,

    [map_reduce.EXTRACTORS.ALL] = function(map_reduce_result)
        local items = {}
        for _, success in ipairs(map_reduce_result.successes or {}) do
            table.insert(items, {
                type = "success",
                iteration = success.iteration,
                item = success.item,
                result = success.result
            })
        end
        for _, failure in ipairs(map_reduce_result.failures or {}) do
            table.insert(items, {
                type = "failure",
                iteration = failure.iteration,
                item = failure.item,
                error = failure.error
            })
        end
        return items
    end
}

local function get_extractor_output_type(extract_name)
    if extract_name == map_reduce.EXTRACTORS.SUCCESSES or
       extract_name == map_reduce.EXTRACTORS.FAILURES or
       extract_name == map_reduce.EXTRACTORS.ALL then
        return "array"
    else
        return "unknown"
    end
end

local function validate_failure_strategy(strategy)
    return strategy == map_reduce.FAILURE_STRATEGIES.FAIL_FAST or
        strategy == map_reduce.FAILURE_STRATEGIES.IGNORE_FAILURES or
        strategy == map_reduce.FAILURE_STRATEGIES.COLLECT_ERRORS
end

local function validate_batch_size(size)
    return type(size) == "number" and size > 0 and size <= 1000
end

local function validate_extractor(extract_name)
    return extractors[extract_name] ~= nil
end

local function validate_item_pipeline_step(step)
    if not step or type(step) ~= "table" then
        return false, "Step must be a table"
    end

    if not step.type then
        return false, "Step must have a type"
    end

    if step.type ~= map_reduce.ITEM_PIPELINE_STEPS.MAP and
       step.type ~= map_reduce.ITEM_PIPELINE_STEPS.FILTER then
        return false, "Item pipeline only supports 'map' and 'filter' steps"
    end

    if not step.func_id then
        return false, "Item pipeline step requires func_id"
    end

    -- Validate per-step context
    if step.context and type(step.context) ~= "table" then
        return false, "Step context must be a table if provided"
    end

    return true, nil
end

local function validate_reduction_pipeline_step(step, expected_data_type)
    if not step or type(step) ~= "table" then
        return false, "Step must be a table"
    end

    if not step.type then
        return false, "Step must have a type"
    end

    local valid_types = {
        [map_reduce.REDUCTION_PIPELINE_STEPS.MAP] = true,
        [map_reduce.REDUCTION_PIPELINE_STEPS.FILTER] = true,
        [map_reduce.REDUCTION_PIPELINE_STEPS.GROUP] = true,
        [map_reduce.REDUCTION_PIPELINE_STEPS.REDUCE_GROUPS] = true,
        [map_reduce.REDUCTION_PIPELINE_STEPS.AGGREGATE] = true,
        [map_reduce.REDUCTION_PIPELINE_STEPS.FLATTEN] = true
    }

    if not valid_types[step.type] then
        return false, "Invalid reduction pipeline step type: " .. step.type
    end

    if step.type == map_reduce.REDUCTION_PIPELINE_STEPS.MAP or
       step.type == map_reduce.REDUCTION_PIPELINE_STEPS.FILTER or
       step.type == map_reduce.REDUCTION_PIPELINE_STEPS.GROUP then
        if expected_data_type == "object" then
            return false, "Step type '" .. step.type .. "' requires array input, but previous step produces object. Use 'aggregate' step instead."
        end
    end

    if step.type == map_reduce.REDUCTION_PIPELINE_STEPS.GROUP then
        if not step.key_func_id then
            return false, "Group step requires key_func_id"
        end
    else
        if not step.func_id then
            return false, "Step type " .. step.type .. " requires func_id"
        end
    end

    -- Validate per-step context
    if step.context and type(step.context) ~= "table" then
        return false, "Step context must be a table if provided"
    end

    return true, nil
end

local function validate_reduction_pipeline_flow(extract_name, pipeline_steps)
    if not pipeline_steps or #pipeline_steps == 0 then
        return true, nil
    end

    local current_data_type = get_extractor_output_type(extract_name)

    for i, step in ipairs(pipeline_steps) do
        local valid, err = validate_reduction_pipeline_step(step, current_data_type)
        if not valid then
            return false, "Pipeline step " .. i .. ": " .. err
        end

        if step.type == map_reduce.REDUCTION_PIPELINE_STEPS.GROUP then
            current_data_type = "grouped_object"
        elseif step.type == map_reduce.REDUCTION_PIPELINE_STEPS.REDUCE_GROUPS then
            current_data_type = "object"
        elseif step.type == map_reduce.REDUCTION_PIPELINE_STEPS.AGGREGATE or
               step.type == map_reduce.REDUCTION_PIPELINE_STEPS.FLATTEN then
            current_data_type = "any"
        end
    end

    return true, nil
end

local function execute_item_pipeline_step(step, data)
    local step_type = step.type

    -- Create executor with per-step context
    local executor = map_reduce._deps.funcs.new()
    if step.context then
        executor = executor:with_context(step.context)
    end

    if step_type == map_reduce.ITEM_PIPELINE_STEPS.MAP then
        return executor:call(step.func_id, data)
    elseif step_type == map_reduce.ITEM_PIPELINE_STEPS.FILTER then
        local keep, err = executor:call(step.func_id, data)
        if err then
            return nil, "Filter step failed: " .. err
        end
        return keep and data or nil, nil
    else
        return nil, "Unknown item pipeline step type: " .. step_type
    end
end

local function execute_reduction_pipeline_step(step, data)
    local step_type = step.type

    if step_type == map_reduce.REDUCTION_PIPELINE_STEPS.MAP then
        if type(data) ~= "table" or #data == 0 then
            local item_executor = map_reduce._deps.funcs.new()
            local merged_context = {}

            -- Merge step context if available
            if step.context then
                for k, v in pairs(step.context) do
                    merged_context[k] = v
                end
            end
            merged_context.current_item = data

            item_executor = item_executor:with_context(merged_context)
            return item_executor:call(step.func_id, data)
        end

        local results = table.create(#data, 0)
        for i, item in ipairs(data) do
            local item_executor = map_reduce._deps.funcs.new()
            local merged_context = {}

            -- Merge step context if available
            if step.context then
                for k, v in pairs(step.context) do
                    merged_context[k] = v
                end
            end
            merged_context.current_item = item
            merged_context.item_index = i

            item_executor = item_executor:with_context(merged_context)

            local transformed, err = item_executor:call(step.func_id, item)
            if err then
                return nil, "Map step failed: " .. err
            end
            results[i] = transformed
        end
        return results, nil

    elseif step_type == map_reduce.REDUCTION_PIPELINE_STEPS.FILTER then
        if type(data) ~= "table" or #data == 0 then
            local item_executor = map_reduce._deps.funcs.new()
            local merged_context = {}

            if step.context then
                for k, v in pairs(step.context) do
                    merged_context[k] = v
                end
            end
            merged_context.current_item = data

            item_executor = item_executor:with_context(merged_context)

            local keep, err = item_executor:call(step.func_id, data)
            if err then
                return nil, "Filter step failed: " .. err
            end
            return keep and data or {}, nil
        end

        local results = table.create(#data, 0)
        local result_count = 0
        for i, item in ipairs(data) do
            local item_executor = map_reduce._deps.funcs.new()
            local merged_context = {}

            if step.context then
                for k, v in pairs(step.context) do
                    merged_context[k] = v
                end
            end
            merged_context.current_item = item
            merged_context.item_index = i

            item_executor = item_executor:with_context(merged_context)

            local keep, err = item_executor:call(step.func_id, item)
            if err then
                return nil, "Filter step failed: " .. err
            end
            if keep then
                result_count = result_count + 1
                results[result_count] = item
            end
        end
        return results, nil

    else
        -- For all other step types, create base executor with step context
        local base_executor = map_reduce._deps.funcs.new()
        if step.context then
            base_executor = base_executor:with_context(step.context)
        end

        if step_type == map_reduce.REDUCTION_PIPELINE_STEPS.GROUP then
            local data_to_group = data
            if type(data) ~= "table" or #data == 0 then
                data_to_group = { data }
            end

            local groups = {}
            for _, item in ipairs(data_to_group) do
                local key, err = base_executor:call(step.key_func_id, item)
                if err then
                    return nil, "Group step failed: " .. err
                end
                key = tostring(key)
                if not groups[key] then
                    groups[key] = table.create(10, 0)
                end
                local group = groups[key]
                group[#group + 1] = item
            end
            return groups, nil

        elseif step_type == map_reduce.REDUCTION_PIPELINE_STEPS.REDUCE_GROUPS then
            if type(data) ~= "table" then
                return data, nil
            end

            local results = {}
            for key, items in pairs(data) do
                local reduced, err = base_executor:call(step.func_id, key, items)
                if err then
                    return nil, "Reduce groups step failed: " .. err
                end
                results[key] = reduced
            end
            return results, nil

        elseif step_type == map_reduce.REDUCTION_PIPELINE_STEPS.AGGREGATE then
            local result, err = base_executor:call(step.func_id, data)
            if err then
                return nil, "Aggregate step failed: " .. err
            end
            return result, nil

        elseif step_type == map_reduce.REDUCTION_PIPELINE_STEPS.FLATTEN then
            local result, err = base_executor:call(step.func_id, data)
            if err then
                return nil, "Flatten step failed: " .. err
            end
            return result, nil

        else
            return nil, "Unknown reduction pipeline step type: " .. step_type
        end
    end
end

local function execute_item_pipeline(item_steps, iteration_result)
    if not item_steps or type(item_steps) ~= "table" or #item_steps == 0 then
        return iteration_result, nil
    end

    local current_data = iteration_result
    for i, step in ipairs(item_steps) do
        local step_result, step_err = execute_item_pipeline_step(step, current_data)
        if step_err then
            return nil, "Item pipeline step " .. i .. " (" .. step.type .. ") failed: " .. step_err
        end

        if step.type == map_reduce.ITEM_PIPELINE_STEPS.FILTER and step_result == nil then
            return nil, nil
        end

        current_data = step_result
    end

    return current_data, nil
end

local function execute_reduction_pipeline(reduction_extract, reduction_steps, map_reduce_results)
    if not reduction_extract then
        return map_reduce_results, nil
    end

    if not validate_extractor(reduction_extract) then
        return nil, "Invalid extractor: " .. reduction_extract .. ". Valid options: " ..
                   map_reduce.EXTRACTORS.SUCCESSES .. ", " ..
                   map_reduce.EXTRACTORS.FAILURES .. ", " ..
                   map_reduce.EXTRACTORS.ALL
    end

    local extractor = extractors[reduction_extract]
    local business_data = extractor(map_reduce_results)

    if not reduction_steps or type(reduction_steps) ~= "table" or #reduction_steps == 0 then
        return business_data, nil
    end

    local current_data = business_data
    for i, step in ipairs(reduction_steps) do
        local step_result, step_err = execute_reduction_pipeline_step(step, current_data)
        if step_err then
            return nil, "Reduction pipeline step " .. i .. " (" .. step.type .. ") failed: " .. step_err
        end
        current_data = step_result
    end

    return current_data, nil
end

local function process_batch(n, template_graph, items, batch_start, batch_end, iteration_input_key, failure_strategy, item_steps)
    local batch_size = batch_end - batch_start + 1
    local batch_results = table.create(batch_size, 0)
    local batch_failures = table.create(batch_size, 0)
    local result_count = 0
    local failure_count = 0

    local iterations, create_err = map_reduce._deps.iterator.create_batch(
        n, template_graph, items, batch_start, batch_end, iteration_input_key
    )

    if create_err then
        for i = batch_start, batch_end do
            failure_count = failure_count + 1
            batch_failures[failure_count] = {
                iteration = i,
                item = items[i],
                error = "Failed to create iteration: " .. create_err
            }
        end
        return batch_results, batch_failures
    end

    local all_root_nodes = table.create(#iterations * 2, 0)
    local root_count = 0
    for _, iteration in ipairs(iterations) do
        for _, root_id in ipairs(iteration.root_nodes) do
            root_count = root_count + 1
            all_root_nodes[root_count] = root_id
        end
    end

    local yield_results, yield_err = n:yield({ run_nodes = all_root_nodes })
    if yield_err then
        for i = batch_start, batch_end do
            failure_count = failure_count + 1
            batch_failures[failure_count] = {
                iteration = i,
                item = items[i],
                error = "Yield failed: " .. yield_err
            }
        end
        return batch_results, batch_failures
    end

    for _, iteration in ipairs(iterations) do
        local iteration_result, iteration_error = map_reduce._deps.iterator.collect_results(n, iteration)

        if iteration_result then
            local final_result = iteration_result

            if item_steps then
                local processed_result, pipeline_err = execute_item_pipeline(item_steps, iteration_result)
                if pipeline_err then
                    failure_count = failure_count + 1
                    batch_failures[failure_count] = {
                        iteration = iteration.iteration,
                        item = iteration.input_item,
                        error = "Item pipeline failed: " .. pipeline_err
                    }
                    goto continue
                end

                if processed_result == nil then
                    goto continue
                end

                final_result = processed_result
            end

            result_count = result_count + 1
            batch_results[result_count] = {
                iteration = iteration.iteration,
                item = iteration.input_item,
                result = final_result
            }
        else
            failure_count = failure_count + 1
            batch_failures[failure_count] = {
                iteration = iteration.iteration,
                item = iteration.input_item,
                error = iteration_error or "Unknown iteration failure" 
            }
        end

        ::continue::
    end

    return batch_results, batch_failures
end

local function run(args)
    local n, err = map_reduce._deps.node.new(args)
    if err then
        error(err)
    end

    local config = n:config()

    -- New config format only
    local source_array_key = config.source_array_key
    if not source_array_key or source_array_key == "" then
        return n:fail({
            code = map_reduce.ERRORS.MISSING_SOURCE_ARRAY_KEY,
            message = "source_array_key is required in map-reduce configuration"
        }, "Missing source_array_key in config")
    end

    local iteration_input_key = config.iteration_input_key or map_reduce.DEFAULTS.ITERATION_INPUT_KEY
    local failure_strategy = config.failure_strategy or map_reduce.DEFAULTS.FAILURE_STRATEGY
    local batch_size = config.batch_size or map_reduce.DEFAULTS.BATCH_SIZE

    local item_steps = config.item_steps
    local reduction_extract = config.reduction_extract
    local reduction_steps = config.reduction_steps

    if not validate_failure_strategy(failure_strategy) then
        return n:fail({
            code = map_reduce.ERRORS.INVALID_FAILURE_STRATEGY,
            message = "Invalid failure_strategy: " .. tostring(failure_strategy) ..
                ". Valid options: " .. map_reduce.FAILURE_STRATEGIES.FAIL_FAST ..
                ", " .. map_reduce.FAILURE_STRATEGIES.IGNORE_FAILURES ..
                ", " .. map_reduce.FAILURE_STRATEGIES.COLLECT_ERRORS
        }, "Invalid failure strategy")
    end

    if not validate_batch_size(batch_size) then
        return n:fail({
            code = map_reduce.ERRORS.INVALID_BATCH_SIZE,
            message = "batch_size must be a positive number <= 1000, got: " .. tostring(batch_size)
        }, "Invalid batch size")
    end

    if item_steps then
        if type(item_steps) ~= "table" then
            return n:fail({
                code = map_reduce.ERRORS.INVALID_PIPELINE_STEP,
                message = "item_steps must be an array of steps"
            }, "Invalid item pipeline configuration")
        end

        for i, step in ipairs(item_steps) do
            local valid, err = validate_item_pipeline_step(step)
            if not valid then
                return n:fail({
                    code = map_reduce.ERRORS.INVALID_PIPELINE_STEP,
                    message = "Invalid item pipeline step " .. i .. ": " .. err
                }, "Invalid item pipeline step")
            end
        end
    end

    if reduction_extract then
        if not validate_extractor(reduction_extract) then
            return n:fail({
                code = map_reduce.ERRORS.INVALID_EXTRACTOR,
                message = "Invalid extractor: " .. reduction_extract
            }, "Invalid reduction extractor")
        end

        if reduction_steps then
            local valid, err = validate_reduction_pipeline_flow(reduction_extract, reduction_steps)
            if not valid then
                return n:fail({
                    code = map_reduce.ERRORS.INCOMPATIBLE_PIPELINE_DATA,
                    message = err
                }, "Incompatible reduction pipeline")
            end
        end
    end

    local inputs = n:inputs()
    local input_data = nil

    if inputs.default then
        input_data = inputs.default.content
    else
        for _, input in pairs(inputs) do
            input_data = input.content
            break
        end
    end

    if input_data == nil then
        return n:fail({
            code = map_reduce.ERRORS.NO_INPUT_DATA,
            message = "No input data provided for map-reduce node"
        }, "Map-reduce node requires input data")
    end

    local items_to_process = nil
    if type(input_data) == "table" and input_data[source_array_key] then
        items_to_process = input_data[source_array_key]
    else
        return n:fail({
            code = map_reduce.ERRORS.INVALID_INPUT_STRUCTURE,
            message = "Input data must contain '" .. source_array_key .. "' field with array"
        }, "Invalid input structure for map-reduce")
    end

    if type(items_to_process) ~= "table" or #items_to_process == 0 then
        return n:fail({
            code = map_reduce.ERRORS.INVALID_INPUT_STRUCTURE,
            message = "Field '" .. source_array_key .. "' must be a non-empty array"
        }, "Invalid input structure for map-reduce")
    end

    local template_graph, template_err = map_reduce._deps.template_graph.build_for_node(n)
    if template_err then
        return n:fail({
            code = map_reduce.ERRORS.TEMPLATE_DISCOVERY_FAILED,
            message = template_err
        }, "Failed to discover template nodes")
    end

    if template_graph:is_empty() then
        return n:fail({
            code = map_reduce.ERRORS.NO_TEMPLATES,
            message = "No template nodes found. Map-reduce requires child nodes with status='template'"
        }, "No template nodes found")
    end

    local total_iterations = #items_to_process
    local all_results = table.create(total_iterations, 0)
    local all_failures = table.create(total_iterations, 0)
    local total_success_count = 0
    local total_failure_count = 0

    for batch_start = 1, total_iterations, batch_size do
        local batch_end = math.min(batch_start + batch_size - 1, total_iterations)

        local batch_results, batch_failures = process_batch(
            n, template_graph, items_to_process, batch_start, batch_end,
            iteration_input_key, failure_strategy, item_steps
        )

        for i = 1, #batch_results do
            total_success_count = total_success_count + 1
            all_results[total_success_count] = batch_results[i]
        end

        for i = 1, #batch_failures do
            total_failure_count = total_failure_count + 1
            all_failures[total_failure_count] = batch_failures[i]
        end

        if failure_strategy == map_reduce.FAILURE_STRATEGIES.FAIL_FAST and #batch_failures > 0 then
            return n:fail({
                code = map_reduce.ERRORS.ITERATION_FAILED,
                message = "Iteration failed: " .. batch_failures[1].error,
            }, "Map-reduce failed due to iteration failure")
        end
    end

    local final_result
    if failure_strategy == map_reduce.FAILURE_STRATEGIES.IGNORE_FAILURES then
        final_result = all_results
    else
        final_result = {
            successes = all_results,
            failures = all_failures,
            total_iterations = total_iterations,
            success_count = total_success_count,
            failure_count = total_failure_count
        }
    end

    if reduction_extract then
        local pipeline_result, pipeline_err = execute_reduction_pipeline(reduction_extract, reduction_steps, final_result)
        if pipeline_err then
            return n:fail({
                code = map_reduce.ERRORS.PIPELINE_FAILED,
                message = "Reduction pipeline failed: " .. pipeline_err
            }, "Map-reduce reduction pipeline failed")
        end
        final_result = pipeline_result
    end

    return n:complete(final_result, "Map-reduce completed successfully")
end

map_reduce.validate_item_pipeline_step = validate_item_pipeline_step
map_reduce.validate_reduction_pipeline_step = validate_reduction_pipeline_step
map_reduce.validate_reduction_pipeline_flow = validate_reduction_pipeline_flow
map_reduce.execute_item_pipeline_step = execute_item_pipeline_step
map_reduce.execute_reduction_pipeline_step = execute_reduction_pipeline_step
map_reduce.execute_item_pipeline = execute_item_pipeline
map_reduce.execute_reduction_pipeline = execute_reduction_pipeline
map_reduce.extractors = extractors

map_reduce.run = run
return map_reduce