local test = require("test")
local json = require("json")
local read = require("attention_read")
local guard = require("attention_guard")

local PREFIX = "wippy.agent.tools:"
local function ref(id, mount)
    return {host_instance_id="host", node_id=id, mount_id=mount or "mount", generation=1}
end
local function call(name, args, id)
    return {id=id or "call-1", name=name, registry_id=PREFIX..name, arguments=args or {}}
end
local function history(events)
    local all = {{id="user-1", role="user", content="Find target"}}
    for _, event in ipairs(events or {}) do all[#all+1] = event end
    return {truncated=false, events=all}
end
local function prior(name, args, result)
    return {role="private_function", content=args or {}, metadata={registry_id=PREFIX..name, result=result or {}}}
end

local function define_tests()
    test.describe("Explicit Attention reads", function()
        test.it("separates semantic, CSS and exact identity requests", function()
            local semantic = read.normalize("attention_find_semantic", {name="Right"})
            test.eq(semantic.operation, "find")
            test.eq(semantic.args.limit, 8)
            test.eq(semantic.args.query.name, "Right")
            test.is_nil(read.normalize("attention_find_semantic", {selector="button"}))
            test.is_nil(read.normalize("attention_find_css", {selector="button"}))
            local css = read.normalize("attention_find_css", {selector="button", root=ref("document")})
            test.eq(css.args.query.scope.node_id, "document")
            test.eq(css.args.query.css, "button")
            test.is_nil(read.normalize("attention_find_semantic", {name="Right", limit=9}))
            test.is_nil(read.normalize("attention_get_geometry", {node={node_id="fake"}}))
            local exact = read.normalize("attention_get_node", {node_id="node-1"})
            test.eq(exact.args.limit, 1)
            test.is_true(read.normalize("attention_get_node", {node_id=string.rep("n",256)}) ~= nil)
            test.is_nil(read.normalize("attention_get_node", {node_id=string.rep("n",257)}))
            test.eq(read.normalize("attention_get_tree",{depth=0}).args.depth,0)
        end)
        test.it("bounds pages without restricting semantic traversal depth", function()
            for _, name in ipairs({"attention_get_cursor", "attention_get_focus", "attention_get_selection"}) do
                test.eq(json.encode(read.normalize(name, {}).args), "{}")
            end
            local tree = read.normalize("attention_get_tree", {})
            test.eq(tree.args.depth, 2)
            test.eq(tree.args.limit, 32)
            local search = read.normalize("attention_find_semantic", {role="button"})
            test.is_nil(search.args.depth)
            test.is_nil(read.normalize("attention_hit_test", {x=0/0, y=1}))
            test.is_nil(read.normalize("attention_get_focus", {scope=ref("node"), arbitrary=true}))
        end)
        test.it("returns bounded validation guidance without permitting policy retries", function()
            for reason in pairs(read.validation_errors) do
                local receipt = read.receipt(reason, PREFIX.."attention_get_selection")
                receipt.invalid = true
                test.eq(receipt.reason, reason)
                test.not_nil((receipt.instruction:find("pass {}",1,true)))
                test.is_true(#json.encode(receipt) <= 512)
            end
            test.is_nil((read.receipt("read-budget-exhausted", PREFIX.."attention_get_selection").instruction:find("Correct",1,true)))
        end)
        test.it("deduplicates complete paths and preserves canonical identity", function()
            local path = {}
            for i=1, 17 do path[i]={kind="shadow-root", mount_id="ancestor-"..i, generation=1, label="ancestor "..i, rect={x=0,y=0,width=100,height=100}} end
            local nodes = {}
            for i=1, 8 do nodes[i]={ref=ref("node-"..i), parent=ref("parent"), kind="element", state="mounted", summary={name="Target "..i}, path=path} end
            local raw={host_instance_id="host", status="inspected", inspection={outcome="ok", revisions={tree=1}, data={nodes=nodes}, omissions={}}}
            local compact=read.project(raw, "attention_find_semantic")
            test.eq(#compact.nodes, 8)
            test.eq(#compact.paths, 17)
            test.eq(#compact.nodes[8][6], 17)
            test.eq(compact.nodes[8][1][1], "node-8")
            test.is_nil(compact.paths[1].rect)
            test.is_true(#json.encode(compact) < #json.encode(raw) / 2)
            test.is_true(#json.encode(compact) <= 8192)
        end)
        test.it("joins exact action references and rejects mismatched mounts", function()
            local node={ref=ref("n"), parent=ref("p"), path={}, summary={name="Button"}, kind="element", state="mounted"}
            local raw={host_instance_id="host",status="inspected", inspection={outcome="ok", data={nodes={node}}, omissions={}},targets={{target_id="n",host_instance_id="host",mount_id="wrong",generation=1}}}
            test.is_nil(read.project(raw,"attention_get_node").target_ref)
            raw.targets[1].mount_id="mount"
            test.eq(read.project(raw,"attention_get_node").target_ref.target_id,"n")
            node.path={{kind="element",mount_id="leaf-mount",generation=2}}
            test.is_nil(read.project(raw,"attention_get_node").target_ref)
            raw.targets[1].mount_id="leaf-mount"
            raw.targets[1].generation=2
            test.eq(read.project(raw,"attention_get_node").target_ref.target_id,"n")
        end)
        test.it("does not expose a continuation after mandatory data overflows", function()
            local node={ref=ref("n"), parent=ref("p"), path={}, summary={text=string.rep("😀",3000)}, kind="element", state="mounted"}
            local compact=read.project({status="inspected",inspection={outcome="ok",data={nodes={node}},continuation="advanced",omissions={}}},"attention_get_tree")
            test.eq(compact.outcome,"partial")
            test.eq(compact.omissions[1].reason,"byte-limit")
            test.is_nil(compact.continuation)
            test.is_true(#json.encode(compact)<=8192)
        end)
        test.it("preserves source event times and cleared selection outcome", function()
            local raw={status="inspected",inspection={outcome="ok",data={event={event_id="e",observed_at="original",candidate_ids={"n"},point={x=1,y=2}}}}}
            test.eq(read.project(raw,"attention_get_cursor").event.observed_at,"original")
            raw.inspection={outcome="cleared",data={}}
            test.eq(read.project(raw,"attention_get_selection").outcome,"cleared")
        end)
        test.it("counts Host syntax validation failures toward repair limits", function()
            local raw={status="inspected",inspection={outcome="unavailable",omissions={{reason="invalid-request"}}}}
            test.is_true(read.project(raw,"attention_find_css").invalid)
        end)
        test.it("preserves Unicode selection and deduplicates both complete endpoint paths", function()
            local path={{kind="shadow-root",mount_id="m",generation=1},{kind="element",mount_id="m",generation=1,selector_hint="span"}}
            local selection={selection_id="s",selected_at="original",kind="text",collapsed=false,direction="backward",text="Zażółć 😀",anchor_path=path,focus_path=path,ranges={{rect={x=1,y=2,width=3,height=4},coordinate_space="host-viewport"}}}
            local compact=read.project({status="inspected",inspection={outcome="ok",data={selection=selection,anchor=ref("a"),focus=ref("b")}}},"attention_get_selection")
            test.eq(compact.selection.text,selection.text)
            test.eq(compact.selection.selected_at,"original")
            test.eq(compact.selection.collapsed,false)
            test.eq(#compact.paths,2)
            test.eq(#compact.selection.anchor_path,2)
            test.eq(compact.selection.focus_path[2],compact.selection.anchor_path[2])
            test.eq(compact.anchor[1],"a")
            test.eq(compact.focus[1],"b")
        end)
    end)
    test.describe("Attention trait guard", function()
        test.it("retains unrelated calls and one paired result for every rejected read", function()
            local other={id="other",name="other",registry_id="app:other",arguments={}}
            local result=guard.apply_history({tool_calls={call("attention_get_focus"),other,call("attention_get_cursor",{scope=ref("node")},"second")}},history())
            test.eq(#result.tool_calls,3)
            test.eq(result.tool_calls[2],other)
            test.eq(result.tool_calls[3].id,"second")
            test.eq(result.tool_calls[3].name,"attention_get_cursor")
            test.eq(result.tool_calls[3].registry_id,read.receipt_id)
            test.eq(result.tool_calls[3].arguments.scope.node_id,"node")
            test.is_nil(result.tool_calls[3].arguments.reason)
            test.eq(result.tool_calls[3].context.attention_refusal.reason,"one-read-per-batch")
        end)
        test.it("keeps the model's own arguments and tool context when refusing a read", function()
            local refused=call("attention_get_focus",{arbitrary=true})
            refused.context={agent_setting="kept"}
            refused.provider_metadata={signature="sig"}
            local out=guard.apply_history({tool_calls={refused}},history()).tool_calls[1]
            test.eq(out.id,"call-1")
            test.eq(out.name,"attention_get_focus")
            test.eq(out.registry_id,read.receipt_id)
            test.eq(out.arguments,refused.arguments)
            test.eq(out.arguments.arbitrary,true)
            test.is_nil(out.arguments.reason)
            test.eq(out.provider_metadata.signature,"sig")
            test.eq(out.context.agent_setting,"kept")
            local refusal=out.context.attention_refusal
            test.eq(refusal.reason,"unexpected-field")
            test.eq(refusal.original_registry_id,PREFIX.."attention_get_focus")
            test.is_true(refusal.invalid)
            test.is_nil(rawget(refused.context, "attention_refusal"))
        end)
        test.it("refuses a call to the removed attention_inspect ID without executing it", function()
            local legacy=call("attention_inspect",{operation="tree",args={limit=500}})
            local out=guard.apply_history({tool_calls={legacy}},history()).tool_calls[1]
            test.eq(out.registry_id,read.receipt_id)
            test.eq(out.arguments.operation,"tree")
            test.eq(out.context.attention_refusal.reason,"invalid-request")
            test.is_true(out.context.attention_refusal.invalid)
        end)
        test.it("counts private failures and guard receipts before the fifth attempt", function()
            local events={prior("attention_get_focus"),prior("attention_get_cursor"),prior("attention_read_receipt"),prior("attention_read_receipt")}
            local result=guard.apply_history({tool_calls={call("attention_get_focus")}},history(events))
            test.eq(result.tool_calls[1].context.attention_refusal.reason,"read-budget-exhausted")
            local reset=history(events)
            reset.events[#reset.events+1]={id="user-2",role="user"}
            test.eq(guard.apply_history({tool_calls={call("attention_get_focus")}},reset).tool_calls[1].registry_id,PREFIX.."attention_get_focus")
        end)
        test.it("fails closed on unavailable or truncated history without touching other tools", function()
            local other={id="other",registry_id="app:other"}
            local result=guard.apply_history({tool_calls={other,call("attention_get_focus")}}, {truncated=true,events=history().events})
            test.eq(result.tool_calls[1],other)
            test.eq(result.tool_calls[2].context.attention_refusal.reason,"history-unavailable")
            test.eq(guard.apply_history({tool_calls={other}},nil).tool_calls[1],other)
        end)
        test.it("limits malformed repairs and suppresses repeated static reads", function()
            local events={prior("attention_read_receipt",{}, {invalid=true}),prior("attention_read_receipt",{}, {invalid=true})}
            test.eq(guard.apply_history({tool_calls={call("attention_get_focus")}},history(events)).tool_calls[1].context.attention_refusal.reason,"repair-budget-exhausted")
            local args={name="Right"}
            local found=prior("attention_find_semantic",args,{status="inspected",outcome="ok",revisions={tree=1}})
            local duplicate=guard.apply_history({tool_calls={call("attention_find_semantic",args)}},history({found}))
            test.eq(duplicate.tool_calls[1].context.attention_refusal.reason,"duplicate-read")
            test.eq(duplicate.tool_calls[1].arguments.name,"Right")
            local next_page=guard.apply_history({tool_calls={call("attention_find_semantic",{name="Right",continuation="next"})}},history({found}))
            test.eq(next_page.tool_calls[1].registry_id,PREFIX.."attention_find_semantic")
            found.metadata.stale = "Attention observation expired."
            local refreshed=guard.apply_history({tool_calls={call("attention_find_semantic",args)}},history({found}))
            test.eq(refreshed.tool_calls[1].registry_id,PREFIX.."attention_find_semantic")
            local exhausted=guard.apply_history({tool_calls={call("attention_find_semantic",args)}},history({found,found,found,found}))
            test.eq(exhausted.tool_calls[1].context.attention_refusal.reason,"read-budget-exhausted")
        end)
    end)
end

return {run_tests=test.run_cases(define_tests)}
