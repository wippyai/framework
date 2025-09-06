local consts = require("consts")

---@class NodeData
---@field status string Node status (pending, running, completed, failed)
---@field type string Node type identifier
---@field parent_node_id string|nil Parent node ID if this is a child node
---@field metadata table|nil Additional node metadata

---@class YieldInfo
---@field yield_id string Unique yield identifier
---@field reply_to string Topic to reply to when yield is satisfied
---@field pending_children table<string, string> Map of child_id -> status (pending, completed)
---@field results table<string, any> Map of child_id -> result data
---@field child_path table List of ancestor node IDs for child nodes

---@class InputRequirements
---@field required table List of required input keys
---@field optional table List of optional input keys

---@class InputTracker
---@field requirements table<string, InputRequirements> Map of node_id -> input requirements
---@field available table<string, table<string, boolean>> Map of node_id -> available inputs by key

---@class SchedulerState
---@field nodes table<string, NodeData> Map of node_id -> node data
---@field active_yields table<string, YieldInfo> Map of parent_id -> yield info
---@field active_processes table<string, boolean> Map of node_id -> true for running processes
---@field input_tracker InputTracker Input requirements and availability tracking
---@field has_workflow_output boolean Whether workflow output has been generated

---@class NodeExecutionInfo
---@field node_id string Node identifier
---@field node_type string Node type
---@field path table List of ancestor node IDs
---@field trigger_reason string Reason for execution
---@field parent_id string|nil Parent node ID for yield children

---@class ExecutionDecision
---@field type string Decision type (execute_nodes, satisfy_yield, complete_workflow, no_work)
---@field payload table Decision-specific data

local scheduler = {}

-- Decision types
local DECISION_TYPE = {
    EXECUTE_NODES = "execute_nodes",        -- Unified execution (single or multiple nodes)
    SATISFY_YIELD = "satisfy_yield",
    COMPLETE_WORKFLOW = "complete_workflow",
    NO_WORK = "no_work"
}

-- Trigger reasons
local TRIGGER_REASON = {
    YIELD_DRIVEN = "yield_driven",
    INPUT_READY = "input_ready",
    ROOT_READY = "root_ready"
}

-- Concurrent execution configuration
local CONCURRENT_CONFIG = {
    MAX_CONCURRENT_NODES = 10,  -- Maximum nodes to execute concurrently
    ENABLE_YIELD_CONCURRENCY = false,  -- Whether to allow concurrent yield children (for future)
    ENABLE_INPUT_CONCURRENCY = true,   -- Whether to allow concurrent input-ready nodes
    ENABLE_ROOT_CONCURRENCY = true     -- Whether to allow concurrent root nodes
}

---Create execution decision
---@param decision_type string Type of decision
---@param payload table|nil Decision payload
---@return ExecutionDecision
local function create_decision(decision_type, payload)
    return {
        type = decision_type,
        payload = payload or {}
    }
end

---Create nodes execution decision (single or multiple nodes)
---@param nodes NodeExecutionInfo[] List of nodes to execute (can be single node)
---@return ExecutionDecision
local function create_nodes_execution(nodes)
    return create_decision(DECISION_TYPE.EXECUTE_NODES, {
        nodes = nodes
    })
end

---Check if node has all required inputs
---@param node_id string Node identifier
---@param node_data NodeData Node data
---@param input_tracker InputTracker Input tracking state
---@return boolean
local function node_has_required_inputs(node_id, node_data, input_tracker)
    if not input_tracker.requirements[node_id] then
        local available = input_tracker.available[node_id] or {}
        return next(available) ~= nil
    end

    local requirements = input_tracker.requirements[node_id]
    local available = input_tracker.available[node_id] or {}

    for _, required_key in ipairs(requirements.required or {}) do
        if not available[required_key] then
            return false
        end
    end

    return true
end

---Check if node has any available inputs
---@param node_id string Node identifier
---@param input_tracker InputTracker Input tracking state
---@return boolean
local function node_has_available_inputs(node_id, input_tracker)
    local available = input_tracker.available[node_id] or {}
    return next(available) ~= nil
end

