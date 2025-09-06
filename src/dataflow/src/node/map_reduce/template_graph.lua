local consts = require("consts")

-- Default dependencies
local default_deps = {
    node_reader = require("node_reader")
}

local template_graph = {}

---@class TemplateGraph
---@field nodes table<string, table> Map of node_id -> template node data
---@field edges table<string, table> Map of node_id -> array of target node_ids
---@field roots table Array of root node_ids (nodes with no internal dependencies)
---@field _deps table Dependencies for testing

local TemplateGraph = {}
local template_graph_mt = { __index = TemplateGraph }

---Create a new empty template graph
---@param deps table|nil Optional dependencies for testing
---@return TemplateGraph
function template_graph.new(deps)
    local instance = {
        nodes = {},
        edges = {},
        roots = {},
        _deps = deps or default_deps
    }
    return setmetatable(instance, template_graph_mt)
end

---Check if the graph is empty
---@return boolean
function TemplateGraph:is_empty()
    return next(self.nodes) == nil
end

---Get root node IDs
---@return table Array of root node IDs
function TemplateGraph:get_roots()
    return self.roots
end

---Get all node IDs
---@return table Array of all node IDs
function TemplateGraph:get_all_nodes()
    local node_ids = {}
    for node_id, _ in pairs(self.nodes) do
        table.insert(node_ids, node_id)
    end
    return node_ids
end

---Get node data
---@param node_id string Node ID
---@return table|nil Node data or nil if not found
function TemplateGraph:get_node(node_id)
    return self.nodes[node_id]
end

---Get edges from a node
---@param node_id string Node ID
---@return table Array of target node IDs
function TemplateGraph:get_edges(node_id)
    return self.edges[node_id] or {}
end

---Check if graph has circular dependencies
---@return boolean, string|nil has_cycle, cycle_description
function TemplateGraph:has_cycles()
    local visited = {}
    local rec_stack = {}

    local function dfs(node_id, path)
        if rec_stack[node_id] then
            local cycle_start = nil
            for i, id in ipairs(path) do
                if id == node_id then
                    cycle_start = i
                    break
                end
            end

            if cycle_start then
                local cycle = {}
                for i = cycle_start, #path do
                    table.insert(cycle, path[i])
                end
                table.insert(cycle, node_id)
                return true, "Circular dependency: " .. table.concat(cycle, " -> ")
            end
            return true, "Circular dependency detected at node: " .. node_id
        end

        if visited[node_id] then
            return false, nil
        end

        visited[node_id] = true
        rec_stack[node_id] = true
        table.insert(path, node_id)

        local edges = self:get_edges(node_id)
        for _, target_id in ipairs(edges) do
            if self.nodes[target_id] then
                local has_cycle, cycle_desc = dfs(target_id, path)
                if has_cycle then
                    return true, cycle_desc
                end
            end
        end

        rec_stack[node_id] = false
        table.remove(path)
        return false, nil
    end

    for node_id, _ in pairs(self.nodes) do
        if not visited[node_id] then
            local has_cycle, cycle_desc = dfs(node_id, {})
            if has_cycle then
                return true, cycle_desc
            end
        end
    end

    return false, nil
end

---Discover template child nodes for a parent node
---@param dataflow_id string Dataflow ID
---@param parent_node_id string Parent node ID
---@param deps table Dependencies
---@return table|nil templates Array of template nodes or nil on error
---@return string|nil error Error message if failed
local function discover_templates(dataflow_id, parent_node_id, deps)
    local reader, reader_err = deps.node_reader.with_dataflow(dataflow_id)
    if reader_err then
        return nil, "Failed to create node reader: " .. reader_err
    end

    local templates, query_err = reader
        :with_parent_nodes(parent_node_id)
        :with_statuses(consts.STATUS.TEMPLATE)
        :all()

    if query_err then
        return nil, "Failed to query template nodes: " .. query_err
    end

    return templates, nil
end

---Build template graph for a given parent node
---@param parent_node any Node instance with dataflow_id and node_id
---@param deps table|nil Optional dependencies for testing
---@return TemplateGraph|nil graph Template graph or nil on error
---@return string|nil error Error message if failed
function template_graph.build_for_node(parent_node, deps)
    deps = deps or default_deps

    if not parent_node or not parent_node.dataflow_id or not parent_node.node_id then
        return nil, "Invalid parent node: missing dataflow_id or node_id"
    end

    local templates, discover_err = discover_templates(parent_node.dataflow_id, parent_node.node_id, deps)
    if discover_err then
        return nil, discover_err
    end

    if #templates == 0 then
        return template_graph.new(deps), nil
    end

    local graph = template_graph.new(deps)

    -- Step 1: Add all nodes first
    for _, template in ipairs(templates) do
        graph.nodes[template.node_id] = template
    end

    -- Step 2: Initialize empty edges for all nodes
    for node_id, _ in pairs(graph.nodes) do
        graph.edges[node_id] = {}
    end

    -- Step 3: Build edges by processing each template's targets
    for _, template in ipairs(templates) do
        local config = template.config or {}
        local data_targets = config.data_targets or {}
        local error_targets = config.error_targets or {}

        -- Track data target edges
        for _, target in ipairs(data_targets) do
            if target.node_id and graph.nodes[target.node_id] then
                table.insert(graph.edges[template.node_id], target.node_id)
            end
        end

        -- Track error target edges
        for _, target in ipairs(error_targets) do
            if target.node_id and graph.nodes[target.node_id] then
                table.insert(graph.edges[template.node_id], target.node_id)
            end
        end
    end

    -- Step 4: Find nodes with incoming edges
    local nodes_with_incoming_edges = {}
    for source_id, targets in pairs(graph.edges) do
        for _, target_id in ipairs(targets) do
            nodes_with_incoming_edges[target_id] = true
        end
    end

    -- Step 5: Find root nodes (nodes with no incoming edges)
    -- Sort nodes for consistent ordering in tests
    local sorted_node_ids = {}
    for node_id, _ in pairs(graph.nodes) do
        table.insert(sorted_node_ids, node_id)
    end
    table.sort(sorted_node_ids)

    for _, node_id in ipairs(sorted_node_ids) do
        if not nodes_with_incoming_edges[node_id] then
            table.insert(graph.roots, node_id)
        end
    end

    local has_cycles, cycle_desc = graph:has_cycles()
    if has_cycles then
        return nil, "Template dependency graph has circular dependencies: " .. cycle_desc
    end

    if #graph.roots == 0 then
        return nil, "Template dependency graph has no root nodes (all nodes have internal dependencies)"
    end

    return graph, nil
end

return template_graph