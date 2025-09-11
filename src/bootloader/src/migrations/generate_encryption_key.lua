local env = require("env")
local crypto = require("crypto")
local logger = require("logger")

local log = logger:named("encryption_key_migration")

-- Convert binary data to hex format
local function binary_to_hex(data)
    local hex = {}
    for i = 1, #data do
        local byte = string.byte(data, i)
        hex[i] = string.format("%02x", byte)
    end
    return table.concat(hex)
end

-- Generate a cryptographically secure 256-bit encryption key
local function generate_encryption_key()
    log:info("Generating new 256-bit encryption key")
    
    local random_bytes, err = crypto.random.bytes(32)
    if err then
        log:error("Failed to generate random bytes", { error = err })
        return nil, "Failed to generate random bytes: " .. err
    end
    
    local hex_key = binary_to_hex(random_bytes)
    log:info("Generated encryption key", { length = #hex_key })
    
    return hex_key
end

-- Main migration function
local function migration(options)
    log:info("Starting ENCRYPTION_KEY migration")
    
    -- Check if ENCRYPTION_KEY already exists
    local existing_key = env.get("ENCRYPTION_KEY")
    if existing_key and existing_key ~= "" then
        log:info("ENCRYPTION_KEY already exists, skipping generation")
        return {
            status = "skipped",
            reason = "ENCRYPTION_KEY already exists",
            name = "Generate ENCRYPTION_KEY"
        }
    end
    
    log:info("ENCRYPTION_KEY not found, generating new key")
    
    -- Generate new encryption key
    local new_key, err = generate_encryption_key()
    if err then
        log:error("Failed to generate encryption key", { error = err })
        return {
            status = "error",
            error = err,
            name = "Generate ENCRYPTION_KEY"
        }
    end
    
    -- Validate key format (should be 64 hex characters)
    if #new_key ~= 64 then
        local format_err = "Generated key has invalid length: " .. #new_key .. " (expected 64)"
        log:error("Key validation failed", { error = format_err, length = #new_key })
        return {
            status = "error",
            error = format_err,
            name = "Generate ENCRYPTION_KEY"
        }
    end
    
    -- Persist the key using env.set()
    local set_success, set_err = env.set("ENCRYPTION_KEY", new_key)
    if set_err then
        log:error("Failed to persist encryption key", { error = set_err })
        return {
            status = "error",
            error = "Failed to persist encryption key: " .. set_err,
            name = "Generate ENCRYPTION_KEY"
        }
    end
    
    log:info("Successfully generated and persisted ENCRYPTION_KEY")
    
    return {
        status = "applied",
        description = "Generated and persisted ENCRYPTION_KEY",
        name = "Generate ENCRYPTION_KEY"
    }
end

return { migration = migration }