# React Arena Configuration Specification

## Overview

React Arenas are execution environments for AI agents following the ReAct pattern (Reasoning, Action, Observation). They define how agents interact with tools, process context, and produce structured outputs within the dataflow system.

## Registry Entry Structure

```yaml
- name: arena_name
  kind: registry.entry
  meta:
    type: agent.arena
    title: "Human Readable Title"
    comment: "Purpose and description"
    tags: [react, domain, specialized]
  data:
    # Arena configuration goes here
```

## Core Configuration Properties

### Required Properties

| Property | Type | Description |
|----------|------|-------------|
| `prompt` | string | Base system prompt for agent reasoning |
| `output` | object | Output configuration (schema/format/tool) |

### Optional Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `iterations` | object | `{min: 1, max: 10}` | Iteration control limits |
| `tools` | array | `[]` | Available tools for agents |
| `start_function` | string | none | Function called before first iteration |
| `end_function` | string | none | Function called after completion |
| `input_tool` | string | none | Tool for preprocessing input data |

## Output Configuration Types

### 1. Schema-Based Output (Structured JSON)

```yaml
output:
  schema:
    name: "finish"                    # Tool name (default: "finish")
    description: "Complete the task"  # Tool description
    definition: |                     # JSON schema as string
      {
        "type": "object",
        "properties": {
          "success": {"type": "boolean"},
          "output": {
            "type": "object",
            "properties": {
              "result": {"type": "string"},
              "data": {"type": "object"}
            }
          },
          "error": {"type": "string"}
        },
        "required": ["success"]
      }
```

### 2. XML Format Output

```yaml
output:
  format: xml   # Agent outputs final answer in <o></o> tags
```

### 3. Tool-Based Output

```yaml
output:
  tool: "namespace:custom_finish_tool"  # Use specific registered tool
```

## Tools Configuration

```yaml
tools:
  - "system:calculator"           # Specific tool by ID
  - "research:*"                  # All tools in namespace (wildcard)
  - "external:api_client"         # External API tool
  - "data:file_operations"        # Data manipulation tool
```

**Wildcard Resolution**: `namespace:*` automatically includes all tools registered under that namespace.

## Iteration Control

```yaml
iterations:
  min: 1        # Minimum required iterations
  max: 15       # Maximum allowed iterations
```

- **min**: Enforces thorough reasoning (agent continues even if task seems complete)
- **max**: Prevents infinite loops and controls resource usage

## Lifecycle Functions

```yaml
start_function: "namespace:setup_context"     # Called before first iteration
end_function: "namespace:finalize_results"    # Called after completion
input_tool: "namespace:validate_input"       # Preprocesses initial input
```

## _control Directive Operations

Tools can return `_control` directives to modify arena execution state:

### Session Context Management

```json
{
  "_control": {
    "context": {
      "session": {
        "set": {"user_preference": "detailed", "theme": "dark"},
        "delete": ["temp_var", "cache_key"]
      }
    }
  }
}
```

### Public Metadata Operations

```json
{
  "_control": {
    "context": {
      "public_meta": {
        "set": [
          {"id": "progress", "type": "status", "value": "75%"},
          {"id": "phase", "type": "workflow", "value": "analysis"}
        ],
        "clear": "temporary",           // Clear all items of this type
        "delete": ["old_status_id"]     // Delete specific items by ID
      }
    }
  }
}
```

### Memory Management

```json
{
  "_control": {
    "memory": {
      "add": [
        {"type": "user_context", "text": "User prefers detailed explanations"},
        {"type": "learned_fact", "text": "Company uses React framework"}
      ],
      "clear": "temporary",             // Clear all memories of this type
      "delete": ["memory_id_123"]       // Delete specific memory by ID
    }
  }
}
```

### Artifact Creation

```json
{
  "_control": {
    "artifacts": [
      {
        "title": "Analysis Report",
        "content": "# Report Content...",
        "content_type": "text/markdown",
        "description": "Generated analysis report",
        "type": "document"
      }
    ]
  }
}
```

