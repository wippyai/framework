local registry = require("registry")
local json = require("json")
local funcs = require("funcs")
local logger = require("logger"):named("facade.config_contributors")
local theming = require("theming_helpers")
local core = require("config_contributors_core")

local contributors = core.new(registry, json, funcs, theming)

local function warn_skipped(diagnostic: string)
    logger:warn("configuration contribution was skipped", { diagnostic = diagnostic })
end

return {
    compose_requirements = contributors.compose_requirements,
    -- Overrides for the full configuration (resolver, then contributions).
    -- The config endpoint and wippy.facade:host_url both read through this.
    resolve_requirements = function(): table
        return contributors.resolve_requirements(warn_skipped)
    end,
}
