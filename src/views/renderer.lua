local templates = require("templates")
local funcs = require("funcs")
local page_registry = require("page_registry")
local resource_registry = require("resource_registry")
local env = require("env")
local env_loader = require("env_loader")

-- Main module
local renderer = {}

-- Get data for a page from its data function
-- Returns: data_table, error_message (nil on success)
function renderer.get_page_data(page, params, query)
    if not page or not page.data_func or page.data_func == "" then
        -- No data function defined, return empty table and no error
        return {}, nil
    end

    -- Create context for the function call
    local context = {
        params = params or {},
        query = query or {},
    }

    -- Use the functions module to call the data function
    local executor = funcs.new()
    local result, err = executor:call(page.data_func, context)

    if err then
        -- Return nil for data, and the error message as the second value
        return nil, "Failed to get page data from '" .. page.data_func .. "': " .. tostring(err)
    end

    -- Success: return the result table and nil for the error
    return result or {}, nil
end

-- Render a page with data
-- Returns: rendered_content, error_message (nil on success)
function renderer.render(page_id, params, query)
    if not page_id then
        return nil, "Page ID is required"
    end

    -- Get the page from registry
    local page, err = page_registry.get(page_id)
    if err then
        return nil, "Failed to get page '" .. page_id .. "': " .. tostring(err)
    end

    -- Check security if the page is secure
    -- (Optional: may be redundant if checked in handler)
    if not page_registry.can_access(page) then
        return nil, "Access denied to page '" .. page_id .. "'"
    end

    -- Get the data for the page, now returns data AND error
    local page_specific_data, data_err = renderer.get_page_data(page, params, query)

    -- Explicitly handle error from get_page_data
    if data_err then
        -- If the data function failed, stop rendering and return its error
        return nil, data_err
    end
    -- If we reach here, page_specific_data is valid (though might be empty table)

    -- Get all resources
    local all_resources, res_err = resource_registry.find_all()
    if res_err then
        return nil, "Failed to load resources: " .. res_err
    end

    -- Collect resources for this page
    local page_resources = resource_registry.collect_for_page(page, page_registry, all_resources)

    -- Group resources by type
    local grouped_resources = resource_registry.group_by_type(page_resources)

    -- Load environment mappings from registry via env_loader
    local resolved_env, env_err = env_loader.get_resolved_env()
    if env_err then
        -- Log warning but don't fail render - use empty env context
        print("Warning: Failed to load environment mappings: " .. env_err)
        resolved_env = {}
    end

    -- Build the final render context
    local render_context = {
        -- Wrap the successfully fetched page-specific data under the 'data' key
        data = page_specific_data,

        -- Add other context variables at the top level
        resources = grouped_resources,
        query_params = query,       -- Using original variable name
        route_params = params,      -- Using original variable name

        -- Environment variables loaded from registry mappings
        env = resolved_env or {}
    }

    -- Get the template set
    local tmpl_id = page.template_set
    local tmpl, tmpl_get_err = templates.get(tmpl_id)
    if tmpl_get_err then
        return nil, "Failed to load template set '" .. tmpl_id .. "': " .. tmpl_get_err
    end

    -- Render the template using the correctly built context
    local content, render_err = tmpl:render(page.template_name, render_context)

    -- IMPORTANT: Release the template resource now that we're done with it
    tmpl:release()

    -- Check for rendering errors
    if render_err then
        return nil, "Failed to render template '" .. page.template_name .. "': " .. render_err
    end

    -- Success: return the rendered content and nil error
    return content, nil
end

return renderer
