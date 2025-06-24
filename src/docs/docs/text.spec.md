# Lua Text Module Specification

## Overview

The `text` module provides advanced text processing capabilities for Lua, specializing in intelligent text chunking, text comparison, and regular expression operations for AI applications. It leverages proven algorithms to split large documents into smaller, semantically meaningful chunks while preserving document structure and metadata, provides sophisticated diff functionality for comparing and patching text content, and offers powerful regex pattern matching.

The module is optimized for document processing pipelines, embedding generation, AI content preparation workflows, version control operations, and text analysis tasks.

---

## Module Interface

### Module Loading

```lua
local text = require("text")
```

### Error Handling

All functions in the module follow a consistent error handling pattern, returning two values:

1. The result value (or nil if an error occurred)
2. An error message string (or nil if operation was successful)

Example:

```lua
local splitter, err = text.splitter.recursive({chunk_size = 1000})
if err then
    error("Failed to create splitter: " .. err)
end

local differ, err = text.diff.new({diff_timeout = 1.0})
if err then
    error("Failed to create differ: " .. err)
end

local regex, err = text.regexp.compile("\\d+")
if err then
    error("Failed to compile regex: " .. err)
end
```

---

## Splitter Sub-Module

The `text.splitter` sub-module provides intelligent text chunking capabilities with different algorithms optimized for various content types.

### `text.splitter.recursive(options)`

**Description:**  
Creates a recursive character splitter that intelligently splits text by trying different separators in order of preference. Best for general-purpose text processing.

**Parameters:**

- **`options`** (table, optional): Configuration options:
  - **`chunk_size`** (number): Maximum chunk size in characters (default: 4000)
  - **`chunk_overlap`** (number): Number of overlapping characters between chunks (default: 200)
  - **`separators`** (array): Separators to try in order (default: `{"\n\n", "\n", " ", ""}`)
  - **`keep_separator`** (boolean): Whether to keep separators in the text (default: false)

**Returns:**

- **On success:** A TextSplitter object with methods for splitting text, `nil`
- **On failure:** `nil` and an error message string

**Example:**

```lua
local splitter, err = text.splitter.recursive({
    chunk_size = 1000,
    chunk_overlap = 150,
    separators = {"\n\n", "\n", ". ", " ", ""},
    keep_separator = false
})
if err then
    error("Failed to create splitter: " .. err)
end
```

### `text.splitter.markdown(options)`

**Description:**  
Creates a markdown-aware splitter that preserves document structure while splitting. Ideal for markdown documents, documentation, and structured text.

**Parameters:**

- **`options`** (table, optional): Configuration options:
  - **`chunk_size`** (number): Maximum chunk size in characters (default: 4000)
  - **`chunk_overlap`** (number): Number of overlapping characters between chunks (default: 200)
  - **`code_blocks`** (boolean): Whether to include code blocks in output (default: false)
  - **`reference_links`** (boolean): Whether to resolve reference links (default: false)
  - **`heading_hierarchy`** (boolean): Whether to preserve heading hierarchy in chunks (default: false)
  - **`join_table_rows`** (boolean): Whether to join table rows in single chunks (default: false)
  - **`separators`** (array): Custom separators to try in order (optional)

**Returns:**

- **On success:** A TextSplitter object with methods for splitting text, `nil`
- **On failure:** `nil` and an error message string

**Example:**

```lua
local splitter, err = text.splitter.markdown({
    chunk_size = 1000,
    chunk_overlap = 150,
    code_blocks = true,
    heading_hierarchy = true,
    join_table_rows = false
})
if err then
    error("Failed to create splitter: " .. err)
end
```

---

## Diff Sub-Module

The `text.diff` sub-module provides sophisticated text comparison, diff generation, and patch application capabilities based on the Google Diff-Match-Patch algorithm.

### `text.diff.new(options)`

**Description:**  
Creates a text differ that can compare texts, generate diffs, create patches, and apply changes. Ideal for version control workflows, document comparison, and change tracking.

**Parameters:**

