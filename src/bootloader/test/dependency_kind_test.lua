local test = require("test")
local bootloader = require("bootloader")

-- Validates registry-based dependency classification. Runs from the test harness
-- (which binds env_storage so the module loads) and injects a mock registry so the
-- classification logic is exercised in isolation.
local function with_registry(entries, fn)
    bootloader._set_registry_for_test({
        get = function(id)
            return entries[id]
        end
    })
    local ok, err = pcall(fn)
    bootloader._set_registry_for_test(nil)
    if not ok then
        error(err)
    end
end

local function define_tests()
    describe("bootloader dependency classification", function()
        it("classifies an entry whose meta.type is bootloader as bootloader", function()
            with_registry({ ["wippy.x:boot"] = { meta = { type = "bootloader" } } }, function()
                test.eq(bootloader._dependency_kind("wippy.x:boot"), "bootloader")
                test.is_false(bootloader._is_service_id("wippy.x:boot"))
            end)
        end)

        it("classifies a dotted-namespace non-bootloader entry as a service", function()
            -- The exact case the namespace heuristic got wrong: an env.variable under
            -- the bootloaders namespace is a service dependency, not a bootloader.
            with_registry({
                ["wippy.bootloader.bootloaders:encryption_key_var"] = { meta = { type = "env.variable" } }
            }, function()
                test.eq(bootloader._dependency_kind("wippy.bootloader.bootloaders:encryption_key_var"), "service")
                test.is_true(bootloader._is_service_id("wippy.bootloader.bootloaders:encryption_key_var"))
            end)
        end)

        it("treats an entry with no meta.type as a service", function()
            with_registry({ ["app:db"] = { meta = {} } }, function()
                test.eq(bootloader._dependency_kind("app:db"), "service")
            end)
        end)

        it("falls back to the namespace heuristic when the entry is missing", function()
            with_registry({}, function()
                test.eq(bootloader._dependency_kind("app:db"), "service")
                test.eq(bootloader._dependency_kind("wippy.session:thing"), "bootloader")
            end)
        end)

        it("treats ids without a colon as bootloader", function()
            with_registry({}, function()
                test.eq(bootloader._dependency_kind("plain_id"), "bootloader")
                test.is_false(bootloader._is_service_id("plain_id"))
            end)
        end)
    end)
end

return test.run_cases(define_tests)
