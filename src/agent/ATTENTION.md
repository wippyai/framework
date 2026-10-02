# Attention tools

Add `wippy.agent.traits:attention` to an agent to let it read the current interface through its authenticated submitting Host. Automatic context attachments can remain off. The trait does not grant permission to click, select an area, or capture an image.

| Tool | Example arguments | Purpose |
|---|---|---|
| `attention_find_semantic` | `{"role":"button","name":"Save"}` | Find matching semantics throughout the permitted tree. |
| `attention_find_css` | `{"selector":"button","root":ref}` | Query one known document or shadow root. |
| `attention_get_node` | `{"node_id":"returned-canonical-id"}` | Resolve one known identity. |
| `attention_get_tree` | `{"scope":ref,"limit":16,"depth":2}` | Read a bounded subtree page. |
| `attention_get_geometry` | `{"node":ref}` | Get geometry, coordinate space and quality. |
| `attention_get_cursor` | `{}` | Read the current pointer observation. |
| `attention_get_focus` | `{}` | Read the focused target. |
| `attention_get_selection` | `{}` | Read selected text and both endpoint paths. |
| `attention_hit_test` | `{"x":100,"y":120,"coordinate_space":"host-viewport"}` | Inspect a point with the existing bounded sampling defaults. |

In the examples, `ref` means the complete returned object with `host_instance_id`, `node_id`, `mount_id` and `generation`. Never construct these values from labels, selectors or row positions. Semantic search accepts at least one of `role`, `name`, `text` and `resource_id`. CSS and semantic fields cannot be mixed. Search returns at most eight matches. Tree reads return at most 32 nodes and default to depth two. Semantic search retains the full traversal depth and work budget.

## Model results and history

The tool authenticates the complete private Host reply before projecting it as `wippy.attention.model.v1`. Session stores that compact result in ordinary private function history. Later model generations therefore see the compact result again. This feature does not evict history or provide a full-result retrieval store.

Node rows follow `columns`. Each compact reference is `[canonical_node_id, mount_index]`. The one-based `mounts` dictionary follows `mount_columns`. Node, focus and selection path arrays contain one-based indices into `paths`. They retain every returned ancestry segment while sharing repeated segments. Indices have meaning only within that result. Selection text and event timestamps are preserved. Geometry is included when the operation requires it.

A unique node can include an unchanged `target_ref` for the existing action tools. It is joined by canonical node ID, Host, terminal path mount and generation. The existing action contract binds that terminal mount; the canonical NodeRef names the owning inspection realm, which can be different. Do not substitute one mount for the other. Only the Host can refresh expired action authority. Reading old history does not refresh it.

Each serialized successful projection is limited to 8 KiB. A result that cannot preserve mandatory content within that limit becomes a small typed partial result. Its continuation is removed so it cannot skip discarded rows. Ask for a smaller scoped page or an exact node. Continuations remain bound to the same query, revision and existing 30-second expiry; they cannot be replayed.

## Read limits

The Attention trait installs a `before_execute` wrapper. It admits one Attention read per tool batch and at most four attempted reads per user turn. Invalid and refused attempts count. Two invalid attempts end repair. Unchanged static queries are refused unless an observed revision change or interaction justifies another read. Current pointer, focus and selection observations can be refreshed within the same budget.

The wrapper reads trusted Session history, including private function records. If it cannot establish the latest user-turn boundary, it refuses the read. It preserves each original tool-call ID, name and arguments and substitutes a private terminal receipt for refused Attention calls. The refusal reason travels in tool context, so history keeps the model's own call unchanged. Unrelated tools in the same batch pass through unchanged. Receipts have no Host authority and are not advertised to the model.

These limits bound Attention Host work. They do not enforce a global model-generation or cost limit. A validation receipt preserves its exact reason and permits one corrected call within the remaining budget. Policy and budget refusals instruct the model to answer from available evidence. Agents without this trait keep their existing tool and history behavior. The unrestricted `attention_inspect` tool was removed, and the explicit read tools above replace it. Its ID has no registry entry and no runtime authority. It is still recognized in stored history, and the guard turns any new call to it into a refusal receipt.

## Verification

The owning Agent tests cover normalization, compact identity and ancestry, Unicode selection, byte overflow, action-reference joins, mixed batches, history completeness, attempt limits and duplicate suppression. The real application must also verify a fresh no-attachment named-target answer, observation reads and existing action consent flows. A successful unit suite alone does not complete the local release candidate.
