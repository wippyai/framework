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
                    prompt.image("https://example.com/test.jpg")
                }
            )

            local messages = builder:get_messages()
            expect(#messages).to_equal(1, "Expected 1 message")
            expect(#messages[1].content).to_equal(2, "Expected 2 content parts")

            expect(messages[1].content[1].type).to_equal("text")
            expect(messages[1].content[1].text).to_equal("What's in this image?")

            expect(messages[1].content[2].type).to_equal("image")
            expect(messages[1].content[2].source.url).to_equal("https://example.com/test.jpg")
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

        it("should process function results with images", function()
            local builder = prompt.new()

            builder:add_user("Generate a chart showing sales data")

            -- Add function result with images
            local result_with_images = json.encode({
                result = "Chart generated successfully",
                data = { sales = 1000, month = "January" },
                _images = {
                    {
                        url = "https://example.com/chart.jpg"
                    },
                    {
                        url = "data:image/png;base64,iVBORw0KGgo..."
                    }
                }
            })

            builder:add_function_result("generate_chart", result_with_images, "call_456")

            local messages = builder:get_messages()
            expect(#messages).to_equal(3, "Expected 3 messages: user, function_result, user_with_images")

            -- Check that function result content is cleaned
            local function_result = messages[2]
            expect(function_result.role).to_equal("function_result")
            expect(function_result.name).to_equal("generate_chart")

            -- Parse the cleaned content
            local cleaned_data, err = json.decode(function_result.content[1].text)
            expect(err).to_be_nil("Should parse cleaned JSON without error")
            expect(cleaned_data._images).to_be_nil("_images should be removed")
            expect(cleaned_data.result).to_contain("(see image results below)", "Should contain image placeholder")

            -- Check that images are in the new user message (message 3)
            local user_with_images = messages[3]
            expect(user_with_images.role).to_equal("user")
            expect(#user_with_images.content).to_equal(2, "User message should have 2 images")
            expect(user_with_images.content[1].type).to_equal("image")
            expect(user_with_images.content[2].type).to_equal("image")

            -- Verify image details
            expect(user_with_images.content[1].source.url).to_equal("https://example.com/chart.jpg")
            expect(user_with_images.content[2].source.url).to_equal("data:image/png;base64,iVBORw0KGgo...")
        end)

        it("should handle function results with table content containing images", function()
            local builder = prompt.new()

            builder:add_user("Generate a chart")

            -- Add function result with table content (not string)
            local result_table = {
                result = "Chart generated successfully",
                data = { sales = 1000, month = "January" },
                _images = {
                    {
                        url = "https://example.com/chart.jpg"
                    }
                }
            }

            builder:add_function_result("generate_chart", result_table, "call_456")

            local messages = builder:get_messages()
            expect(#messages).to_equal(3, "Expected 3 messages: user, function_result, user_with_images")

            -- Check that function result content is cleaned (table should be converted to string)
            local function_result = messages[2]
            expect(function_result.role).to_equal("function_result")
            expect(function_result.name).to_equal("generate_chart")

            -- Parse the cleaned content
            local cleaned_data, err = json.decode(function_result.content[1].text)
            expect(err).to_be_nil("Should parse cleaned JSON without error")
            expect(cleaned_data._images).to_be_nil("_images should be removed from table")
            expect(cleaned_data.result).to_contain("(see image results below)", "Should contain image placeholder")

            -- Check that images are inserted after function result as new user message
            local image_message = messages[3]
            expect(image_message.role).to_equal("user")
            expect(#image_message.content).to_equal(1, "Image message should have 1 image")
            expect(image_message.content[1].type).to_equal("image")
            expect(image_message.content[1].source.url).to_equal("https://example.com/chart.jpg")
        end)

        it("should insert images after tool calling sequence, not at conversation end", function()
            local builder = prompt.new()

            -- Initial conversation
            builder:add_user("Hello")
            builder:add_assistant("Hi there!")

            -- Tool calling sequence
            builder:add_user("Generate a chart")
            builder:add_function_call("generate_chart", '{"type":"sales"}', "call_1")

            local result_with_image = {
                result = "Chart created",
                _images = { { url = "https://example.com/chart.jpg" } }
            }
            builder:add_function_result("generate_chart", result_with_image, "call_1")

            -- Later conversation
            builder:add_assistant("Here's your chart!")
            builder:add_user("Thanks, now generate a report")

            local messages = builder:get_messages()

            -- Verify the structure with image insertions:
            -- 1: user ("Hello")
            -- 2: assistant ("Hi there!")
            -- 3: user ("Generate a chart")
            -- 4: func_call (generate_chart)
            -- 5: func_result (generate_chart result)
            -- 6: user (images from tool result) <- NEW
            -- 7: assistant ("Here's your chart!")
            -- 8: user ("Thanks, now generate a report")

            expect(#messages).to_equal(8, "Expected 8 messages")

            -- Verify order: user, assistant, user, function_call, function_result, [NEW USER WITH IMAGES], assistant, user
            expect(messages[1].role).to_equal("user")      -- "Hello"
            expect(messages[2].role).to_equal("assistant") -- "Hi there!"
            expect(messages[3].role).to_equal("user")      -- "Generate a chart"
            expect(messages[4].role).to_equal("function_call")   -- generate_chart call
            expect(messages[5].role).to_equal("function_result") -- generate_chart result
            expect(messages[6].role).to_equal("user")      -- NEW: images from tool result
            expect(messages[7].role).to_equal("assistant") -- "Here's your chart!"
            expect(messages[8].role).to_equal("user")      -- "Thanks, now generate a report"

            -- Verify the image is in the right place (message 6)
            local image_message = messages[6]
            expect(#image_message.content).to_equal(1)
            expect(image_message.content[1].type).to_equal("image")
            expect(image_message.content[1].source.url).to_equal("https://example.com/chart.jpg")
        end)

        it("should handle multiple function calls with images in correct sequence", function()
            local builder = prompt.new()

            builder:add_user("Process two tasks")

            -- First function sequence
            builder:add_function_call("task1", '{"action":"analyze"}', "call_1")
            local result1 = {
                result = "Analysis complete",
                _images = { { url = "https://example.com/analysis.jpg" } }
            }
            builder:add_function_result("task1", result1, "call_1")

            -- Second function sequence
            builder:add_function_call("task2", '{"action":"summarize"}', "call_2")
            local result2 = {
                result = "Summary complete",
                _images = { { url = "https://example.com/summary.png" } }
            }
            builder:add_function_result("task2", result2, "call_2")

            builder:add_assistant("Both tasks completed!")

            local messages = builder:get_messages()
            expect(#messages).to_equal(7, "Expected 7 messages")

            -- Verify sequence: user, func_call1, func_result1, func_call2, func_result2, [NEW USER WITH IMAGES], assistant
            expect(messages[1].role).to_equal("user")           -- "Process two tasks"
            expect(messages[2].role).to_equal("function_call")  -- task1 call
            expect(messages[3].role).to_equal("function_result")-- task1 result
            expect(messages[4].role).to_equal("function_call")  -- task2 call
            expect(messages[5].role).to_equal("function_result")-- task2 result
            expect(messages[6].role).to_equal("user")           -- NEW: all images from both results
            expect(messages[7].role).to_equal("assistant")      -- "Both tasks completed!"

            -- Verify all images are collected in message 6
            local image_message = messages[6]
            expect(#image_message.content).to_equal(2, "Should have both images")
            expect(image_message.content[1].type).to_equal("image")
            expect(image_message.content[1].source.url).to_equal("https://example.com/analysis.jpg")
            expect(image_message.content[2].type).to_equal("image")
            expect(image_message.content[2].source.url).to_equal("https://example.com/summary.png")
        end)

        it("should handle mixed table and string function results with images", function()
            local builder = prompt.new()

            builder:add_user("Mixed results test")

            -- String result with images
            local string_result = json.encode({
                result = "String result",
                _images = { { url = "https://example.com/string.jpg" } }
            })
            builder:add_function_result("func1", string_result, "call_1")

            -- Table result with images
            local table_result = {
                result = "Table result",
                _images = { { url = "https://example.com/table.png" } }
            }
            builder:add_function_result("func2", table_result, "call_2")

            local messages = builder:get_messages()
            expect(#messages).to_equal(4, "Expected 4 messages")

            -- Both function results should be cleaned
            local func1_result = messages[2]
            local cleaned1, err1 = json.decode(func1_result.content[1].text)
            expect(err1).to_be_nil("String result should parse")
            expect(cleaned1._images).to_be_nil("String result _images should be removed")

            local func2_result = messages[3]
            local cleaned2, err2 = json.decode(func2_result.content[1].text)
            expect(err2).to_be_nil("Table result should parse")
            expect(cleaned2._images).to_be_nil("Table result _images should be removed")

            -- Images should be collected in final user message
            local image_message = messages[4]
            expect(image_message.role).to_equal("user")
            expect(#image_message.content).to_equal(2, "Should have both images")
            expect(image_message.content[1].source.url).to_equal("https://example.com/string.jpg")
            expect(image_message.content[2].source.url).to_equal("https://example.com/table.png")
        end)

        it("should handle function results without images normally", function()
            local builder = prompt.new()

            builder:add_user("Get weather info")
            builder:add_function_result("get_weather", '{"temp":25,"sunny":true}', "call_789")

            local messages = builder:get_messages()
            expect(#messages).to_equal(2, "Expected 2 messages")

            -- User message should be unchanged
            local user_message = messages[1]
            expect(#user_message.content).to_equal(1, "User message should only have text")
            expect(user_message.content[1].text).to_equal("Get weather info")

            -- Function result should be unchanged
            local function_result = messages[2]
            expect(function_result.content[1].text).to_equal('{"temp":25,"sunny":true}')
        end)

        it("should handle invalid JSON in function results gracefully", function()
            local builder = prompt.new()

            builder:add_user("Test invalid JSON")
            builder:add_function_result("test", 'invalid json with "_images" text', "call_bad")

            local messages = builder:get_messages()
            expect(#messages).to_equal(2, "Expected 2 messages")

            -- Should not crash and should preserve original content
            local function_result = messages[2]
            expect(function_result.content[1].text).to_equal('invalid json with "_images" text')

            -- User message should be unchanged
            local user_message = messages[1]
            expect(#user_message.content).to_equal(1, "User message should only have text")
        end)

        it("should handle empty or malformed _images arrays", function()
            local builder = prompt.new()

            builder:add_user("Test malformed images")

            -- Empty _images array
            local result1 = { result = "No images", _images = {} }
            builder:add_function_result("func1", result1, "call_1")

            -- Malformed _images (not array)
            local result2 = { result = "Bad images", _images = "not an array" }
            builder:add_function_result("func2", result2, "call_2")

            -- _images with invalid entries
            local result3 = {
                result = "Invalid images",
                _images = {
                    { url = "https://valid.jpg" },  -- valid
                    { no_url = "invalid" },         -- invalid - no url
                    "string instead of object"      -- invalid - not object
                }
            }
            builder:add_function_result("func3", result3, "call_3")

            local messages = builder:get_messages()

            -- Should only create image message for result3 with 1 valid image
            expect(#messages).to_equal(5, "Expected 5 messages: user + 3 func_results + 1 image_message")

            local image_message = messages[5]
            expect(image_message.role).to_equal("user")
            expect(#image_message.content).to_equal(1, "Should have 1 valid image")
            expect(image_message.content[1].source.url).to_equal("https://valid.jpg")
        end)

        it("should handle multiple clusters of tool calls with images", function()
            local builder = prompt.new()

            builder:add_user("Do multiple task clusters")

            -- First cluster: single tool with image
            builder:add_function_call("task1", '{"action":"analyze"}', "call_1")
            local result1 = {
                result = "Analysis done",
                _images = { { url = "https://example.com/analysis.jpg" } }
            }
            builder:add_function_result("task1", result1, "call_1")
            -- Assistant response breaks the cluster
            builder:add_assistant("Task 1 completed")

            -- Second cluster: two tools, both with images
            builder:add_user("Continue with next tasks")
            builder:add_function_call("task2", '{"action":"process"}', "call_2")
            local result2 = {
                result = "Processing done",
                _images = { { url = "https://example.com/process.jpg" } }
            }
            builder:add_function_result("task2", result2, "call_2")

            builder:add_function_call("task3", '{"action":"render"}', "call_3")
            local result3 = {
                result = "Rendering done",
                _images = { { url = "https://example.com/render.png" } }
            }
            builder:add_function_result("task3", result3, "call_3")

            -- Third cluster: three tools, only two have images
            builder:add_assistant("Moving to final cluster")
            builder:add_user("Final batch of tasks")
            builder:add_function_call("task4", '{"action":"validate"}', "call_4")
            local result4 = {
                result = "Validation done",
                _images = { { url = "https://example.com/validate.gif" } }
            }
            builder:add_function_result("task4", result4, "call_4")

            builder:add_function_call("task5", '{"action":"optimize"}', "call_5")
            local result5 = { result = "Optimization done" } -- No images
            builder:add_function_result("task5", result5, "call_5")

            builder:add_function_call("task6", '{"action":"finalize"}', "call_6")
            local result6 = {
                result = "Finalization done",
                _images = { { url = "https://example.com/final.webp" } }
            }
            builder:add_function_result("task6", result6, "call_6")

            builder:add_assistant("All tasks completed!")

            local messages = builder:get_messages()

            -- Verify the structure with image insertions:
            -- 1: user ("Do multiple task clusters")
            -- 2: func_call (task1)
            -- 3: func_result (task1)
            -- 4: user (images from task1) <- NEW
            -- 5: assistant ("Task 1 completed")
            -- 6: user ("Continue with next tasks")
            -- 7: func_call (task2)
            -- 8: func_result (task2)
            -- 9: func_call (task3)
            -- 10: func_result (task3)
            -- 11: user (images from task2 + task3) <- NEW
            -- 12: assistant ("Moving to final cluster")
            -- 13: user ("Final batch of tasks")
            -- 14: func_call (task4)
            -- 15: func_result (task4)
            -- 16: func_call (task5)
            -- 17: func_result (task5)
            -- 18: func_call (task6)
            -- 19: func_result (task6)
            -- 20: user (images from task4 + task6, no task5) <- NEW
            -- 21: assistant ("All tasks completed!")

            expect(#messages).to_equal(21, "Expected 21 messages with image insertions")

            -- Check first cluster image insertion (after task1)
            local cluster1_images = messages[4]
            expect(cluster1_images.role).to_equal("user")
            expect(#cluster1_images.content).to_equal(1, "Cluster 1 should have 1 image")
            expect(cluster1_images.content[1].source.url).to_equal("https://example.com/analysis.jpg")

            -- Check second cluster image insertion (after task2 + task3)
            local cluster2_images = messages[11]
            expect(cluster2_images.role).to_equal("user")
            expect(#cluster2_images.content).to_equal(2, "Cluster 2 should have 2 images")
            expect(cluster2_images.content[1].source.url).to_equal("https://example.com/process.jpg")
            expect(cluster2_images.content[2].source.url).to_equal("https://example.com/render.png")

            -- Check third cluster image insertion (after task4 + task5 + task6, but only task4 and task6 have images)
            local cluster3_images = messages[20]
            expect(cluster3_images.role).to_equal("user")
            expect(#cluster3_images.content).to_equal(2, "Cluster 3 should have 2 images (task4 + task6)")
            expect(cluster3_images.content[1].source.url).to_equal("https://example.com/validate.gif")
            expect(cluster3_images.content[2].source.url).to_equal("https://example.com/final.webp")
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

        it("should support developer messages with multi-modal content", function()
            local builder = prompt.new()

            builder:add_message(
                prompt.ROLE.DEVELOPER,
                {
                    prompt.text("Here's a screenshot of the error:"),
                    prompt.image("https://example.com/error.jpg")
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