### Dynamic Configuration Changes

```json
{
  "_control": {
    "config": {
      "agent": "specialized_researcher",    // Switch to different agent
      "model": "claude-3-opus"             // Change model mid-execution
    }
  }
}
```

### Direct Database Commands

```json
{
  "_control": {
    "commands": [
      {
        "type": "CREATE_DATA",
        "payload": {
          "data_type": "analysis.result",
          "key": "final_analysis",
          "content": {"findings": "...", "confidence": 0.95}
        }
      }
    ]
  }
}
```

### Yield Operations

```json
{
  "_control": {
    "yield": {
      "user_context": {
        "run_node_ids": ["validation_node", "preprocessing_node"]
      },
      "commands": [
        {
          "type": "UPDATE_NODE",
          "payload": {"node_id": "current", "status": "paused"}
        }
      ]
    }
  }
}
```

## Command Operation Shapes

### Node Operations

#### CREATE_NODE
```json
{
  "type": "CREATE_NODE",
  "payload": {
    "node_id": "uuid",              // optional, auto-generated
    "node_type": "analysis_task",   // required
    "parent_node_id": "parent_id",  // optional
    "status": "pending",            // optional, default: "pending"
    "metadata": {"priority": "high"} // optional
  }
}
```

#### UPDATE_NODE
```json
{
  "type": "UPDATE_NODE",
  "payload": {
    "node_id": "uuid",              // required
    "node_type": "updated_type",    // optional
    "status": "running",            // optional
    "metadata": {"progress": "50%"} // optional
  }
}
```

#### DELETE_NODE
```json
{
  "type": "DELETE_NODE",
  "payload": {
    "node_id": "uuid"               // required
  }
}
```

### Data Operations

#### CREATE_DATA
```json
{
  "type": "CREATE_DATA",
  "payload": {
    "data_id": "uuid",                    // optional, auto-generated
    "data_type": "analysis.result",       // required
    "key": "final_output",                // required
    "content": {"result": "success"},     // required (string or object)
    "discriminator": "public",            // optional, default: varies
    "content_type": "application/json",   // optional, default: "application/json"
    "node_id": "associated_node",         // optional
    "metadata": {"source": "analysis"}   // optional
  }
}
```

#### UPDATE_DATA
```json
{
  "type": "UPDATE_DATA",
  "payload": {
    "data_id": "uuid",                    // required
    "content": {"updated": "content"},    // optional
    "content_type": "text/plain",         // optional
    "metadata": {"modified": "true"}     // optional
  }
}
```

#### DELETE_DATA
```json
{
  "type": "DELETE_DATA",
  "payload": {
    "data_id": "uuid"                     // required
  }
}
```

### Workflow Operations

#### CREATE_WORKFLOW
```json
{
  "type": "CREATE_WORKFLOW",
  "payload": {
    "dataflow_id": "uuid",                // optional if in context
    "actor_id": "user_123",               // required
    "type": "research_workflow",          // required
    "status": "pending",                  // optional, default: "pending"
    "parent_dataflow_id": "parent_id",    // optional
    "metadata": {"domain": "finance"}    // optional
  }
}
```

#### UPDATE_WORKFLOW
```json
{
  "type": "UPDATE_WORKFLOW",
  "payload": {
    "dataflow_id": "uuid",                // optional if in context
    "type": "updated_workflow_type",      // optional
    "status": "running",                  // optional
    "last_commit_id": "commit_123",       // optional
    "metadata": {"phase": "analysis"}    // optional
  }
}
```

#### DELETE_WORKFLOW
```json
{
  "type": "DELETE_WORKFLOW",
  "payload": {
    "dataflow_id": "uuid"                 // optional if in context
  }
}
```

## Complete Arena Examples

