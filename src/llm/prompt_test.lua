local prompt = require("prompt")
local json = require("json")

local function define_tests()
    describe("Prompt Library", function()
        it("should create a basic prompt with system, user, and assistant messages", function()
            local builder = prompt.new()

            builder:add_system("You are a helpful assistant.")
            builder:add_user("Hello, can you help me?")
            builder:add_assistant("Of course! What do you need help with?")

            local messages = builder:get_messages()

            expect(#messages).to_equal(3, "Expected 3 messages")
            expect(messages[1].role).to_equal("system", "First message should be system")
            expect(messages[2].role).to_equal("user", "Second message should be user")
            expect(messages[3].role).to_equal("assistant", "Third message should be assistant")

            expect(messages[1].content[1].text).to_equal("You are a helpful assistant.")
            expect(messages[2].content[1].text).to_equal("Hello, can you help me?")
            expect(messages[3].content[1].text).to_equal("Of course! What do you need help with?")
        end)

        it("should support developer messages", function()
            local builder = prompt.new()

            builder:add_system("You are a helpful assistant.")
            builder:add_user("How do I fix this code error?")
            builder:add_developer("User is asking about code errors. Provide debugging steps.")
            builder:add_assistant("I'd be happy to help debug your code.")

            local messages = builder:get_messages()
            expect(#messages).to_equal(4, "Expected 4 messages with developer message")
            expect(messages[1].role).to_equal("system")
            expect(messages[2].role).to_equal("user")
            expect(messages[3].role).to_equal("developer", "Third message should be developer")
            expect(messages[3].content[1].text).to_equal("User is asking about code errors. Provide debugging steps.")
            expect(messages[4].role).to_equal("assistant")
        end)

        it("should create multi-modal messages with text and images", function()
            local builder = prompt.new()

            -- Create a user message with text and image content
            builder:add_message(
                prompt.ROLE.USER,
                {
                    prompt.text("What's in this image?"),
                    prompt.image("https://example.com/test.jpg", "A test image")
                }
            )

            local messages = builder:get_messages()
            expect(#messages).to_equal(1, "Expected 1 message")
            expect(#messages[1].content).to_equal(2, "Expected 2 content parts")

            expect(messages[1].content[1].type).to_equal("text")
            expect(messages[1].content[1].text).to_equal("What's in this image?")

            expect(messages[1].content[2].type).to_equal("image")
            expect(messages[1].content[2].source.url).to_equal("https://example.com/test.jpg")
            expect(messages[1].content[2].alt).to_equal("A test image")
        end)

        it("should handle function calls and results", function()
            local builder = prompt.new()

            -- Add function call from assistant
            builder:add_function_call(
                "get_weather",
                '{"location":"London","units":"celsius"}',
                "call_123"
            )

            -- Add function result
            builder:add_function_result(
                "get_weather",
                '{"temp":20,"condition":"Sunny"}',
                "call_123"
            )

            local messages = builder:get_messages()
            expect(#messages).to_equal(2, "Expected 2 messages")

            -- Check function call
            expect(messages[1].role).to_equal("function_call")
            expect(messages[1].function_call).not_to_be_nil("Function call should exist")
            expect(messages[1].function_call.name).to_equal("get_weather")
            expect(messages[1].function_call.arguments).to_equal('{"location":"London","units":"celsius"}')
            expect(messages[1].function_call.id).to_equal("call_123")

            -- Check function result
            expect(messages[2].role).to_equal("function_result")
            expect(messages[2].name).to_equal("get_weather")
            expect(messages[2].content[1].text).to_equal('{"temp":20,"condition":"Sunny"}')
            expect(messages[2].function_call_id).to_equal("call_123")
        end)

        it("should add cache markers", function()
            local builder = prompt.new()

            builder:add_system("You are a helpful assistant.")
            builder:add_cache_marker("system_cache")
            builder:add_user("Hello!")

            local messages = builder:get_messages()
            expect(#messages).to_equal(3, "Expected 3 messages")

            expect(messages[2].role).to_equal("cache_marker")
            expect(messages[2].marker_id).to_equal("system_cache")
        end)

        it("should clone builders with all message types", function()
            local builder = prompt.new()

            -- Add various message types
            builder:add_system("You are a helpful assistant.")
            builder:add_cache_marker("system_cache")
            builder:add_user("Look at this code")
            builder:add_developer("User is asking about code. Provide code examples.")

            -- Clone the builder
            local cloned = builder:clone()
            local original_messages = builder:get_messages()
            local cloned_messages = cloned:get_messages()

            -- Check basic structure
            expect(#cloned_messages).to_equal(#original_messages)

            -- Check that modifying the clone doesn't affect the original
            cloned:add_user("This is a new message")
            expect(#cloned:get_messages()).to_equal(#original_messages + 1)
            expect(#builder:get_messages()).to_equal(#original_messages)
        end)

        it("should calculate prompt size", function()
            local builder = prompt.new()

            builder:add_system("You are a helpful assistant.")
            builder:add_user("Hello!")

            local messages = builder:get_messages()
            local size = prompt.calculate_size(messages)

            expect(size).to_be_type("number")
            expect(size > 0).to_be_true("Size should be greater than zero")

            -- Check that adding more content increases size
            builder:add_assistant("Hi there!")
            local new_messages = builder:get_messages()
            local new_size = prompt.calculate_size(new_messages)

            expect(new_size > size).to_be_true("Size should increase with more content")
        end)

        it("should initialize with existing messages", function()
            local existing_messages = {
                {
                    role = "system",
                    content = {
                        { type = "text", text = "You are a helpful assistant." }
                    }
                },
                {
                    role = "user",
                    content = {
                        { type = "text", text = "Hello!" }
                    }
                }
            }

            local builder = prompt.new(existing_messages)
            local messages = builder:get_messages()

            expect(#messages).to_equal(2)
            expect(messages[1].role).to_equal("system")
            expect(messages[2].role).to_equal("user")

            -- Should be able to add more messages
            builder:add_assistant("Hi there!")
            expect(#builder:get_messages()).to_equal(3)
        end)

        it("should create a prompt with conversation helper", function()
            local system = "You are a helpful assistant."
            local conversation = {
                "What is the capital of France?",
                "The capital of France is Paris."
            }

            local builder = prompt.from_conversation(system, conversation)
            local messages = builder:get_messages()

            expect(#messages).to_equal(3)
            expect(messages[1].role).to_equal("system")
            expect(messages[2].role).to_equal("user")
            expect(messages[3].role).to_equal("assistant")
            expect(messages[2].content[1].text).to_equal("What is the capital of France?")
            expect(messages[3].content[1].text).to_equal("The capital of France is Paris.")
        end)

        it("should support developer messages with multi-modal content", function()
            local builder = prompt.new()

            builder:add_message(
                prompt.ROLE.DEVELOPER,
                {
                    prompt.text("Here's a screenshot of the error:"),
                    prompt.image("https://example.com/error.jpg", "Error screenshot")
                }
            )

            local messages = builder:get_messages()
            expect(#messages).to_equal(1, "Expected 1 message")
            expect(messages[1].role).to_equal("developer")
            expect(#messages[1].content).to_equal(2, "Expected 2 content parts")
            expect(messages[1].content[1].type).to_equal("text")
            expect(messages[1].content[2].type).to_equal("image")
        end)
    end)
end

return require("test").run_cases(define_tests)