- **`options`** (table, optional): Configuration options:
  - **`diff_timeout`** (number): Timeout in seconds for diff computation (default: 1.0)
  - **`diff_edit_cost`** (number): Cost of an edit operation for diff quality (default: 4)
  - **`match_threshold`** (number): Match threshold (0.0 = perfection, 1.0 = very loose, default: 0.5)
  - **`match_distance`** (number): How far to search for a match (default: 1000)
  - **`patch_delete_threshold`** (number): Delete threshold for patch application (default: 0.5)
  - **`patch_margin`** (number): Number of context lines around patches (default: 4)

**Returns:**

- **On success:** A Differ object with methods for text comparison, `nil`
- **On failure:** `nil` and an error message string

**Example:**

```lua
local differ, err = text.diff.new({
    diff_timeout = 1.0,
    match_threshold = 0.5,
    patch_margin = 4
})
if err then
    error("Failed to create differ: " .. err)
end
```

---

## Regexp Sub-Module

The `text.regexp` sub-module provides powerful regular expression pattern matching and text manipulation capabilities.

### `text.regexp.compile(pattern)`

**Description:**  
Compiles a regular expression pattern for reuse. Uses Go's regexp syntax.

**Parameters:**

- **`pattern`** (string): The regular expression pattern to compile

**Returns:**

- **On success:** A Regexp object with methods for pattern matching, `nil`
- **On failure:** `nil` and an error message string

**Example:**

```lua
local regex, err = text.regexp.compile("\\b\\d{3}-\\d{3}-\\d{4}\\b")
if err then
    error("Failed to compile regex: " .. err)
end
```

---

## TextSplitter Object Methods

Once created, TextSplitter objects provide the following methods:

### `splitter:split_text(content)`

**Description:**  
Splits a single text string into chunks according to the splitter's configuration.

**Parameters:**

- **`content`** (string): The text content to split

**Returns:**

- **On success:** Array of text chunks (strings), `nil`
- **On failure:** `nil` and an error message string

**Example:**

```lua
local content = "This is a long document that needs to be split into smaller chunks for processing..."
local chunks, err = splitter:split_text(content)
if err then
    error("Failed to split text: " .. err)
end

for i, chunk in ipairs(chunks) do
    print("Chunk " .. i .. ": " .. chunk)
end
```

### `splitter:split_batch(pages)`

**Description:**  
Splits multiple text items with associated metadata in a single operation. Each input item's metadata is preserved and attached to all chunks generated from that item.

**Parameters:**

- **`pages`** (array): Array of page objects, each containing:
  - **`content`** (string): The text content to split
  - **`metadata`** (table): Metadata to preserve with each chunk

**Returns:**

- **On success:** Array of chunk objects (each containing `content` and `metadata`), `nil`
- **On failure:** `nil` and an error message string

**Example:**

```lua
local pages = {
    {
        content = "Content from page 1 of the document...",
        metadata = {page_number = 1, document_id = "doc123", source = "manual.pdf"}
    },
    {
        content = "Content from page 2 of the document...",
        metadata = {page_number = 2, document_id = "doc123", source = "manual.pdf"}
    }
}

local chunks, err = splitter:split_batch(pages)
if err then
    error("Failed to split batch: " .. err)
end

for i, chunk in ipairs(chunks) do
    print("Chunk content: " .. chunk.content)
    print("From page: " .. chunk.metadata.page_number)
    print("Document: " .. chunk.metadata.document_id)
end
```

---

## Differ Object Methods

Once created, Differ objects provide the following methods:

### `differ:compare(text1, text2)`

**Description:**  
Compares two text strings and returns an array of diff operations describing the changes needed to transform text1 into text2.

**Parameters:**

- **`text1`** (string): The original text
- **`text2`** (string): The modified text

**Returns:**

- **On success:** Array of diff objects (each containing `operation` and `text`), `nil`
- **On failure:** `nil` and an error message string

Each diff object contains:
- **`operation`** (string): The operation type ("equal", "delete", "insert")
- **`text`** (string): The text content for this operation

**Example:**

```lua
local old_text = "The quick brown fox"
local new_text = "The quick red fox"

local diffs, err = differ:compare(old_text, new_text)
if err then
    error("Failed to compare texts: " .. err)
end

for i, diff in ipairs(diffs) do
    print(string.format("%s: '%s'", diff.operation, diff.text))
end
-- Output:
-- equal: 'The quick '
-- delete: 'brown'
-- insert: 'red'
-- equal: ' fox'
```

### `differ:pretty_text(diffs)`

