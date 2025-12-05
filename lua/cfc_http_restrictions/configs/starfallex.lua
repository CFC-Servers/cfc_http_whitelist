---@diagnostic disable-next-line: undefined-global
if not file.Exists( "entities/starfall_processor/cl_init.lua", "LUA" ) then return end

AddCSLuaFile()

local config = {
    version = "1",
    addresses = {
        ["thegrb93.github.io"] = { allowed = true },
    }
}


if CLIENT then
    hook.Add( "CanAccessUrl", "StarfallEx", function( url )
        return true
    end )
end
return config
