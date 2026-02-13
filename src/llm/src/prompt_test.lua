local prompt = require("prompt")
local json = require("json")

local function define_tests()
    describe("Prompt Library", function()
        it("should create a basic prompt with system, user, and assistant messages", function()
            local builder = prompt.new()

            builder:add_system("You are a helpful assistant.", nil)
            builder:add_user("Hello, can you help me?", nil)
            builder:add_assistant("Of course! What do you need help with?", nil)

            local messages = builder:get_messages()

            test.eq(#messages, 3, "Expected 3 messages")

            local msg1 = assert(messages[1])
            local msg2 = assert(messages[2])
            local msg3 = assert(messages[3])

            test.eq(msg1.role, "system", "First message should be system")
            test.eq(msg2.role, "user", "Second message should be user")
            test.eq(msg3.role, "assistant", "Third message should be assistant")

            local part1 = assert(msg1.content[1])
            local part2 = assert(msg2.content[1])
            local part3 = assert(msg3.content[1])

            test.eq(part1.text, "You are a helpful assistant.")
            test.eq(part2.text, "Hello, can you help me?")
            test.eq(part3.text, "Of course! What do you need help with?")
        end)

        it("should support developer messages", function()
            local builder = prompt.new()

            builder:add_system("You are a helpful assistant.", nil)
            builder:add_user("How do I fix this code error?", nil)
            builder:add_developer("User is asking about code errors. Provide debugging steps.", nil)
            builder:add_assistant("I'd be happy to help debug your code.", nil)

            local messages = builder:get_messages()
            test.eq(#messages, 4, "Expected 4 messages with developer message")

            local msg1 = assert(messages[1])
            local msg2 = assert(messages[2])
            local msg3 = assert(messages[3])
            local msg4 = assert(messages[4])

            test.eq(msg1.role, "system")
            test.eq(msg2.role, "user")
            test.eq(msg3.role, "developer", "Third message should be developer")

            local part3 = assert(msg3.content[1])
            test.eq(part3.text, "User is asking about code errors. Provide debugging steps.")
            test.eq(msg4.role, "assistant")
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
            test.eq(#messages, 1, "Expected 1 message")

            local msg1 = assert(messages[1])
            test.eq(#msg1.content, 2, "Expected 2 content parts")

            local c1 = assert(msg1.content[1])
            local c2 = assert(msg1.content[2])

            test.eq(c1.type, "text")
            test.eq(c1.text, "What's in this image?")

            test.eq(c2.type, "image")
            test.eq(c2.source.url, "https://example.com/test.jpg")
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
            test.eq(#messages, 2, "Expected 2 messages")

            -- Check function call
            local msg1 = assert(messages[1])
            test.eq(msg1.role, "function_call")
            test.not_nil(msg1.function_call, "Function call should exist")
            local fc = assert(msg1.function_call)
            test.eq(fc.name, "get_weather")
            test.eq(fc.arguments, '{"location":"London","units":"celsius"}')
            test.eq(fc.id, "call_123")

            -- Check function result
            local msg2 = assert(messages[2])
            test.eq(msg2.role, "function_result")
            test.eq(msg2.name, "get_weather")
            local part2 = assert(msg2.content[1])
            test.eq(part2.text, '{"temp":20,"condition":"Sunny"}')
            test.eq(msg2.function_call_id, "call_123")
        end)

        it("should process function results with images", function()
            local builder = prompt.new()

            builder:add_user("Generate a chart showing sales data", nil)

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
            test.eq(#messages, 3, "Expected 3 messages: user, function_result, user_with_images")

            -- Check that function result content is cleaned
            local function_result = assert(messages[2])
            test.eq(function_result.role, "function_result")
            test.eq(function_result.name, "generate_chart")

            -- Parse the cleaned content
            local fr_part = assert(function_result.content[1])
            local cleaned_data, err = json.decode(tostring(fr_part.text))
            test.is_nil(err, "Should parse cleaned JSON without error")
            test.is_nil(cleaned_data._images, "_images should be removed")
            test.contains(cleaned_data.result, "(see image results below)", "Should contain image placeholder")

            -- Check that images are in the new user message (message 3)
            local user_with_images = assert(messages[3])
            test.eq(user_with_images.role, "user")
            test.eq(#user_with_images.content, 2, "User message should have 2 images")

            local uc1 = assert(user_with_images.content[1])
            local uc2 = assert(user_with_images.content[2])
            test.eq(uc1.type, "image")
            test.eq(uc2.type, "image")

            -- Verify image details
            test.eq(uc1.source.url, "https://example.com/chart.jpg")
            test.eq(uc2.source.url, "data:image/png;base64,iVBORw0KGgo...")
        end)

        it("should handle function results with table content containing images", function()
            local builder = prompt.new()

            builder:add_user("Generate a chart", nil)

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
            test.eq(#messages, 3, "Expected 3 messages: user, function_result, user_with_images")

            -- Check that function result content is cleaned (table should be converted to string)
            local function_result = assert(messages[2])
            test.eq(function_result.role, "function_result")
            test.eq(function_result.name, "generate_chart")

            -- Parse the cleaned content
            local fr_part = assert(function_result.content[1])
            local cleaned_data, err = json.decode(tostring(fr_part.text))
            test.is_nil(err, "Should parse cleaned JSON without error")
            test.is_nil(cleaned_data._images, "_images should be removed from table")
            test.contains(cleaned_data.result, "(see image results below)", "Should contain image placeholder")

            -- Check that images are inserted after function result as new user message
            local image_message = assert(messages[3])
            test.eq(image_message.role, "user")
            test.eq(#image_message.content, 1, "Image message should have 1 image")

            local ic1 = assert(image_message.content[1])
            test.eq(ic1.type, "image")
            test.eq(ic1.source.url, "https://example.com/chart.jpg")
        end)

        it("should insert images after tool calling sequence, not at conversation end", function()
            local builder = prompt.new()

            -- Initial conversation
            builder:add_user("Hello", nil)
            builder:add_assistant("Hi there!", nil)

            -- Tool calling sequence
            builder:add_user("Generate a chart", nil)
            builder:add_function_call("generate_chart", '{"type":"sales"}', "call_1")

            local result_with_image = {
                result = "Chart created",
                _images = { { url = "https://example.com/chart.jpg" } }
            }
            builder:add_function_result("generate_chart", result_with_image, "call_1")

            -- Later conversation
            builder:add_assistant("Here's your chart!", nil)
            builder:add_user("Thanks, now generate a report", nil)

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

            test.eq(#messages, 8, "Expected 8 messages")

            -- Verify order: user, assistant, user, function_call, function_result, [NEW USER WITH IMAGES], assistant, user
            local m1 = assert(messages[1])
            local m2 = assert(messages[2])
            local m3 = assert(messages[3])
            local m4 = assert(messages[4])
            local m5 = assert(messages[5])
            local m6 = assert(messages[6])
            local m7 = assert(messages[7])
            local m8 = assert(messages[8])

            test.eq(m1.role, "user")           -- "Hello"
            test.eq(m2.role, "assistant")      -- "Hi there!"
            test.eq(m3.role, "user")           -- "Generate a chart"
            test.eq(m4.role, "function_call")  -- generate_chart call
            test.eq(m5.role, "function_result") -- generate_chart result
            test.eq(m6.role, "user")           -- NEW: images from tool result
            test.eq(m7.role, "assistant")      -- "Here's your chart!"
            test.eq(m8.role, "user")           -- "Thanks, now generate a report"

            -- Verify the image is in the right place (message 6)
            local image_message = m6
            test.eq(#image_message.content, 1)
            local ic1 = assert(image_message.content[1])
            test.eq(ic1.type, "image")
            test.eq(ic1.source.url, "https://example.com/chart.jpg")
        end)

        it("should handle multiple function calls with images in correct sequence", function()
            local builder = prompt.new()

            builder:add_user("Process two tasks", nil)

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

            builder:add_assistant("Both tasks completed!", nil)

            local messages = builder:get_messages()
            test.eq(#messages, 7, "Expected 7 messages")

            -- Verify sequence: user, func_call1, func_result1, func_call2, func_result2, [NEW USER WITH IMAGES], assistant
            local m1 = assert(messages[1])
            local m2 = assert(messages[2])
            local m3 = assert(messages[3])
            local m4 = assert(messages[4])
            local m5 = assert(messages[5])
            local m6 = assert(messages[6])
            local m7 = assert(messages[7])

            test.eq(m1.role, "user")            -- "Process two tasks"
            test.eq(m2.role, "function_call")   -- task1 call
            test.eq(m3.role, "function_result") -- task1 result
            test.eq(m4.role, "function_call")   -- task2 call
            test.eq(m5.role, "function_result") -- task2 result
            test.eq(m6.role, "user")            -- NEW: all images from both results
            test.eq(m7.role, "assistant")       -- "Both tasks completed!"

            -- Verify all images are collected in message 6
            local image_message = m6
            test.eq(#image_message.content, 2, "Should have both images")

            local ic1 = assert(image_message.content[1])
            local ic2 = assert(image_message.content[2])
            test.eq(ic1.type, "image")
            test.eq(ic1.source.url, "https://example.com/analysis.jpg")
            test.eq(ic2.type, "image")
            test.eq(ic2.source.url, "https://example.com/summary.png")
        end)

        it("should handle mixed table and string function results with images", function()
            local builder = prompt.new()

            builder:add_user("Mixed results test", nil)

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
            test.eq(#messages, 4, "Expected 4 messages")

            -- Both function results should be cleaned
            local func1_result = assert(messages[2])
            local f1_part = assert(func1_result.content[1])
            local cleaned1, err1 = json.decode(tostring(f1_part.text))
            test.is_nil(err1, "String result should parse")
            test.is_nil(cleaned1._images, "String result _images should be removed")

            local func2_result = assert(messages[3])
            local f2_part = assert(func2_result.content[1])
            local cleaned2, err2 = json.decode(tostring(f2_part.text))
            test.is_nil(err2, "Table result should parse")
            test.is_nil(cleaned2._images, "Table result _images should be removed")

            -- Images should be collected in final user message
            local image_message = assert(messages[4])
            test.eq(image_message.role, "user")
            test.eq(#image_message.content, 2, "Should have both images")

            local ic1 = assert(image_message.content[1])
            local ic2 = assert(image_message.content[2])
            test.eq(ic1.source.url, "https://example.com/string.jpg")
            test.eq(ic2.source.url, "https://example.com/table.png")
        end)

        it("should handle function results without images normally", function()
            local builder = prompt.new()

            builder:add_user("Get weather info", nil)
            builder:add_function_result("get_weather", '{"temp":25,"sunny":true}', "call_789")

            local messages = builder:get_messages()
            test.eq(#messages, 2, "Expected 2 messages")

            -- User message should be unchanged
            local user_message = assert(messages[1])
            test.eq(#user_message.content, 1, "User message should only have text")
            local uc1 = assert(user_message.content[1])
            test.eq(uc1.text, "Get weather info")

            -- Function result should be unchanged
            local function_result = assert(messages[2])
            local fr1 = assert(function_result.content[1])
            test.eq(fr1.text, '{"temp":25,"sunny":true}')
        end)

        it("should handle invalid JSON in function results gracefully", function()
            local builder = prompt.new()

            builder:add_user("Test invalid JSON", nil)
            builder:add_function_result("test", 'invalid json with "_images" text', "call_bad")

            local messages = builder:get_messages()
            test.eq(#messages, 2, "Expected 2 messages")

            -- Should not crash and should preserve original content
            local function_result = assert(messages[2])
            local fr1 = assert(function_result.content[1])
            test.eq(fr1.text, 'invalid json with "_images" text')

            -- User message should be unchanged
            local user_message = assert(messages[1])
            test.eq(#user_message.content, 1, "User message should only have text")
        end)

        it("should handle empty or malformed _images arrays", function()
            local builder = prompt.new()

            builder:add_user("Test malformed images", nil)

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
            test.eq(#messages, 5, "Expected 5 messages: user + 3 func_results + 1 image_message")

            local image_message = assert(messages[5])
            test.eq(image_message.role, "user")
            test.eq(#image_message.content, 1, "Should have 1 valid image")
            local ic1 = assert(image_message.content[1])
            test.eq(ic1.source.url, "https://valid.jpg")
        end)

        it("should handle multiple clusters of tool calls with images", function()
            local builder = prompt.new()

            builder:add_user("Do multiple task clusters", nil)

            -- First cluster: single tool with image
            builder:add_function_call("task1", '{"action":"analyze"}', "call_1")
            local result1 = {
                result = "Analysis done",
                _images = { { url = "https://example.com/analysis.jpg" } }
            }
            builder:add_function_result("task1", result1, "call_1")
            -- Assistant response breaks the cluster
            builder:add_assistant("Task 1 completed", nil)

            -- Second cluster: two tools, both with images
            builder:add_user("Continue with next tasks", nil)
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
            builder:add_assistant("Moving to final cluster", nil)
            builder:add_user("Final batch of tasks", nil)
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

            builder:add_assistant("All tasks completed!", nil)

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

            test.eq(#messages, 21, "Expected 21 messages with image insertions")

            -- Check first cluster image insertion (after task1)
            local cluster1_images = assert(messages[4])
            test.eq(cluster1_images.role, "user")
            test.eq(#cluster1_images.content, 1, "Cluster 1 should have 1 image")
            local c1i1 = assert(cluster1_images.content[1])
            test.eq(c1i1.source.url, "https://example.com/analysis.jpg")

            -- Check second cluster image insertion (after task2 + task3)
            local cluster2_images = assert(messages[11])
            test.eq(cluster2_images.role, "user")
            test.eq(#cluster2_images.content, 2, "Cluster 2 should have 2 images")
            local c2i1 = assert(cluster2_images.content[1])
            local c2i2 = assert(cluster2_images.content[2])
            test.eq(c2i1.source.url, "https://example.com/process.jpg")
            test.eq(c2i2.source.url, "https://example.com/render.png")

            -- Check third cluster image insertion (after task4 + task5 + task6, but only task4 and task6 have images)
            local cluster3_images = assert(messages[20])
            test.eq(cluster3_images.role, "user")
            test.eq(#cluster3_images.content, 2, "Cluster 3 should have 2 images (task4 + task6)")
            local c3i1 = assert(cluster3_images.content[1])
            local c3i2 = assert(cluster3_images.content[2])
            test.eq(c3i1.source.url, "https://example.com/validate.gif")
            test.eq(c3i2.source.url, "https://example.com/final.webp")
        end)

        it("should add cache markers", function()
            local builder = prompt.new()

            builder:add_system("You are a helpful assistant.", nil)
            builder:add_cache_marker("system_cache")
            builder:add_user("Hello!", nil)

            local messages = builder:get_messages()
            test.eq(#messages, 3, "Expected 3 messages")

            local msg2 = assert(messages[2])
            test.eq(msg2.role, "cache_marker")
            test.eq(msg2.marker_id, "system_cache")
        end)

        it("should clone builders with all message types", function()
            local builder = prompt.new()

            -- Add various message types
            builder:add_system("You are a helpful assistant.", nil)
            builder:add_cache_marker("system_cache")
            builder:add_user("Look at this code", nil)
            builder:add_developer("User is asking about code. Provide code examples.", nil)

            -- Clone the builder
            local cloned: any = builder:clone()
            local original_messages = builder:get_messages()
            local cloned_messages = cloned:get_messages()

            -- Check basic structure
            test.eq(#cloned_messages, #original_messages)

            -- Check that modifying the clone doesn't affect the original
            cloned:add_user("This is a new message", nil)
            test.eq(#cloned:get_messages(), #original_messages + 1)
            test.eq(#builder:get_messages(), #original_messages)
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

            test.eq(#messages, 2)

            local msg1 = assert(messages[1])
            local msg2 = assert(messages[2])
            test.eq(msg1.role, "system")
            test.eq(msg2.role, "user")

            -- Should be able to add more messages
            builder:add_assistant("Hi there!", nil)
            test.eq(#builder:get_messages(), 3)
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
            test.eq(#messages, 1, "Expected 1 message")

            local msg1 = assert(messages[1])
            test.eq(msg1.role, "developer")
            test.eq(#msg1.content, 2, "Expected 2 content parts")

            local c1 = assert(msg1.content[1])
            local c2 = assert(msg1.content[2])
            test.eq(c1.type, "text")
            test.eq(c2.type, "image")
        end)
    end)
end

return require("test").run_cases(define_tests)