**Description:**  
Converts an array of diff operations into a human-readable unified diff format, similar to git diff output.

**Parameters:**

- **`diffs`** (array): Array of diff objects from `compare()`

**Returns:**

- **On success:** Formatted diff string, `nil`
- **On failure:** `nil` and an error message string

**Example:**

```lua
local diffs, err = differ:compare("Hello world", "Hello beautiful world")
if err then
    error("Compare failed: " .. err)
end

local pretty, err = differ:pretty_text(diffs)
if err then
    error("Pretty text failed: " .. err)
end

print(pretty)
-- Output shows insertions/deletions in readable format
```

### `differ:pretty_html(diffs)`

**Description:**  
Converts an array of diff operations into HTML format with proper `<ins>` and `<del>` tags for web display.

**Parameters:**

- **`diffs`** (array): Array of diff objects from `compare()`

**Returns:**

- **On success:** Formatted HTML string, `nil`
- **On failure:** `nil` and an error message string

**Example:**

```lua
local diffs, err = differ:compare("Hello world", "Hello beautiful world")
if err then
    error("Compare failed: " .. err)
end

local html, err = differ:pretty_html(diffs)
if err then
    error("Pretty HTML failed: " .. err)
end

print(html)
-- Output: HTML with <ins> and <del> tags
```

### `differ:patch_make(text1, text2)`

**Description:**  
Creates patches that can be used to transform text1 into text2. Patches are compact representations of changes that can be stored or transmitted.

**Parameters:**

- **`text1`** (string): The original text
- **`text2`** (string): The target text

**Returns:**

- **On success:** Array of patch objects, `nil`
- **On failure:** `nil` and an error message string

Each patch object contains:
- **`text`** (string): The patch in unified diff format

**Example:**

```lua
local patches, err = differ:patch_make("Hello world", "Hello beautiful world")
if err then
    error("Failed to create patches: " .. err)
end

print("Created " .. #patches .. " patches")
for i, patch in ipairs(patches) do
    print("Patch " .. i .. ": " .. patch.text)
end
```

### `differ:patch_apply(patches, text)`

**Description:**  
Applies an array of patches to a text string, attempting to transform it according to the patches. Supports both internally generated patches and externally provided patches.

**Parameters:**

- **`patches`** (array): Array of patch objects, each containing a `text` field
- **`text`** (string): The text to apply patches to

**Returns:**

- **On success:** The patched text, boolean indicating if all patches applied successfully
- **On failure:** `nil` and an error message string

**External Patch Format:**
External agents can create patches by providing an array of objects with the following structure:
```lua
{
    {text = "@@ -1,4 +1,4 @@\n-old\n+new\n context"},
    {text = "@@ -10,3 +10,4 @@\n context\n+added line\n context"}
}
```

**Example:**

```lua
local original = "Hello world"
local modified = "Hello beautiful world"

-- Create patches internally
local patches, err = differ:patch_make(original, modified)
if err then
    error("Patch creation failed: " .. err)
end

-- Apply patches
local result, success = differ:patch_apply(patches, original)
if not success then
    print("Warning: Some patches failed to apply")
end

print("Result: " .. result)
print("Matches target: " .. tostring(result == modified))

-- Example with external patches from another system
local external_patches = {
    {text = "@@ -7,5 +7,15 @@\n llo \n-w\n+beautiful w\n orld\n"}
}

local external_result, external_success = differ:patch_apply(external_patches, original)
if external_success then
    print("External patch applied: " .. external_result)
end
```

### `differ:summarize(diffs)`

**Description:**  
Analyzes an array of diff operations and returns statistics about the changes.

**Parameters:**

- **`diffs`** (array): Array of diff objects from `compare()`

**Returns:**

- Summary table containing:
  - **`insertions`** (number): Total characters inserted
  - **`deletions`** (number): Total characters deleted
  - **`equals`** (number): Total characters unchanged

**Example:**

```lua
local diffs, err = differ:compare("The old text", "The new text")
if err then
    error("Compare failed: " .. err)
end

local summary = differ:summarize(diffs)
print("Changes: " .. summary.deletions .. " deletions, " .. summary.insertions .. " insertions")
print("Unchanged: " .. summary.equals .. " characters")
```

---

## Regexp Object Methods

Once created, Regexp objects provide the following methods:

