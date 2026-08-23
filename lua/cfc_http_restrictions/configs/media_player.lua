if not file.Exists( "entities/mediaplayer_tv/shared.lua", "LUA" ) then return end

AddCSLuaFile()

local config = {
    version = "1",
    addresses = {
        ["mp.physcannon.top"] = { allowed = true },
        ["mp.purrcoding.com"] = {allowed=true},
    }
}

return config