---Check if all children in a yield are complete
---@param yield_info YieldInfo Yield information
---@return boolean
local function yield_children_complete(yield_info)
    if not yield_info.pending_children then
        return true
    end

    for child_id, status in pairs(yield_info.pending_children) do
        if status == consts.STATUS.PENDING then
            return false
        end
    end

    return true
end

---Find yield-driven work (highest priority)
---@param state SchedulerState Current workflow state
---@return ExecutionDecision|nil
local function find_yield_driven_work(state)
    -- First check for completed yields to satisfy
    for parent_id, yield_info in pairs(state.active_yields) do
        if yield_children_complete(yield_info) then
            return create_decision(DECISION_TYPE.SATISFY_YIELD, {
                parent_id = parent_id,
                yield_id = yield_info.yield_id,
                reply_to = yield_info.reply_to,
                results = yield_info.results or {}
            })
        end
    end

    -- Then find ready yield children
    local ready_yield_children = {}

    for parent_id, yield_info in pairs(state.active_yields) do
        if yield_info.pending_children then
            for child_id, status in pairs(yield_info.pending_children) do
                if status == consts.STATUS.PENDING then
                    local child_node = state.nodes[child_id]
                    if child_node and child_node.status == consts.STATUS.PENDING and
                       node_has_required_inputs(child_id, child_node, state.input_tracker) then
                        table.insert(ready_yield_children, {
                            node_id = child_id,
                            node_type = child_node.type,
                            path = yield_info.child_path or {},
                            trigger_reason = TRIGGER_REASON.YIELD_DRIVEN,
                            parent_id = parent_id
                        })
                    end
                end
            end
        end
    end

    -- For now, execute yield children one at a time (can be enhanced later)
    if #ready_yield_children > 0 then
        return create_nodes_execution({ ready_yield_children[1] })
    end

    return nil
end

