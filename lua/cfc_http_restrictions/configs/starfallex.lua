---@diagnostic disable-next-line: undefined-global
if not file.Exists( "entities/starfall_processor/cl_init.lua", "LUA" ) then return end

AddCSLuaFile()

local config = {
    version = "1",
    asetURIProtocols = {
        "sf",
    },
    addresses = {
        ["thegrb93.github.io"] = { allowed = true },
        ["cdnjs.cloudflare.com"] = { allowed = true },
    }
}

return config
