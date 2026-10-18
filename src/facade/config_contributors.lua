local registry = require("registry")
local json = require("json")
local funcs = require("funcs")
local theming = require("theming_helpers")
local core = require("config_contributors_core")

return core.new(registry, json, funcs, theming)