### `regex:find_all_string_submatch(text)`

**Description:**  
Finds all matches of the pattern in the text and returns all submatches for each match.

**Parameters:**

- **`text`** (string): The text to search in

**Returns:**

- Array of match arrays, where each match array contains the full match and any captured groups

**Example:**

```lua
local regex, _ = text.regexp.compile("(\\w+)@(\\w+\\.\\w+)")
local matches = regex:find_all_string_submatch("Contact john@example.com or jane@test.org")
-- Returns: {{"john@example.com", "john", "example.com"}, {"jane@test.org", "jane", "test.org"}}
```

### `regex:find_string_submatch(text)`

**Description:**  
Finds the first match of the pattern in the text and returns all submatches.

**Parameters:**

- **`text`** (string): The text to search in

**Returns:**

- Array containing the full match and any captured groups, or `nil` if no match

### `regex:find_all_string(text)`

**Description:**  
Finds all matches of the pattern in the text.

**Parameters:**

- **`text`** (string): The text to search in

**Returns:**

- Array of matched strings

### `regex:find_string(text)`

**Description:**  
Finds the first match of the pattern in the text.

**Parameters:**

- **`text`** (string): The text to search in

**Returns:**

- The matched string, or `nil` if no match

### `regex:find_all_string_index(text)`

**Description:**  
Finds all matches and returns their positions in the text.

**Parameters:**

- **`text`** (string): The text to search in

**Returns:**

- Array of position arrays, where each position array contains `{start, end}` (1-based, inclusive)

### `regex:find_string_index(text)`

**Description:**  
Finds the first match and returns its position.

**Parameters:**

- **`text`** (string): The text to search in

**Returns:**

- Position array `{start, end}` (1-based, inclusive), or `nil` if no match

### `regex:replace_all_string(text, replacement)`

**Description:**  
Replaces all matches of the pattern with the replacement string.

**Parameters:**

- **`text`** (string): The text to perform replacements in
- **`replacement`** (string): The replacement string (can include `$1`, `$2`, etc. for captured groups)

**Returns:**

- The text with all matches replaced

### `regex:match_string(text)`

**Description:**  
Tests whether the pattern matches the text.

**Parameters:**

- **`text`** (string): The text to test

**Returns:**

- `true` if the pattern matches, `false` otherwise

### `regex:split(text, n)`

**Description:**  
Splits the text using the pattern as delimiter.

**Parameters:**

- **`text`** (string): The text to split
- **`n`** (number, optional): Maximum number of splits (-1 for unlimited, default: -1)

**Returns:**

- Array of split parts

### `regex:num_subexp()`

**Description:**  
Returns the number of parenthesized subexpressions in the pattern.

**Returns:**

- Number of capture groups

### `regex:subexp_names()`

**Description:**  
Returns the names of the parenthesized subexpressions.

**Returns:**

- Array of subexpression names (empty strings for unnamed groups)

### `regex:string()`

**Description:**  
Returns the source text of the regular expression.

**Returns:**

- The original pattern string

---

## Working with External Patches

The text module's diff functionality supports interoperability with external systems through standardized patch formats. This enables external agents, version control systems, or other tools to generate patches that can be applied using the text module.

### Patch Format Specification

Patches use the unified diff format compatible with the Google Diff-Match-Patch algorithm:

```
@@ -start_line,context_lines +start_line,context_lines @@
 context_line
-deleted_line  
+inserted_line
 context_line
```

### Creating External Patches

External agents can create patches by generating patch objects with the following structure:

```lua
local external_patches = {
    {
        text = "@@ -1,4 +1,4 @@\n context\n-old text\n+new text\n context"
    },
    {
        text = "@@ -10,3 +10,4 @@\n context\n+added line\n context"
    }
}
```

### Patch Interoperability Examples

#### Example 1: Git-Style Workflow

