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
    local P = {}
    P.id = "urlwhitelist"
    P.name = "URL Whitelist"
    P.settingsoptions = { "Enabled", "Disabled" }
    P.defaultsetting = 1
    P.checks = {
        function() return true end,
        "allow",
    }

    P.settingsoptions[3] = "Disabled for owner"
    P.checks[3] = function() return true end

    hook.Add( "PostGamemodeLoaded", "CFCHTTP_Wrap_SF", function()
        local original = SF.Permissions.includePermissions
        SF.Permissions.includePermissions = function()
            original()
            SF.Permissions.registerProvider( P )
        end
    end )
end

return config
