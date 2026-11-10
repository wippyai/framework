# Gemini structured-output transport

The Google structured-output handler sends JSON Schema in `generationConfig.responseJsonSchema`. The `responseSchema` field describes an OpenAPI schema and rejects JSON Schema fields such as `additionalProperties`.

The nested closed-object regression fails before the change and passes afterward. The full LLM gate passes with the official runtime v0.3.59a, and scoped lint reports no issues.

## Compatibility

The public structured-output contract, model routing, options and result shape remain unchanged. Generative Language and Vertex AI expose `responseJsonSchema`. The handler preserves the caller's schema without rewriting it. No stored data or table write path changes, so this change introduces no steady-state rows at 10x or 100x load.