```lua
local text = require("text")

-- Simulate receiving patches from a git diff or external system
local function apply_git_style_patches(original_content, patch_data)
    local differ, err = text.diff.new({
        patch_margin = 3,
        match_threshold = 0.3
    })
    if err then
        error("Failed to create differ: " .. err)
    end
    
    -- Convert external patch format to our format
    local patches = {}
    for _, patch_text in ipairs(patch_data) do
        table.insert(patches, {text = patch_text})
    end
    
    -- Apply patches
    local result, success = differ:patch_apply(patches, original_content)
    
    return result, success
end

-- Usage
local original = "function hello() {\n    console.log('Hello');\n}"
local git_patches = {
    "@@ -1,3 +1,4 @@\n function hello() {\n+    console.log('debug');\n     console.log('Hello');\n }"
}

local patched_code, success = apply_git_style_patches(original, git_patches)
if success then
    print("Successfully applied git patches:")
    print(patched_code)
end
```

#### Example 2: AI Agent Patch Generation

```lua
local text = require("text")

-- AI agent generates patches for code modifications
local function ai_generate_patches(original_code, modification_instructions)
    local differ, err = text.diff.new()
    if err then
        error("Failed to create differ: " .. err)
    end
    
    -- AI logic would generate the modified code based on instructions
    -- This is a simplified example
    local modified_code = original_code:gsub("Hello", "Hello World")
    
    -- Generate patches that can be shared with other systems
    local patches, err = differ:patch_make(original_code, modified_code)
    if err then
        error("Failed to generate patches: " .. err)
    end
    
    -- Return patches in a format that external systems can use
    local exportable_patches = {}
    for i, patch in ipairs(patches) do
        table.insert(exportable_patches, {
            id = i,
            description = modification_instructions,
            patch_data = patch.text,
            format = "unified_diff"
        })
    end
    
    return exportable_patches
end

-- Usage
local code = "console.log('Hello');"
local patches = ai_generate_patches(code, "Add 'World' to greeting")

-- These patches can now be serialized and sent to other systems
for i, patch in ipairs(patches) do
    print("Patch " .. patch.id .. ": " .. patch.description)
    print("Data: " .. patch.patch_data)
end
```

#### Example 3: Cross-System Patch Exchange

```lua
local text = require("text")

-- Function to exchange patches between different systems
local function patch_exchange_workflow()
    local differ, err = text.diff.new()
    if err then
        error("Failed to create differ: " .. err)
    end
    
    -- System A generates patches
    local original_doc = "# Title\n\nOriginal content."
    local modified_doc = "# Updated Title\n\nModified content with additions."
    
    local patches, err = differ:patch_make(original_doc, modified_doc)
    if err then
        error("Failed to create patches: " .. err)
    end
    
    -- Serialize patches for transmission (simplified)
    local serialized_patches = {}
    for i, patch in ipairs(patches) do
        serialized_patches[i] = {
            text = patch.text,
            version = "1.0",
            algorithm = "diff-match-patch"
        }
    end
    
    -- System B receives and applies patches
    local received_patches = {}
    for i, serialized in ipairs(serialized_patches) do
        table.insert(received_patches, {text = serialized.text})
    end
    
    local result, success = differ:patch_apply(received_patches, original_doc)
    
    return {
        original = original_doc,
        modified = modified_doc,
        patched = result,
        success = success,
        matches = (result == modified_doc)
    }
end

local workflow_result = patch_exchange_workflow()
print("Patch exchange successful: " .. tostring(workflow_result.success))
print("Result matches expected: " .. tostring(workflow_result.matches))
```

### Best Practices for External Patches

1. **Validation**: Always validate patch format before application
2. **Error Handling**: Handle patch application failures gracefully
3. **Context Preservation**: Ensure sufficient context lines for reliable application
4. **Version Compatibility**: Document patch format version for future compatibility
5. **Fallback Strategies**: Implement fallback mechanisms for failed patch applications

```lua
local function safe_external_patch_application(text_content, external_patches)
    local differ, err = text.diff.new({
        patch_margin = 4,  -- More context for better matching
        patch_delete_threshold = 0.8  -- More lenient threshold
    })
    if err then
        return nil, "Failed to create differ: " .. err
    end
    
    -- Validate patch format
    for i, patch in ipairs(external_patches) do
        if type(patch) ~= "table" or type(patch.text) ~= "string" then
            return nil, "Invalid patch format at index " .. i
        end
    end
    
    -- Apply patches with error handling
    local result, success = differ:patch_apply(external_patches, text_content)
    
    if not success then
        -- Implement fallback strategy
        return text_content, "Patches applied with conflicts - returned original content"
    end
    
    return result, nil
end
```

---

