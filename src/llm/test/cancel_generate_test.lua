local test = require("test")
local llm = require("llm")
local output = require("output")
local store = require("store")
local time = require("time")

local PROVIDER = "app:streaming_provider"

local function scenario(mode, chunks)
    local s = store.get("app:test_store")
    s:set("streaming_scenario", { mode = mode, chunks = chunks })
    s:set("streaming_started", false)
    s:set("streaming_held", false)
    s:set("streaming_resumed", false)
    return s
end

-- Runs llm.generate in a coroutine so the test can observe the stream and cancel.
local function start_generate(options)
    local done = channel.new(1)
    coroutine.spawn(function()
        local result, err = llm.generate("Say something.", options)
        done:send({ result = result, err = err })
    end)
    return done
end

local function receive_within(ch, duration, description)
    local timer = time.timer(duration)
    local selected = channel.select({ ch:case_receive(), timer:channel():case_receive() })
    timer:stop()
    if selected.channel ~= ch then error("Deadline waiting for " .. description) end
    return selected.value
end

local function define_tests()
    describe("Cancellable generation", function()
        local original_resolver = llm._model_resolver
        after_each(function() llm._model_resolver = original_resolver end)

        it("cancels a real fallback attempt without dispatching another model", function()
            local s = scenario("hold", { "Backup partial" })
            s:set("streaming_scenario", { mode = "hold", chunks = { "Backup partial" }, fallback = true })
            for _, name in ipairs({ "primary", "backup", "third" }) do s:set("streaming_" .. name, false) end
            llm._model_resolver = { resolve = function(_, args)
                return { id = "app:" .. args.model, name = args.model, capabilities = { "generate" },
                    fallback = args.model == "primary" and { "backup", "third" } or nil,
                    providers = { { id = PROVIDER, provider_model = args.model } } }
            end }
            local stream = process.listen("cancel_test.fallback")
            local cancel = channel.new(1)
            local done = start_generate({ model = "primary", cancel = cancel, deadline_ms = 10000,
                stream = { reply_to = process.pid(), topic = "cancel_test.fallback" } })
            test.eq(receive_within(stream, "5s", "fallback chunk").content, "Backup partial")
            cancel:send(true)
            local outcome = receive_within(done, "2s", "cancelled fallback")
            process.unlisten(stream)
            test.is_nil(outcome.err)
            test.eq(outcome.result.finish_reason, output.FINISH_REASON.CANCELLED)
            test.eq(outcome.result.result, "Backup partial")
            test.is_true((s:get("streaming_primary")))
            test.is_true((s:get("streaming_backup")))
            test.is_false((s:get("streaming_third")))
        end)

        it("does not dispatch a provider when cancellation is already signaled", function()
            local s = scenario("complete", { "must not run" })
            local cancel = channel.new()
            cancel:close()
            local result, err = llm.generate("Say something.", {
                model = "fixture", provider_id = PROVIDER, cancel = cancel,
            })
            test.is_nil(err)
            test.eq(result.finish_reason, output.FINISH_REASON.CANCELLED)
            test.eq(result.result, "")
            test.is_false((s:get("streaming_started")))
        end)

        it("cancels an in-flight streaming call and returns the streamed text", function()
            local s = scenario("hold", { "Partial ", "answer" })
            local stream = process.listen("cancel_test.stream")
            local cancel = channel.new()
            local done = start_generate({
                model = "fixture", provider_id = PROVIDER, cancel = cancel,
                stream = { reply_to = process.pid(), topic = "cancel_test.stream" },
            })

            local first = receive_within(stream, "5s", "first chunk")
            local second = receive_within(stream, "5s", "second chunk")
            test.eq(first.type, output.TYPE.CONTENT)
            test.eq(first.content .. second.content, "Partial answer")

            local started = time.now()
            cancel:close()
            local outcome = receive_within(done, "2s", "cancelled generation")
            process.unlisten(stream)

            test.is_true(time.now():sub(started):seconds() < 2)
            test.is_nil(outcome.err)
            test.eq(outcome.result.finish_reason, output.FINISH_REASON.CANCELLED)
            test.eq(outcome.result.result, "Partial answer")
            test.eq(#outcome.result.tool_calls, 0)
            test.is_true((s:get("streaming_held")))
            test.is_false((s:get("streaming_resumed")))
        end)

        it("cancels an in-flight call without a stream", function()
            scenario("hold", {})
            local cancel = channel.new()
            local done = start_generate({ model = "fixture", provider_id = PROVIDER, cancel = cancel })
            local s = store.get("app:test_store")
            local timer = time.timer("5s")
            while not s:get("streaming_held") do
                local selected = channel.select({ timer:channel():case_receive(), default = true })
                if not selected.default then error("Deadline waiting for the provider call") end
                time.sleep("10ms")
            end
            timer:stop()

            cancel:send(true)
            local outcome = receive_within(done, "2s", "cancelled generation")

            test.is_nil(outcome.err)
            test.eq(outcome.result.finish_reason, output.FINISH_REASON.CANCELLED)
            test.eq(outcome.result.result, "")
        end)

        it("relays every chunk in order and returns the provider result when not cancelled", function()
            local chunks = {}
            for index = 1, 50 do chunks[index] = "c" .. index .. " " end
            scenario("complete", chunks)
            local stream = process.listen("cancel_test.relay")
            local cancel = channel.new()
            local done = start_generate({
                model = "fixture", provider_id = PROVIDER, cancel = cancel,
                stream = { reply_to = process.pid(), topic = "cancel_test.relay" },
            })

            local outcome = receive_within(done, "5s", "completed generation")
            local received = {}
            for index = 1, #chunks do
                received[index] = receive_within(stream, "1s", "relayed chunk " .. index).content
            end
            process.unlisten(stream)

            test.is_nil(outcome.err)
            test.eq(outcome.result.finish_reason, "stop")
            test.eq(outcome.result.result, table.concat(chunks))
            test.eq(table.concat(received), table.concat(chunks))
            test.eq(outcome.result.tokens.completion_tokens, #chunks)
        end)

        it("keeps the direct provider call when no cancel channel is given", function()
            scenario("complete", { "Whole answer" })

            local result, err = llm.generate("Say something.", { model = "fixture", provider_id = PROVIDER })

            test.is_nil(err)
            test.eq(result.result, "Whole answer")
            test.eq(result.finish_reason, "stop")
        end)
    end)
end

return require("test").run_cases(define_tests)
