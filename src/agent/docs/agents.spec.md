# Wippy Agents Specification

## Overview

The Wippy Agents System is a configuration-driven framework for defining, composing, and deploying AI agents powered by large language models. Agents are defined as registry entries with specific structure and properties that determine their capabilities, behaviors, and relationships with other components.

## Agent Definition Structure

Agents are defined in YAML configuration files as registry entries with kind `registry.entry` and type `agent.gen1`.

### Basic Agent Structure

```yaml
version: "1.0"
namespace: myapp.agents

entries:
  - name: my_assistant
    kind: registry.entry
    meta:
      name: my-assistant
      type: agent.gen1
      title: "My Assistant"
      comment: "A helpful assistant for various tasks"
      group:
        - Assistants
      tags:
        - helper
        - conversation
      icon: tabler:message
    prompt: |
      You are a helpful assistant that provides accurate and concise information.
      
      When responding:
      - Keep answers brief but complete
      - Use simple language
      - Provide examples when helpful
    model: claude-3-7-sonnet
    temperature: 0.7
    max_tokens: 4096
    tools:
      - myapp.tools:calculator
      - myapp.tools:search
    memory:
      - "You were created to help users with general questions"
      - "Today's date is April 6, 2025"
    traits:
      - conversational
      - thinking
```

### Configuration Parameters

| Parameter | Type | Description | Required |
|-----------|------|-------------|----------|
| `name` | String | Registry entry name | Yes |
| `kind` | String | Must be `registry.entry` for agent definitions | Yes |
| `meta.name` | String | Display name of the agent | Yes |
| `meta.type` | String | Must be `agent.gen1` | Yes |
| `meta.title` | String | Title for display purposes | No |
| `meta.comment` | String | Description of the agent | No |
| `meta.group` | Array | Grouping categories for the agent | No |
| `meta.tags` | Array | Tags for categorization and discovery | No |
| `meta.icon` | String | Icon identifier (e.g., `tabler:robot`) | No |
| `prompt` | String | Base system prompt for the agent | Yes |
| `model` | String | LLM model identifier (e.g., `claude-3-7-sonnet`) | No* |
| `temperature` | Number | Sampling temperature (0.0-1.0) | No* |
| `max_tokens` | Number | Maximum completion tokens | No* |
| `tools` | Array | Tool IDs the agent can use | No |
| `memory` | Array | Memory items for contextual knowledge | No |
| `traits` | Array | Trait names or IDs for capability composition | No |
| `delegate` | Map | Delegation configurations for specialized handling | No |
| `inherit` | Array | Parent agent IDs to inherit capabilities from | No |

*These parameters have default values if not specified.

## Traits System

Traits are reusable prompt components that define specific behaviors or capabilities. They are defined as registry entries with type `agent.trait`.

### Trait Definition

```yaml
version: "1.0"
namespace: myapp.traits

entries:
  - name: technical_expertise
    kind: registry.entry
    meta:
      name: technical_expertise
      type: agent.trait
      comment: "Trait that adds technical expertise to an agent's responses"
    prompt: |
      You have expertise in technical subjects including computer science, programming, 
      mathematics, engineering, and related fields. When discussing technical topics:
      
      1. Use precise terminology
      2. Provide accurate technical details
      3. Explain complex concepts clearly
      4. Reference relevant technical standards when appropriate
      5. Distinguish between established facts and areas of ongoing research
```

### Using Traits

Traits are referenced by name in the agent's `traits` array:

```yaml
traits:
  - conversational
  - thinking
  - technical_expertise
```

The system automatically:
1. Resolves traits by name from the registry
2. Combines trait prompts with the agent's base prompt
3. Uses the combined prompt for the agent's system message

### Standard Traits

Wippy provides several built-in traits:

| Trait | Description |
|-------|-------------|
| `conversational` | Makes agents communicate in a natural, friendly way |
| `thinking` | Adds structured thinking tags for complex reasoning |
| `artifact_handling` | Enables proper handling of artifacts in responses |
| `agent_instructions` | Makes agents process special instructions from tools |

## Tool Integration

Tools extend an agent's capabilities by allowing it to perform actions beyond text generation.

### Tool Specification

Tools are specified in the agent definition as an array of tool IDs:

```yaml
tools:
  - myapp.tools:calculator
  - myapp.tools:search
  - myapp.tools:knowledge_base
```

### Tool Wildcards

You can use namespace wildcards to include all tools in a namespace:

```yaml
tools:
  - myapp.tools:*  # Includes all tools in the myapp.tools namespace
```

## Delegation System

Delegation allows agents to forward requests to specialized agents when appropriate.

### Delegate Configuration

Delegates are configured as a map where:
- Keys are the target agent IDs
- Values contain the delegation name and rule

