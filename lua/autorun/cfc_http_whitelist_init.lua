AddCSLuaFile()

local function includeClient( f )
    if SERVER then
        AddCSLuaFile( f )
    else
        include( f )
    end
end

local function includeShared( f )
    AddCSLuaFile( f )
    include( f )
end
include( "cfc_http_restrictions/config_loader.lua" )
<<<<<<< HEAD
includeShared( "cfc_http_restrictions/shared/filetypes.lua" )
includeShared( "cfc_http_restrictions/config_loader.lua" )
includeShared( "cfc_http_restrictions/shared/list_manager.lua" )
=======
includeShared( "cfc_http_restrictions/client/filetypes.lua" )
includeClient( "cfc_http_restrictions/config_loader.lua" )
includeClient( "cfc_http_restrictions/client/list_manager.lua" )
>>>>>>> main
includeClient( "cfc_http_restrictions/client/list_view.lua" )
includeClient( "cfc_http_restrictions/client/wrap_functions.lua" )