### Research Arena
```yaml
- name: research_arena
  kind: registry.entry
  meta:
    type: agent.arena
    title: "Research Arena"
    comment: "Comprehensive research with source validation"
    tags: [research, academic, fact-checking]
  data:
    prompt: |
      You are a research assistant using the ReAct methodology.
      
      Research Process:
      1. REASON about information needs and search strategy
      2. ACTION with research tools to gather information
      3. OBSERVE results and assess credibility
      4. Synthesize findings from multiple sources
      
      Guidelines:
      - Verify information from multiple sources
      - Note confidence levels and limitations
      - Cite sources when possible
      - Acknowledge conflicting information

    iterations:
      min: 2      # Ensure multi-source verification
      max: 20     # Allow deep investigation

    output:
      schema:
        name: research_complete
        description: "Complete research with findings and sources"
        definition: |
          {
            "type": "object",
            "properties": {
              "success": {"type": "boolean"},
              "output": {
                "type": "object",
                "properties": {
                  "findings": {"type": "string"},
                  "sources": {"type": "array", "items": {"type": "string"}},
                  "confidence": {"type": "number", "minimum": 0, "maximum": 1},
                  "limitations": {"type": "string"}
                },
                "required": ["findings", "sources"]
              },
              "error": {"type": "string"}
            },
            "required": ["success"]
          }

    tools:
      - "research:web_search"
      - "research:academic_search"
      - "research:fact_check"
      - "analysis:*"

    end_function: "research:format_report"
```

### Code Development Arena
```yaml
- name: code_dev_arena
  kind: registry.entry
  meta:
    type: agent.arena
    title: "Code Development Arena"
    comment: "Software development with testing and validation"
    tags: [coding, development, testing]
  data:
    prompt: |
      You are a software development assistant following ReAct methodology.
      
      Development Process:
      1. REASON about requirements and technical approach
      2. ACTION with development tools (code, test, debug)
      3. OBSERVE results and validate functionality
      
      Standards:
      - Write clean, well-documented code
      - Include comprehensive tests
      - Validate code functionality before completion
      - Follow security best practices

    iterations:
      min: 1
      max: 25

    output:
      schema:
        name: development_complete
        description: "Complete development deliverable"
        definition: |
          {
            "type": "object",
            "properties": {
              "success": {"type": "boolean"},
              "output": {
                "type": "object",
                "properties": {
                  "code": {"type": "string"},
                  "tests": {"type": "string"},
                  "documentation": {"type": "string"},
                  "validation_results": {"type": "object"}
                },
                "required": ["code"]
              },
              "error": {"type": "string"}
            },
            "required": ["success"]
          }

    tools:
      - "dev:code_editor"
      - "dev:test_runner"
      - "dev:linter"
      - "system:file_operations"

    input_tool: "dev:parse_requirements"
    end_function: "dev:package_deliverable"
```

### Simple XML Arena
```yaml
- name: simple_xml_arena
  kind: registry.entry
  meta:
    type: agent.arena
    title: "Simple XML Output Arena"
    comment: "Basic ReAct with XML final output"
    tags: [react, xml, simple]
  data:
    prompt: |
      Follow the ReAct pattern: Reason, Act with tools, Observe results.
      When you have your final answer, wrap it in <o></o> tags.

    iterations:
      min: 1
      max: 8

    output:
      format: xml

    tools:
      - "system:*"
      - "web:search"
```

## Data Types Reference

From `consts.lua`, available data types:

### Node Data Types
- `node.output` - Node execution results
- `node.input` - Node input data
- `node.yield` - Yield request data
- `node.yield.result` - Yield response data
- `node.result` - Final node result
- `node.config` - Node configuration changes

### Workflow Data Types
- `dataflow.output` - Workflow final output
- `dataflow.input` - Workflow initial input
- `dataflow.log` - Workflow execution logs

### Context Data Types
- `context.data` - Contextual information
- `artifact.data` - Generated artifacts

### Content Types
- `application/json` - JSON structured data
- `text/plain` - Plain text content
- `application/octet-stream` - Binary data
- `dataflow/reference` - Reference to other data

### Context Discriminators
- `public` - Accessible to all agents
- `private` - Node-specific context
- `group` - Shared within group scope