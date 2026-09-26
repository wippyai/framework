local test = require("test")
local bootloader = require("bootloader")

type BootloaderEntry = {
    id: string,
    kind: string,
    meta: { type: string, order: number?, requires: any? },
}

local function entry(name: string, order: number, requires: {string}?): BootloaderEntry
    return {
        id = "app:" .. name,
        kind = "function.lua",
        meta = { type = "bootloader", order = order, requires = requires },
    }
end

local function statuses(stats)
    local out = {}
    for _, row in ipairs(stats.bootloaders) do
        table.insert(out, row.id .. "=" .. row.status)
    end
    return table.concat(out, ",")
end

local function define_tests()
    describe("bootloader run_chain", function()
        it("runs the given bootloaders in the given order", function()
            local ok, stats = bootloader.run_chain({
                entry("chain_first", 10),
                entry("chain_last", 40),
            }, {}, {})
            test.is_true(ok)
            test.eq(statuses(stats), "app:chain_first=success,app:chain_last=success")
            test.eq(stats.total, 2)
            test.eq(stats.success, 2)
        end)

        it("treats a satisfied prerequisite as completed without running it", function()
            local ok, stats = bootloader.run_chain({
                entry("chain_needs_prior", 20, { "app.fixture:prior" }),
            }, {}, { "app.fixture:prior" })
            test.is_true(ok)
            test.eq(statuses(stats), "app:chain_needs_prior=success")
        end)

        it("fails a bootloader whose prerequisite is neither satisfied nor completed", function()
            local ok, stats = bootloader.run_chain({
                entry("chain_needs_prior", 20, { "app.fixture:prior" }),
            }, {}, {})
            test.is_false(ok)
            test.eq(stats.failed, 1)
            test.contains(stats.bootloaders[1].message, "Missing bootloaders: app.fixture:prior")
        end)

        it("stops at the first failing bootloader and reports its message", function()
            local ok, stats = bootloader.run_chain({
                entry("chain_first", 10),
                entry("chain_fails", 30),
                entry("chain_last", 40),
            }, {}, {})
            test.is_false(ok)
            test.eq(statuses(stats), "app:chain_first=success,app:chain_fails=error")
            test.eq(stats.bootloaders[2].message, "cache warm failed: no such table")
            test.eq(stats.total, 3)
        end)

        it("succeeds running discovered bootloaders", function()
            local ok, stats = bootloader.run()
            test.is_true(ok)
            test.is_table(stats)
        end)

        it("raises an error when a bootloader fails during run()", function()
            bootloader._set_bootloader_registry_for_test({
                find = function()
                    return {
                        entry("chain_first", 10),
                        entry("chain_fails", 20),
                    }
                end
            })
            local ok, err = pcall(bootloader.run)
            bootloader._set_bootloader_registry_for_test(nil)
            test.is_false(ok)
            test.contains(tostring(err), "Bootloader app:chain_fails failed: cache warm failed: no such table")
        end)

        it("raises an error when discovery fails during run()", function()
            bootloader._set_bootloader_registry_for_test({
                find = function()
                    return nil, "mock discovery error"
                end
            })
            local ok, err = pcall(bootloader.run)
            bootloader._set_bootloader_registry_for_test(nil)
            test.is_false(ok)
            test.contains(tostring(err), "Failed to discover bootloaders: mock discovery error")
        end)
    end)
end

return test.run_cases(define_tests)