```yaml
delegate:
  myapp.agents:data_analyst:
    name: to_data_analyst
    rule: "Forward to this agent when you receive data analysis questions"
  
  myapp.agents:coding_expert:
    name: to_coding_expert
    rule: "Forward to this agent when you receive coding or programming questions"
```

## Memory System

The memory field allows agents to have persistent contextual knowledge.

### Memory Items

Memory items can be:
- Simple strings of information
- References to memory files
- References to memory registry entries

```yaml
memory:
  - "You were created on April 1, 2025"
  - "Your creator is the Wippy framework team"
  - "file://memory/company_policies.txt"
  - "myapp.memory:product_catalog"
```

## Inheritance

Agents can inherit capabilities from parent agents using the `inherit` field.

### Inheritance Configuration

```yaml
inherit:
  - myapp.agents:base_assistant
  - myapp.agents:technical_assistant
```

### Inheritance Behavior

When an agent inherits from another agent:
1. The child agent gets all traits from the parent(s)
2. Tools from the parent(s) are added to the child's tools
3. Memory items from the parent(s) are added to the child's memory
4. The inheritance is processed recursively for multi-level inheritance
5. Circular inheritance is automatically detected and prevented

### Example Inheritance Chain

```yaml
# Base Assistant
- name: base_assistant
  kind: registry.entry
  meta:
    name: base-assistant
    type: agent.gen1
  prompt: "You are a helpful assistant."
  tools:
    - common:calculator
  traits:
    - conversational
  memory:
    - "You were created to help users"

# Technical Assistant
- name: technical_assistant
  kind: registry.entry
  meta:
    name: technical-assistant
    type: agent.gen1
  prompt: "You have technical expertise."
  tools:
    - coding:syntax_check
  traits:
    - technical_expertise
  inherit:
    - myapp.agents:base_assistant

# Programming Assistant
- name: programming_assistant
  kind: registry.entry
  meta:
    name: programming-assistant
    type: agent.gen1
  prompt: "You specialize in programming help."
  tools:
    - coding:debug
    - coding:lint
  traits:
    - step_by_step
  inherit:
    - myapp.agents:technical_assistant
```

In this example:
- `programming_assistant` inherits from `technical_assistant`
- `technical_assistant` inherits from `base_assistant`
- The final `programming_assistant` will have:
    - Combined prompts from all three
    - Tools from all three (`common:calculator`, `coding:syntax_check`, `coding:debug`, `coding:lint`)
    - Traits from all three (`conversational`, `technical_expertise`, `step_by_step`)
    - Memory from all three

## System Message Construction

The system constructs the agent's system message by combining:
1. Base prompt from the agent definition
2. Prompts from all traits (including inherited traits)
3. Memory context
4. Delegate information

The resulting system message follows this structure:

```
[Base prompt]

[Trait prompt 1]

[Trait prompt 2]

...

## Your memory contains:
- [Memory item 1]
- [Memory item 2]
...

## You can delegate tasks to these specialized agents:
- [Delegate 1 display name]: [Delegate 1 rule] (use tool [Delegate 1 name])
- [Delegate 2 display name]: [Delegate 2 rule] (use tool [Delegate 2 name])
...
```

## Complete Example

Here's a complete example of an agent definition with all major components:

```yaml
version: "1.0"
namespace: chatbot.agents

entries:
  - name: support_assistant
    kind: registry.entry
    meta:
      name: support-assistant
      type: agent.gen1
      title: "Support Assistant"
      comment: "Customer support assistant with knowledge of products and policies"
      group:
        - Support
      tags:
        - customer
        - service
        - support
      icon: tabler:headset
    prompt: |
      You are a customer support assistant for TechCo, a company that sells computer hardware.
      
      Your primary responsibilities:
      1. Answer questions about TechCo products
      2. Help with order status inquiries
      3. Assist with returns and warranty claims
      4. Troubleshoot basic technical issues
      
      Always maintain a professional, helpful tone. If you cannot resolve an issue,
      offer to escalate to a human support representative.
    model: claude-3-7-sonnet
    temperature: 0.3
    max_tokens: 4096
    tools:
      - chatbot.tools:order_lookup
      - chatbot.tools:product_search
      - chatbot.tools:knowledge_base
    memory:
      - "TechCo sells laptops, desktops, tablets, monitors, and accessories"
      - "TechCo offers a 30-day return policy and 1-year warranty on all products"
      - "file://memory/product_catalog.txt"
      - "file://memory/common_issues.txt"
    traits:
      - conversational
      - thinking
      - agent_instructions
    delegate:
      technical-expert:
        name: to_tech_expert
        rule: "Forward to this agent when advanced technical troubleshooting is needed"
      
      order-specialist:
        name: to_order_specialist
        rule: "Forward to this agent when complex order issues arise that you cannot resolve"
    inherit:
      - chatbot.agents:base_assistant
```
