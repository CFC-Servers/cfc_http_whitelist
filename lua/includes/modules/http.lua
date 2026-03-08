AddCSLuaFile()

if SERVER then
    local expectedHash = "0cd6bc47b235a6c98af53c41e575f06fbb00a1bd399f49ddcfd15f139f9a4def"

    -- file.Read is not available yet
    local originalFile = file.Open( "garrysmod/lua/includes/modules/http.lua", "r", "BASE_PATH" )
    local code = originalFile:Read( originalFile:Size() )
    originalFile:Close()
    local hash = util.SHA256( code )
    if hash ~= expectedHash then
        ErrorNoHaltWithStack( "[CFC HTTP Restrictions] Warning: The http.lua module has been modified! Expected hash: " .. expectedHash .. ", got: " .. hash .. "\n" )
    end
end


if SERVER then
    local svEnabled = CreateConVar( "cfc_http_restrictions_sv_enabled", "0", FCVAR_ARCHIVE, "Enable server-side HTTP whitelisting", 0, 1 )
    if svEnabled:GetBool() then
        ProtectedCall( include, "cfc_http_restrictions/wraps/http.lua" )
    end
end

if CLIENT then
    ProtectedCall( include, "cfc_http_restrictions/wraps/http.lua" )
    ProtectedCall( include, "cfc_http_restrictions/wraps/playURL.lua" )
end

AddCSLuaFile( "includes/modules/original_http.lua" )
require( "original_http" )
