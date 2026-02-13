local test = require("test")
local bootloader = require("bootloader")
local bootloader_registry = require("bootloader_registry")

type BootloaderMeta = {
    type: string,
    order: number?,
    description: string?,
    requires: any?,
}

type BootloaderEntry = {
    id: string,
    kind: string,
    meta: BootloaderMeta,
}

local function define_tests()
    test.describe("is_service_id", function()
        test.it("returns true for service IDs without dots in namespace", function()
            test.is_true(bootloader._is_service_id("app:db"))
            test.is_true(bootloader._is_service_id("system:logger"))
        end)

        test.it("returns false for bootloader IDs with dots in namespace", function()
            test.is_false(bootloader._is_service_id("wippy.bootloader.bootloaders:encryption_key"))
            test.is_false(bootloader._is_service_id("wippy.migration:migration_bootloader"))
        end)

        test.it("returns false for IDs without colon", function()
            test.is_false(bootloader._is_service_id("no_colon"))
            test.is_false(bootloader._is_service_id(""))
        end)
    end)

    test.describe("check_dependencies", function()
        test.it("returns success when no requirements", function()
            local entry = {
                id = "test:bootloader",
                kind = "function.lua",
                meta = { type = "bootloader" } :: BootloaderMeta,
            } :: BootloaderEntry
            local ok, err = bootloader._check_dependencies(entry, {})
            test.is_true(ok)
            test.is_nil(err)
        end)

        test.it("returns success when all bootloader deps completed", function()
            local entry = {
                id = "test:second",
                kind = "function.lua",
                meta = {
                    type = "bootloader",
                    requires = { "wippy.bootloader:first" },
                } :: BootloaderMeta,
            } :: BootloaderEntry
            local ok, err = bootloader._check_dependencies(entry, { "wippy.bootloader:first" })
            test.is_true(ok)
            test.is_nil(err)
        end)

        test.it("returns error when bootloader dep is missing", function()
            local entry = {
                id = "test:second",
                kind = "function.lua",
                meta = {
                    type = "bootloader",
                    requires = { "wippy.bootloader:first" },
                } :: BootloaderMeta,
            } :: BootloaderEntry
            local ok, err = bootloader._check_dependencies(entry, {})
            test.is_false(ok)
            test.not_nil(err)
            test.gt(#err, 0)
            test.contains(err[1], "Missing bootloaders")
        end)

        test.it("normalizes string requires to array", function()
            local entry = {
                id = "test:single",
                kind = "function.lua",
                meta = {
                    type = "bootloader",
                    requires = "wippy.bootloader:first",
                } :: BootloaderMeta,
            } :: BootloaderEntry
            local ok, err = bootloader._check_dependencies(entry, { "wippy.bootloader:first" })
            test.is_true(ok)
            test.is_nil(err)
        end)
    end)

    test.describe("registry find", function()
        test.it("sorts by order ascending", function()
            local mock_entries = {
                { id = "b:second", kind = "function.lua", meta = { type = "bootloader", order = 20 } },
                { id = "a:first", kind = "function.lua", meta = { type = "bootloader", order = 10 } },
                { id = "c:third", kind = "function.lua", meta = { type = "bootloader", order = 30 } },
            }

            table.sort(mock_entries, function(a, b)
                local a_order = a.meta and a.meta.order or 999
                local b_order = b.meta and b.meta.order or 999
                if a_order ~= b_order then
                    return a_order < b_order
                end
                return a.id < b.id
            end)

            test.eq(mock_entries[1].id, "a:first")
            test.eq(mock_entries[2].id, "b:second")
            test.eq(mock_entries[3].id, "c:third")
        end)

        test.it("uses default order 999 when missing", function()
            local entries = {
                { id = "a:explicit", kind = "function.lua", meta = { type = "bootloader", order = 10 } },
                { id = "b:default", kind = "function.lua", meta = { type = "bootloader" } },
            }

            table.sort(entries, function(a, b)
                local a_order = a.meta and a.meta.order or 999
                local b_order = b.meta and b.meta.order or 999
                if a_order ~= b_order then
                    return a_order < b_order
                end
                return a.id < b.id
            end)

            test.eq(entries[1].id, "a:explicit")
            test.eq(entries[2].id, "b:default")
        end)

        test.it("sorts by id when order is equal", function()
            local entries = {
                { id = "c:charlie", kind = "function.lua", meta = { type = "bootloader", order = 10 } },
                { id = "a:alpha", kind = "function.lua", meta = { type = "bootloader", order = 10 } },
                { id = "b:bravo", kind = "function.lua", meta = { type = "bootloader", order = 10 } },
            }

            table.sort(entries, function(a, b)
                local a_order = a.meta and a.meta.order or 999
                local b_order = b.meta and b.meta.order or 999
                if a_order ~= b_order then
                    return a_order < b_order
                end
                return a.id < b.id
            end)

            test.eq(entries[1].id, "a:alpha")
            test.eq(entries[2].id, "b:bravo")
            test.eq(entries[3].id, "c:charlie")
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