---Find input-ready work (nodes with satisfied data dependencies)
---@param state SchedulerState Current workflow state
---@return ExecutionDecision|nil
local function find_input_ready_work(state)
    local ready_nodes = {}

    for node_id, node_data in pairs(state.nodes) do
        if node_data.status == consts.STATUS.PENDING and
           not state.active_processes[node_id] and
           state.input_tracker.requirements[node_id] and
           node_has_required_inputs(node_id, node_data, state.input_tracker) then

            -- Skip yield children (they're handled in yield-driven work)
            local is_yield_child = false
            for _, yield_info in pairs(state.active_yields) do
                if yield_info.pending_children and yield_info.pending_children[node_id] then
                    is_yield_child = true
                    break
                end
            end

            if not is_yield_child then
                table.insert(ready_nodes, {
                    node_id = node_id,
                    node_type = node_data.type,
                    path = {},
                    trigger_reason = TRIGGER_REASON.INPUT_READY
                })
            end
        end
    end

    return decide_execution_strategy(ready_nodes, CONCURRENT_CONFIG.ENABLE_INPUT_CONCURRENCY)
end

---Find root-driven work (nodes with no dependencies but available inputs)
---@param state SchedulerState Current workflow state
---@return ExecutionDecision|nil
local function find_root_driven_work(state)
    local ready_nodes = {}

    for node_id, node_data in pairs(state.nodes) do
        if node_data.status == consts.STATUS.PENDING and
           not state.input_tracker.requirements[node_id] and
           node_has_available_inputs(node_id, state.input_tracker) then

            table.insert(ready_nodes, {
                node_id = node_id,
                node_type = node_data.type,
                path = {},
                trigger_reason = TRIGGER_REASON.ROOT_READY
            })
        end
    end

    return decide_execution_strategy(ready_nodes, CONCURRENT_CONFIG.ENABLE_ROOT_CONCURRENCY)
end

---Decide whether to execute nodes concurrently or singly
---@param ready_nodes NodeExecutionInfo[] List of ready nodes
---@param allow_concurrent boolean Whether concurrent execution is enabled for this type
---@return ExecutionDecision|nil
function decide_execution_strategy(ready_nodes, allow_concurrent)
    if #ready_nodes == 0 then
        return nil
    elseif #ready_nodes == 1 then
        -- Single node execution
        return create_nodes_execution(ready_nodes)
    elseif allow_concurrent then
        -- Multiple nodes execution (concurrent)
        local limit = math.min(#ready_nodes, CONCURRENT_CONFIG.MAX_CONCURRENT_NODES)
        local nodes_to_execute = {}
        for i = 1, limit do
            table.insert(nodes_to_execute, ready_nodes[i])
        end
        return create_nodes_execution(nodes_to_execute)
    else
        -- Concurrent execution disabled, execute first node only
        return create_nodes_execution({ ready_nodes[1] })
    end
end

---Check workflow completion status
---@param state SchedulerState Current workflow state
---@return ExecutionDecision|nil
local function check_workflow_completion(state)
    -- If there's active work, keep going
    if next(state.active_processes) or next(state.active_yields) then
        return nil
    end

    -- Check if we have any nodes at all (empty workflow case)
    local has_nodes = false
    for _ in pairs(state.nodes) do
        has_nodes = true
        break
    end

    -- Empty workflow succeeds immediately
    if not has_nodes then
        return create_decision(DECISION_TYPE.COMPLETE_WORKFLOW, {
            success = true,
            message = "Empty workflow completed"
        })
    end

    -- If workflow output exists, we succeeded (regardless of node failures)
    if state.has_workflow_output then
        return create_decision(DECISION_TYPE.COMPLETE_WORKFLOW, {
            success = true,
            message = "Workflow completed successfully"
        })
    end

    -- Check if more work is possible
    local has_pending = false
    local runnable_nodes = 0
    local nodes_with_no_requirements_or_inputs = 0

    for node_id, node_data in pairs(state.nodes) do
        if node_data.status == consts.STATUS.PENDING then
            has_pending = true

            local has_requirements = state.input_tracker.requirements[node_id] ~= nil
            local has_inputs = node_has_available_inputs(node_id, state.input_tracker)

            if has_requirements then
                if node_has_required_inputs(node_id, node_data, state.input_tracker) then
                    runnable_nodes = runnable_nodes + 1
                end
            elseif has_inputs then
                runnable_nodes = runnable_nodes + 1
            else
                -- No requirements and no inputs
                nodes_with_no_requirements_or_inputs = nodes_with_no_requirements_or_inputs + 1
            end
        end
    end

    -- No pending nodes = workflow is done without output
    if not has_pending then
        return create_decision(DECISION_TYPE.COMPLETE_WORKFLOW, {
            success = false,
            message = "Workflow completed without producing output"
        })
    end

    -- Pending nodes but no runnable work = deadlock/no input data
    if runnable_nodes == 0 then
        local message = "Workflow failed to produce output"
        if nodes_with_no_requirements_or_inputs > 0 then
            message = "No input data provided"
        else
            message = "Workflow deadlocked: nodes pending but no inputs available"
        end

        return create_decision(DECISION_TYPE.COMPLETE_WORKFLOW, {
            success = false,
            message = message
        })
    end

    return nil
end

---Main scheduling function - determines next action to take
---@param state SchedulerState Current workflow state snapshot
---@return ExecutionDecision Decision about what to execute next
function scheduler.find_next_work(state)
    -- Priority 1: Yield-driven work (satisfaction and children)
    local decision = find_yield_driven_work(state)
    if decision then
        return decision
    end

    -- Priority 2: Input-ready work (with concurrency support)
    decision = find_input_ready_work(state)
    if decision then
        return decision
    end

    -- Priority 3: Root-driven work (with concurrency support)
    decision = find_root_driven_work(state)
    if decision then
        return decision
    end

    -- Priority 4: Check for completion
    decision = check_workflow_completion(state)
    if decision then
        return decision
    end

    -- No work available
    return create_decision(DECISION_TYPE.NO_WORK, {
        message = "No work available, waiting for events"
    })
end

---Helper to create empty scheduler state for testing
---@return SchedulerState
function scheduler.create_empty_state()
    return {
        nodes = {},
        active_yields = {},
        active_processes = {},
        input_tracker = {
            requirements = {},
            available = {}
        },
        has_workflow_output = false
    }
end

scheduler.DECISION_TYPE = DECISION_TYPE

return scheduler