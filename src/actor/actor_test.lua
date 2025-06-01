local actor = require("actor")
local time = require("time")
local json = require("json")

local function define_tests()
    -- Main test suite wrapper
    describe("Actor Library Tests", function()
        -- Before each test, reset the actor._process
        before_each(function()
            actor._process = nil

            -- Also ensure we restore the original _G._original_tostring
            -- in case our mock of tostring failed
            if _G._original_tostring then
                _G.tostring = _G._original_tostring
                _G._original_tostring = nil
            end
        end)

        -- Actor Creation and Basic Functionality
        describe("Actor Creation", function()
            it("should create an actor with initial state", function()
                local initial_state = { count = 0 }
                local test_actor = actor.new(initial_state, {})

                expect(test_actor).not_to_be_nil("Actor should be created")
                expect(test_actor.run).to_be_type("function", "Actor should have a run method")
            end)

            it("should throw an error when handlers is not a table", function()
                local success, error_msg = pcall(function()
                    actor.new({}, "not a table")
                end)

                expect(success).to_be_false("Should throw an error")
                expect(tostring(error_msg)).to_match("handlers must be a table",
                    "Error message should indicate handlers must be a table")
            end)
        end)

        -- Actor.exit Tests
        describe("Actor Exit", function()
            it("should create an exit object with result", function()
                local result = { status = "completed" }
                local exit_obj = actor.exit(result)

                expect(exit_obj).not_to_be_nil("Exit object should be created")
                expect(exit_obj._actor_exit).to_be_true("Exit object should have _actor_exit flag")
                expect(exit_obj.result).to_equal(result, "Exit object should contain the result")
            end)
        end)

        -- Actor.next Tests
        describe("Actor Next", function()
            it("should create a next object with specified topic", function()
                local next_topic = "next_handler"
                local next_obj = actor.next(next_topic)

                expect(next_obj).not_to_be_nil("Next object should be created")
                expect(next_obj._actor_next).to_be_true("Next object should have _actor_next flag")
                expect(next_obj.next_topic).to_equal(next_topic, "Next object should contain the topic")
                expect(next_obj.payload).to_be_nil("Payload should be nil for using original payload")
            end)

            it("should create a next object with specified topic and payload", function()
                local next_topic = "next_handler"
                local next_payload = { value = 42 }
                local next_obj = actor.next(next_topic, next_payload)

                expect(next_obj).not_to_be_nil("Next object should be created")
                expect(next_obj._actor_next).to_be_true("Next object should have _actor_next flag")
                expect(next_obj.next_topic).to_equal(next_topic, "Next object should contain the topic")
                expect(next_obj.payload).to_equal(next_payload, "Next object should contain the payload")
            end)
        end)

        -- Test with dependency injection
        describe("Message Handling with DI", function()
            it("should handle inbox messages with correct argument order", function()
                local handler_called = false
                local received_state = nil
                local received_payload = nil
                local received_topic = nil
                local received_from = nil

                -- Create a mock message
                local mock_message = {
                    from = function() return "sender_pid" end,
                    topic = function() return "status" end,
                    payload = function()
                        return {
                            data = function()
                                return {
                                    command = "get_status",
                                    reply_to = "caller_pid"
                                }
                            end
                        }
                    end
                }

                -- Create mock channels
                local inbox_channel = {
                    case_receive = function() return "inbox_case" end
                }

                local events_channel = {
                    case_receive = function() return "events_case" end
                }

                -- Create a mock internal channel
                local internal_channel = {
                    send = function(self, value) return true end,
                    receive = function(self) return nil, false end,
                    case_receive = function(self) return "internal_case" end
                }

                -- Store original functions
                local original_channel = _G.channel
                local original_tostring = _G.tostring

                -- Mock channel
                _G.channel = {
                    new = function(size)
                        return internal_channel
                    end,
                    select = function(cases)
                        -- First simulate inbox message, then exit
                        return {
                            ok = true,
                            channel = inbox_channel,
                            value = mock_message
                        }
                    end
                }

                -- Set up the mock process
                actor._process = {
                    inbox = function() return inbox_channel end,
                    events = function() return events_channel end,
                    send = function(dest, topic, payload)
                        return true
                    end,
                    pid = function() return "test-pid" end,
                    event = {
                        CANCEL = "pid.cancel",
                        EXIT = "pid.exit",
                        LINK_DOWN = "pid.link.down"
                    }
                }

                -- Create the actor with initial state
                local initial_state = { value = 42 }

                -- Create the actor
                local test_actor = actor.new(
                    initial_state,
                    {
                        status = function(state, payload, topic, from)
                            handler_called = true
                            received_state = state
                            received_payload = payload
                            received_topic = topic
                            received_from = from
                            return actor.exit({ status = "ok", value = state.value })
                        end
                    }
                )

                -- Run the actor
                local result = test_actor.run()

                -- Restore original functions
                _G.channel = original_channel
                _G.tostring = original_tostring

                -- Verify handler was called with all parameters in correct order
                expect(handler_called).to_be_true("Inbox handler should have been called")
                expect(received_state).to_equal(initial_state, "State should be passed correctly")
                expect(received_payload.command).to_equal("get_status", "Payload should be passed correctly")
                expect(received_topic).to_equal("status", "Topic should be passed correctly")
                expect(received_from).to_equal("sender_pid", "Sender should be passed correctly")
                expect(result.status).to_equal("ok", "Status should be passed from handler exit")
            end)
        end)

        -- Event Handling Tests with DI
        describe("Event Handling with DI", function()
            it("should handle system events with correct argument order", function()
                local handler_called = false
                local received_state = nil
                local received_event = nil
                local received_kind = nil
                local received_from = nil

                -- Create mock event
                local mock_event = {
                    kind = "pid.exit",
                    from = "other_pid",
                    at = time.now(),
                    result = {
                        error = nil,
                        value = { status = "completed" }
                    }
                }

                -- Create mock channels
                local inbox_channel = {
                    case_receive = function() return "inbox_case" end
                }

                local events_channel = {
                    case_receive = function() return "events_case" end
                }

                -- Create a mock internal channel
                local internal_channel = {
                    send = function(self, value) return true end,
                    receive = function(self) return nil, false end,
                    case_receive = function(self) return "internal_case" end
                }

                -- Store original functions
                local original_channel = _G.channel

                -- Mock channel
                _G.channel = {
                    new = function(size)
                        return internal_channel
                    end,
                    select = function(cases)
                        -- Return event from events channel
                        return {
                            ok = true,
                            channel = events_channel,
                            value = mock_event
                        }
                    end
                }

                -- Set up the mock process
                actor._process = {
                    inbox = function() return inbox_channel end,
                    events = function() return events_channel end,
                    send = function(dest, topic, payload) return true end,
                    pid = function() return "test-pid" end,
                    event = {
                        CANCEL = "pid.cancel",
                        EXIT = "pid.exit",
                        LINK_DOWN = "pid.link.down"
                    }
                }

                -- Create the actor with initial state
                local initial_state = { value = 0 }

                -- Create the actor
                local test_actor = actor.new(
                    initial_state,
                    {
                        __on_event = function(state, event, kind, from)
                            handler_called = true
                            received_state = state
                            received_event = event
                            received_kind = kind
                            received_from = from
                            return actor.exit({ status = "handled", value = 99 })
                        end
                    }
                )

                -- Run the actor
                local result = test_actor.run()

                -- Restore original functions
                _G.channel = original_channel

                -- Verify handler was called with correct parameters in correct order
                expect(handler_called).to_be_true("Event handler should have been called")
                expect(received_state).to_equal(initial_state, "State should be passed correctly")
                expect(received_event).to_equal(mock_event, "Event should be passed correctly")
                expect(received_kind).to_equal("pid.exit", "Event kind should be passed separately")
                expect(received_from).to_equal("other_pid", "Event source should be passed separately")
                expect(result.status).to_equal("handled", "Actor should exit with handler status")
                expect(result.value).to_equal(99, "Handler should affect exit result")
            end)

            it("should handle cancel events with specific handler using correct argument order", function()
                -- Create mock cancel event
                local mock_event = {
                    kind = "pid.cancel",
                    from = "parent_pid",
                    at = time.now(),
                    deadline = time.now():add(5, "s")
                }

                -- Create mock channels
                local inbox_channel = {
                    case_receive = function() return "inbox_case" end
                }

                local events_channel = {
                    case_receive = function() return "events_case" end
                }

                -- Create a mock internal channel
                local internal_channel = {
                    send = function(self, value) return true end,
                    receive = function(self) return nil, false end,
                    case_receive = function(self) return "internal_case" end
                }

                -- Store original functions
                local original_channel = _G.channel

                -- Mock channel
                _G.channel = {
                    new = function(size)
                        return internal_channel
                    end,
                    select = function(cases)
                        -- Return cancel event
                        return {
                            ok = true,
                            channel = events_channel,
                            value = mock_event
                        }
                    end
                }

                -- Set up the mock process
                actor._process = {
                    inbox = function() return inbox_channel end,
                    events = function() return events_channel end,
                    send = function(dest, topic, payload) return true end,
                    pid = function() return "test-pid" end,
                    event = {
                        CANCEL = "pid.cancel",
                        EXIT = "pid.exit",
                        LINK_DOWN = "pid.link.down"
                    }
                }

                local cancel_handler_called = false
                local received_state = nil
                local received_event = nil
                local received_kind = nil
                local received_from = nil

                -- Create the actor with initial state
                local initial_state = { value = 0 }

                -- Create the actor with a specific cancel handler
                local test_actor = actor.new(
                    initial_state,
                    {
                        __on_cancel = function(state, event, kind, from)
                            cancel_handler_called = true
                            received_state = state
                            received_event = event
                            received_kind = kind
                            received_from = from
                            return actor.exit({ status = "cancelled", source = from })
                        end
                    }
                )

                -- Run the actor
                local result = test_actor.run()

                -- Restore original functions
                _G.channel = original_channel

                -- Verify the specific handler was called with correct parameters
                expect(cancel_handler_called).to_be_true("Cancel handler should have been called")
                expect(received_state).to_equal(initial_state, "State should be passed correctly")
                expect(received_event).to_equal(mock_event, "Event should be passed correctly")
                expect(received_kind).to_equal("pid.cancel", "Kind should be passed correctly")
                expect(received_from).to_equal("parent_pid", "Should receive the correct source")
                expect(result.status).to_equal("cancelled", "Should return cancelled status")
                expect(result.source).to_equal("parent_pid", "Should include source in result")
            end)
        end)

        -- Async functionality tests
        describe("Async Function Execution", function()
            it("should pass tasks to coroutine.spawn", function()
                -- Keep track of async function calls
                local spawn_called = false
                local spawn_fn = nil

                -- Create mock channels
                local inbox_channel = {
                    case_receive = function() return "inbox_case" end
                }

                local events_channel = {
                    case_receive = function() return "events_case" end
                }

                -- Create a mock internal channel
                local internal_channel = {
                    send = function(self, value) return true end,
                    receive = function(self) return nil, false end,
                    case_receive = function(self) return "internal_case" end
                }

                -- Store original functions
                local original_channel = _G.channel
                local original_coroutine = _G.coroutine

                -- Mock channel
                _G.channel = {
                    new = function(size)
                        return internal_channel
                    end,
                    select = function(cases)
                        -- Exit after __init runs
                        return { ok = false }
                    end
                }

                -- Mock coroutine
                _G.coroutine = {
                    spawn = function(fn)
                        spawn_called = true
                        spawn_fn = fn
                        return true
                    end
                }

                -- Set up the mock process
                actor._process = {
                    inbox = function() return inbox_channel end,
                    events = function() return events_channel end,
                    send = function(dest, topic, payload) return true end,
                    pid = function() return "test-pid" end,
                    event = {
                        CANCEL = "pid.cancel",
                        EXIT = "pid.exit",
                        LINK_DOWN = "pid.link.down"
                    }
                }

                -- Create the actor with initial state
                local initial_state = { value = 0 }

                -- Create the actor
                local test_actor = actor.new(
                    initial_state,
                    {
                        __init = function(state)
                            -- Start an async task
                            local task = state.async(function()
                                return { success = true }
                            end)

                            return actor.exit({ status = "initialized" })
                        end
                    }
                )

                -- Run the actor
                local result = test_actor.run()

                -- Restore original functions
                _G.channel = original_channel
                _G.coroutine = original_coroutine

                -- Verify async function was passed to coroutine.spawn
                expect(spawn_called).to_be_true("Async function should be passed to coroutine.spawn")
                expect(spawn_fn).to_be_type("function", "Spawned function should be a function")
                expect(result.status).to_equal("initialized", "Actor should exit with correct status")
            end)
        end)

        -- Handler management tests
        describe("Handler Management", function()
            it("should add and remove handlers dynamically", function()
                -- Track handler calls
                local first_handler_called = false
                local second_handler_called = false

                -- Create mock message for testing
                local test_message = {
                    from = function() return "sender_pid" end,
                    topic = function() return "dynamic_topic" end,
                    payload = function()
                        return {
                            data = function()
                                return { value = 42 }
                            end
                        }
                    end
                }

                -- Create mock channels
                local inbox_channel = {
                    case_receive = function() return "inbox_case" end
                }

                local events_channel = {
                    case_receive = function() return "events_case" end
                }

                -- Create a mock internal channel
                local internal_channel = {
                    send = function(self, value) return true end,
                    receive = function(self) return nil, false end,
                    case_receive = function(self) return "internal_case" end
                }

                -- Store original functions
                local original_channel = _G.channel

                -- Set up sequential responses for channel.select
                local select_count = 0
                local select_responses = {
                    -- First return the message to test initial handler
                    {
                        ok = true,
                        channel = inbox_channel,
                        value = test_message
                    },
                    -- Then return the message again to test handler removal
                    {
                        ok = true,
                        channel = inbox_channel,
                        value = test_message
                    },
                    -- Finally exit
                    { ok = false }
                }

                -- Mock channel
                _G.channel = {
                    new = function(size)
                        return internal_channel
                    end,
                    select = function(cases)
                        select_count = select_count + 1
                        return select_responses[select_count]
                    end
                }

                -- Set up the mock process
                actor._process = {
                    inbox = function() return inbox_channel end,
                    events = function() return events_channel end,
                    send = function(dest, topic, payload) return true end,
                    pid = function() return "test-pid" end,
                    event = {
                        CANCEL = "pid.cancel",
                        EXIT = "pid.exit",
                        LINK_DOWN = "pid.link.down"
                    }
                }

                -- Create the actor with initial state
                local initial_state = { value = 0 }

                -- Create the actor with handlers to test dynamic registration
                local test_actor = actor.new(
                    initial_state,
                    {
                        __init = function(state)
                            -- Add a dynamic topic handler in init
                            state.add_handler("dynamic_topic", function(state, payload, topic, from)
                                first_handler_called = true

                                -- Remove the handler after being called
                                state.remove_handler("dynamic_topic")

                                -- Add a new handler for the same topic
                                state.add_handler("dynamic_topic", function(state, payload, topic, from)
                                    second_handler_called = true
                                    return nil
                                end)

                                return nil
                            end)

                            return nil
                        end,

                        -- Default handler to ensure we catch messages with no handler
                        __default = function(state, payload, topic, from)
                            -- This should not be called for our dynamic topic
                            expect(topic).not_to_equal("dynamic_topic",
                                "Default handler should not be called for registered topic")
                            return nil
                        end
                    }
                )

                -- Run the actor
                test_actor.run()

                -- Restore original functions
                _G.channel = original_channel

                -- Verify both handlers were called in sequence
                expect(first_handler_called).to_be_true("First dynamic handler should be called")
                expect(second_handler_called).to_be_true("Second handler should be called after replacing the first")
            end)
        end)

        -- Channel management tests
        describe("Channel Management", function()
            it("should register and unregister channels", function()
                -- Track channel handler calls
                local channel_handler_called = false
                local handler_received_value = nil

                -- Create mock channels
                local inbox_channel = {
                    case_receive = function() return "inbox_case" end
                }

                local events_channel = {
                    case_receive = function() return "events_case" end
                }

                -- Create a mock internal channel
                local internal_channel = {
                    send = function(self, value) return true end,
                    receive = function(self) return nil, false end,
                    case_receive = function(self) return "internal_case" end
                }

                -- Create a test channel with unique ID
                local test_channel = {
                    _id = "test_channel_id", -- For identification
                    send = function(self, value) return true end,
                    receive = function(self) return nil, false end,
                    case_receive = function(self) return "test_case" end
                }

                -- Track if cases are rebuilt
                local cases_count_before = 0
                local cases_count_after_register = 0
                local cases_count_after_unregister = 0

                -- Store original functions
                local original_channel = _G.channel
                local original_tostring = _G.tostring

                -- Mock tostring to identify our test channel
                _G.tostring = function(obj)
                    if obj == test_channel then
                        return "test_channel_id"
                    end
                    return original_tostring(obj)
                end

                -- Set up sequential responses for channel.select
                local select_count = 0
                local select_responses = {
                    -- First return data from test channel to verify registration
                    {
                        ok = true,
                        channel = test_channel,
                        value = "test_data"
                    },
                    -- Then exit
                    { ok = false }
                }

                -- Mock channel with tracking of select cases
                _G.channel = {
                    new = function(size)
                        return internal_channel
                    end,
                    select = function(cases)
                        -- Track the number of cases to verify registration/unregistration
                        if select_count == 0 then
                            -- After registration should include our test channel
                            cases_count_after_register = #cases
                        end

                        select_count = select_count + 1
                        return select_responses[select_count]
                    end
                }

                -- Set up the mock process
                actor._process = {
                    inbox = function() return inbox_channel end,
                    events = function() return events_channel end,
                    send = function(dest, topic, payload) return true end,
                    pid = function() return "test-pid" end,
                    event = {
                        CANCEL = "pid.cancel",
                        EXIT = "pid.exit",
                        LINK_DOWN = "pid.link.down"
                    }
                }

                -- Create the actor with initial state containing test channel
                local initial_state = {
                    value = 0,
                    test_channel = test_channel
                }

                -- Create the actor with channel manipulation
                local test_actor = actor.new(
                    initial_state,
                    {
                        __init = function(state)
                            -- Count baseline cases (inbox, events, internal)
                            cases_count_before = 3

                            -- Register the test channel
                            local register_result = state.register_channel(state.test_channel,
                                function(state, value, ok, channel_name)
                                    channel_handler_called = true
                                    handler_received_value = value
                                    return nil
                                end)

                            expect(register_result).to_be_true("Channel registration should succeed")

                            return nil
                        end
                    }
                )

                -- Run the actor
                test_actor.run()

                -- Restore original functions
                _G.channel = original_channel
                _G.tostring = original_tostring

                -- Verify channel registration worked
                expect(cases_count_after_register).to_equal(cases_count_before + 1,
                    "Select cases should increase after channel registration")

                -- Verify channel handler was called
                expect(channel_handler_called).to_be_true("Channel handler should be called when channel receives data")
                expect(handler_received_value).to_equal("test_data", "Handler should receive correct data")
            end)
        end)

        -- Test actor.next functionality
        describe("Handler Chaining with actor.next", function()
            it("should chain handlers using actor.next", function()
                -- Track handler calls
                local first_handler_called = false
                local second_handler_called = false
                local payload_received_by_second = nil

                -- Create mock message
                local mock_message = {
                    from = function() return "sender_pid" end,
                    topic = function() return "first_topic" end,
                    payload = function()
                        return {
                            data = function()
                                return { value = 42 }
                            end
                        }
                    end
                }

                -- Create mock channels
                local inbox_channel = {
                    case_receive = function() return "inbox_case" end
                }

                local events_channel = {
                    case_receive = function() return "events_case" end
                }

                -- Create a mock internal channel
                local internal_channel = {
                    send = function(self, value) return true end,
                    receive = function(self) return nil, false end,
                    case_receive = function(self) return "internal_case" end
                }

                -- Store original functions
                local original_channel = _G.channel

                -- Counter to limit execution cycles to prevent actual infinite loop in test
                local select_count = 0
                local max_iterations = 5

                -- Mock channel
                _G.channel = {
                    new = function(size)
                        return internal_channel
                    end,
                    select = function(cases)
                        select_count = select_count + 1

                        -- First return the message, then exit after a few iterations
                        -- to avoid hanging if loop detection fails
                        if select_count == 1 then
                            return {
                                ok = true,
                                channel = inbox_channel,
                                value = mock_message
                            }
                        else
                            -- Force exit after a few iterations
                            return { ok = false }
                        end
                    end
                }

                -- Set up the mock process
                actor._process = {
                    inbox = function() return inbox_channel end,
                    events = function() return events_channel end,
                    send = function(dest, topic, payload) return true end,
                    pid = function() return "test-pid" end,
                    event = {
                        CANCEL = "pid.cancel",
                        EXIT = "pid.exit",
                        LINK_DOWN = "pid.link.down"
                    }
                }

                -- Create the actor with handlers that use next
                local test_actor = actor.new(
                    { value = 0 },
                    {
                        first_topic = function(state, payload, topic, from)
                            first_handler_called = true
                            -- Chain to second handler with modified payload
                            return actor.next("second_topic", { value = payload.value * 2 })
                        end,

                        second_topic = function(state, payload, topic, from)
                            second_handler_called = true
                            payload_received_by_second = payload
                            -- Exit after second handler
                            return actor.exit({ status = "completed", value = payload.value })
                        end
                    }
                )

                -- Run the actor
                local result = test_actor.run()

                -- Restore original functions
                _G.channel = original_channel

                -- Verify both handlers were called in sequence
                expect(first_handler_called).to_be_true("First handler should be called")
                expect(second_handler_called).to_be_true("Second handler should be called via next")
                expect(payload_received_by_second.value).to_equal(84, "Payload should be modified by first handler")
                expect(result.status).to_equal("completed", "Actor should exit with correct status")
                expect(result.value).to_equal(84, "Actor should exit with correct value")
            end)

            it("should chain to default handler when specified topic doesn't exist", function()
                -- Track handler calls
                local first_handler_called = false
                local default_handler_called = false
                local received_topic_in_default = nil

                -- Create mock message
                local mock_message = {
                    from = function() return "sender_pid" end,
                    topic = function() return "first_topic" end,
                    payload = function()
                        return {
                            data = function()
                                return { value = 42 }
                            end
                        }
                    end
                }

                -- Create mock channels
                local inbox_channel = {
                    case_receive = function() return "inbox_case" end
                }

                local events_channel = {
                    case_receive = function() return "events_case" end
                }

                -- Create a mock internal channel
                local internal_channel = {
                    send = function(self, value) return true end,
                    receive = function(self) return nil, false end,
                    case_receive = function(self) return "internal_case" end
                }

                -- Store original functions
                local original_channel = _G.channel

                -- Mock channel
                _G.channel = {
                    new = function(size)
                        return internal_channel
                    end,
                    select = function(cases)
                        -- Return message then exit
                        return {
                            ok = true,
                            channel = inbox_channel,
                            value = mock_message
                        }
                    end
                }

                -- Set up the mock process
                actor._process = {
                    inbox = function() return inbox_channel end,
                    events = function() return events_channel end,
                    send = function(dest, topic, payload) return true end,
                    pid = function() return "test-pid" end,
                    event = {
                        CANCEL = "pid.cancel",
                        EXIT = "pid.exit",
                        LINK_DOWN = "pid.link.down"
                    }
                }

                -- Create the actor with next to nonexistent handler
                local test_actor = actor.new(
                    { value = 0 },
                    {
                        first_topic = function(state, payload, topic, from)
                            first_handler_called = true
                            -- Chain to nonexistent topic, should go to default
                            return actor.next("nonexistent_topic")
                        end,

                        __default = function(state, payload, topic, from)
                            default_handler_called = true
                            received_topic_in_default = topic
                            return actor.exit({ status = "handled_by_default" })
                        end
                    }
                )

                -- Run the actor
                local result = test_actor.run()

                -- Restore original functions
                _G.channel = original_channel

                -- Verify default handler was called
                expect(first_handler_called).to_be_true("First handler should be called")
                expect(default_handler_called).to_be_true("Default handler should be called when topic doesn't exist")
                expect(received_topic_in_default).to_equal("nonexistent_topic",
                    "Default handler should get the default topic name")
                expect(result.status).to_equal("handled_by_default", "Actor should exit with correct status")
            end)

            it("should use original payload when next payload is nil", function()
                -- Track received payloads
                local first_handler_called = false
                local second_handler_called = false
                local payload_received_by_second = nil

                -- Create mock message with original payload
                local original_payload = { value = 42, extra = "data" }
                local mock_message = {
                    from = function() return "sender_pid" end,
                    topic = function() return "first_topic" end,
                    payload = function()
                        return {
                            data = function()
                                return original_payload
                            end
                        }
                    end
                }

                -- Create mock channels
                local inbox_channel = {
                    case_receive = function() return "inbox_case" end
                }

                local events_channel = {
                    case_receive = function() return "events_case" end
                }

                -- Create a mock internal channel
                local internal_channel = {
                    send = function(self, value) return true end,
                    receive = function(self) return nil, false end,
                    case_receive = function(self) return "internal_case" end
                }

                -- Store original functions
                local original_channel = _G.channel

                -- Mock channel
                _G.channel = {
                    new = function(size)
                        return internal_channel
                    end,
                    select = function(cases)
                        -- Return message then exit
                        return {
                            ok = true,
                            channel = inbox_channel,
                            value = mock_message
                        }
                    end
                }

                -- Set up the mock process
                actor._process = {
                    inbox = function() return inbox_channel end,
                    events = function() return events_channel end,
                    send = function(dest, topic, payload) return true end,
                    pid = function() return "test-pid" end,
                    event = {
                        CANCEL = "pid.cancel",
                        EXIT = "pid.exit",
                        LINK_DOWN = "pid.link.down"
                    }
                }

                -- Create the actor with next that doesn't specify payload
                local test_actor = actor.new(
                    { value = 0 },
                    {
                        first_topic = function(state, payload, topic, from)
                            first_handler_called = true
                            -- Chain to second handler without modifying payload
                            return actor.next("second_topic")
                        end,

                        second_topic = function(state, payload, topic, from)
                            second_handler_called = true
                            payload_received_by_second = payload
                            -- Exit after second handler
                            return actor.exit({ status = "completed" })
                        end
                    }
                )

                -- Run the actor
                test_actor.run()

                -- Restore original functions
                _G.channel = original_channel

                -- Verify both handlers were called and payload preserved
                expect(first_handler_called).to_be_true("First handler should be called")
                expect(second_handler_called).to_be_true("Second handler should be called via next")
                expect(payload_received_by_second).to_equal(original_payload,
                    "Original payload should be passed to second handler")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