## Best Practices

### 1. Choose the Right Tool

```lua
-- For document chunking (AI/ML workflows)
local splitter = text.splitter.recursive({
    chunk_size = 1000,
    chunk_overlap = 150
})

-- For version control and change tracking
local differ = text.diff.new({
    diff_timeout = 1.0,
    match_threshold = 0.5
})

-- For markdown documentation
local md_splitter = text.splitter.markdown({
    heading_hierarchy = true,
    code_blocks = true
})

-- For pattern matching and extraction
local email_regex = text.regexp.compile("\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b")
```

### 2. Configure for Your Use Case

```lua
-- For embeddings with token limits
local embedding_splitter = text.splitter.recursive({
    chunk_size = 800,    -- Leave room for metadata
    chunk_overlap = 100
})

-- For code comparison (strict matching)
local code_differ = text.diff.new({
    match_threshold = 0.0,  -- Exact matches only
    diff_edit_cost = 10     -- Higher cost for edits
})

-- For fuzzy document comparison
local doc_differ = text.diff.new({
    match_threshold = 0.8,  -- More flexible matching
    diff_timeout = 2.0      -- Allow more time for complex diffs
})
```

### 3. Error Handling Pattern

```lua
local function safe_text_processing(old_text, new_text)
    local differ, err = text.diff.new({diff_timeout = 5.0})
    if err then
        return nil, "Failed to create differ: " .. err
    end
    
    -- Validate inputs
    if type(old_text) ~= "string" or type(new_text) ~= "string" then
        return nil, "Both inputs must be strings"
    end
    
    -- Perform comparison
    local diffs, err = differ:compare(old_text, new_text)
    if err then
        return nil, "Comparison failed: " .. err
    end
    
    -- Generate output
    local pretty, err = differ:pretty_text(diffs)
    if err then
        return nil, "Pretty text generation failed: " .. err
    end
    
    return {
        diffs = diffs,
        pretty = pretty,
        summary = differ:summarize(diffs)
    }
end
```

### 4. Complete Example Usage

```lua
local text = require("text")

-- Document processing with change tracking and external patch support
local function complete_document_workflow()
    -- Create tools
    local splitter, err = text.splitter.recursive({
        chunk_size = 1000,
        chunk_overlap = 150
    })
    if err then
        error("Failed to create splitter: " .. err)
    end
    
    local differ, err = text.diff.new({
        diff_timeout = 1.0,
        match_threshold = 0.5
    })
    if err then
        error("Failed to create differ: " .. err)
    end
    
    -- Process document
    local original_doc = [[
# Document Title

This is the original introduction.

## Section 1
Original content here.
]]
    
    local modified_doc = [[
# Document Title

This is the updated introduction with more details.

## Section 1
Enhanced content with examples.

## Section 2
New section added.
]]
    
    -- Generate diff and patches
    local diffs, err = differ:compare(original_doc, modified_doc)
    if err then
        error("Failed to compare: " .. err)
    end
    
    local patches, err = differ:patch_make(original_doc, modified_doc)
    if err then
        error("Failed to create patches: " .. err)
    end
    
    local summary = differ:summarize(diffs)
    local pretty_diff, err = differ:pretty_text(diffs)
    if err then
        error("Failed to create pretty diff: " .. err)
    end
    
    -- Split the modified document for processing
    local chunks, err = splitter:split_text(modified_doc)
    if err then
        error("Failed to split document: " .. err)
    end
    
    -- Export patches for external systems
    local exportable_patches = {}
    for i, patch in ipairs(patches) do
        table.insert(exportable_patches, {
            text = patch.text,
            format = "unified_diff",
            created = os.time()
        })
    end
    
    return {
        summary = summary,
        diff_output = pretty_diff,
        chunk_count = #chunks,
        exportable_patches = exportable_patches,
        can_roundtrip = true
    }
end

-- Execute workflow
local result = complete_document_workflow()
print("Document processing complete:")
print("Changes: " .. result.summary.insertions .. " insertions, " .. result.summary.deletions .. " deletions")
print("Chunks created: " .. result.chunk_count)
print("Patches available for export: " .. #result.exportable_patches)
```

This specification provides comprehensive coverage of the text module's capabilities, with particular emphasis on the external patch functionality that enables integration with other systems and agents.