local consts = {}

-- Database and host constants
consts.HOST_ID = "app:processes"
consts.APP_DB = "app:db"
consts.ORCHESTRATOR = "wippy.dataflow.runner:orchestrator"

-- Topic constants for actor state transitions
consts.TOPIC = {
    PROCESS_WORK_QUEUE = "process_work_queue",
    EXECUTE_NODES = "execute_nodes",
    SATISFY_YIELD = "satisfy_yield",
    COMPLETE_WORKFLOW = "complete_workflow"
}

-- Message topic constants
consts.MESSAGE_TOPIC = {
    YIELD_REQUEST = "dataflow.yield_request",
    COMMIT_REQUEST = "dataflow.commit_request",
    COMMIT = "dataflow.commit",
    COMMIT_RESPONSE_PREFIX = "dataflow.commit.",
    YIELD_REPLY_PREFIX = "dataflow.yield_reply."
}

-- Command constants
consts.COMMAND = {
    APPLY_COMMIT = "APPLY_COMMIT"
}

-- Command type constants (from ops.lua)
consts.COMMAND_TYPES = {
    -- Workflow Operations
    CREATE_WORKFLOW = "CREATE_WORKFLOW",
    UPDATE_WORKFLOW = "UPDATE_WORKFLOW",
    DELETE_WORKFLOW = "DELETE_WORKFLOW",

    -- Node Operations
    CREATE_NODE = "CREATE_NODE",
    UPDATE_NODE = "UPDATE_NODE",
    DELETE_NODE = "DELETE_NODE",

    -- Data Operations
    CREATE_DATA = "CREATE_DATA",
    UPDATE_DATA = "UPDATE_DATA",
    DELETE_DATA = "DELETE_DATA",
}

-- Meta key constants (from ops.lua)
consts.META_KEYS = {
    OP_ID = "op_id",
}

-- Status constants (from ops.lua)
consts.STATUS = {
    TEMPLATE = "template",
    PENDING = "pending",
    READY = "ready",
    RUNNING = "running",
    PAUSED = "paused",
    COMPLETED_SUCCESS = "completed",
    COMPLETED_FAILURE = "failed",
    CANCELLED = "cancelled",
    SKIPPED = "skipped",
    TERMINATED = "terminated"
}

-- Data type constants
consts.DATA_TYPE = {
    NODE_OUTPUT = "node.output",
    NODE_INPUT = "node.input",
    NODE_YIELD = "node.yield",
    NODE_YIELD_RESULT = "node.yield.result",
    NODE_RESULT = "node.result",
    NODE_CONFIG = "node.config",
    WORKFLOW_OUTPUT = "dataflow.output",
    WORKFLOW_INPUT = "dataflow.input",
    WORKFLOW_LOG = "dataflow.log",
    CONTEXT_DATA = "context.data",
    ARTIFACT = "artifact.data"
}

-- Content type constants
consts.CONTENT_TYPE = {
    JSON = "application/json",
    TEXT = "text/plain",
    BINARY = "application/octet-stream",
    REFERENCE = "dataflow/reference"
}

-- Context discriminator constants
consts.CONTEXT_DISCRIMINATOR = {
    PUBLIC = "public",
    PRIVATE = "private",
    GROUP = "group"
}

-- Error message constants
consts.ERROR = {
    NO_INPUT = "No input data found",
    INVALID_INPUT = "Invalid input data: ",
    REFERENCE_NOT_FOUND = "Referenced input not found: "
}

return consts
