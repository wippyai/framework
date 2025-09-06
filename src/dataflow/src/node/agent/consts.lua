local consts = {}

-- Data Types
consts.DATA_TYPE = {
    AGENT_ACTION = "agent.action",
    AGENT_OBSERVATION = "agent.observation",
    AGENT_MEMORY = "agent.memory",
    AGENT_DELEGATION = "agent.delegation",
    AGENT_ERROR = "agent.error"
}

-- Tool Calling Modes
consts.TOOL_CALLING = {
    ANY = "any",
    AUTO = "auto",
    NONE = "none"
}

-- Configuration Defaults
consts.DEFAULTS = {
    MAX_ITERATIONS = 10,
    MIN_ITERATIONS = 1,
    TOOL_CALLING = "any"
}

-- Input Configuration Defaults
consts.INPUT_DEFAULTS = {
    CONTEXT_KEY = nil,
    AGENT_ID_KEY = nil,
    PROMPT_KEY = "",
    REQUIRED = {}
}

-- Delegate Configuration Defaults
consts.DELEGATE_DEFAULTS = {
    GENERATE_TOOL_SCHEMAS = true,
    DESCRIPTION_PREFIX = "Delegate to ",
    DESCRIPTION_SUFFIX = " (runs specialized agent in parallel)",
    SCHEMA = {
        type = "object",
        properties = {
            message = {
                type = "string",
                description = "The message to forward to the agent"
            }
        },
        required = { "message" }
    }
}

-- Error Codes
consts.ERROR = {
    INVALID_CONFIG = "INVALID_CONFIG",
    AGENT_LOAD_FAILED = "AGENT_LOAD_FAILED",
    AGENT_EXEC_FAILED = "AGENT_EXEC_FAILED",
    TOOL_EXEC_FAILED = "TOOL_EXEC_FAILED",
    PROMPT_BUILD_FAILED = "PROMPT_BUILD_FAILED",
    INPUT_MISSING = "INPUT_MISSING",
    INPUT_VALIDATION_FAILED = "INPUT_VALIDATION_FAILED",
    DELEGATION_FAILED = "DELEGATION_FAILED"
}

-- Error Messages
consts.ERROR_MSG = {
    INVALID_CONFIG = "Invalid agent node configuration",
    AGENT_LOAD_FAILED = "Failed to load agent: %s",
    AGENT_EXEC_FAILED = "Agent execution failed: %s",
    TOOL_EXEC_FAILED = "Tool execution failed: %s",
    PROMPT_BUILD_FAILED = "Failed to build prompt: %s",
    INPUT_MISSING = "Required input not found: %s",
    INPUT_VALIDATION_FAILED = "Input validation failed: %s",
    DELEGATION_FAILED = "Delegation failed: %s"
}

-- Feedback Messages
consts.FEEDBACK = {
    NO_TOOLS_CALLED = "Environment: You have not used any tools. Continue with your reasoning and use appropriate tools.",
    EXIT_AVAILABLE = "Environment: Use the '%s' tool when you are ready to complete the task.",
    ITERATIONS_WARNING = "Environment: You have %d iterations remaining before reaching the maximum limit. Plan accordingly.",
    FINAL_ITERATION = "Environment: You have 1 iteration remaining - this is your last chance. You must complete your task or call the finish tool now.",
    CRITICAL_FINAL = "CRITICAL: This is your FINAL iteration! You must call the finish tool now or the task will fail. Do not call any other tools."
}

-- Status Messages
consts.STATUS = {
    COMPLETED_SUCCESS = "Agent completed successfully",
    COMPLETED_ERROR = "Agent failed: "
}

return consts