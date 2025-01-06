CFCHTTP.Proxy = CFCHTTP.Proxy or {}
local proxyURL = CreateConVar( "cfc_http_restrictions_proxy_url", "http://localhost:8080", FCVAR_ARCHIVE + FCVAR_PROTECTED, "The URL of the proxy server" )
local proxyAuth = CreateConVar( "cfc_http_restrictions_proxy_auth", "", FCVAR_ARCHIVE + FCVAR_PROTECTED, "The authorization token for the proxy server" )

local proxy = CFCHTTP.Proxy

---@type table<string, {steamID: string, token: string}>
proxy.clients = {}

function proxy:CreateClient( steamID )
    local url = proxyURL:GetString() .. "/clients"

    HTTP {
        url = url,
        method = "POST",
        headers = {
            Authorization = proxyAuth:GetString()
        },
        success = function( code, body, headers )
            if code ~= 200 then
                ErrorNoHalt( "Failed to create client: " .. code )
                return
            end
            local data = util.JSONToTable( body )
            if not data then
                return
            end

            self.clients[steamID] = {
                steamID = steamID,
                token = data.Token
            }
            self:NotifiyClient( steamID )
        end,
        failed = function( err )
            ErrorNoHalt( "Failed to create client: " .. err )
        end,
        body = util.TableToJSON( { clientID = steamID } )
    }
end

util.AddNetworkString( "CFCHTTP_ProxyUpdate" )

function proxy:NotifiyClient( steamID )
    local ply = player.GetBySteamID( steamID )
    if not IsValid( ply ) then
        return
    end

    local clientEntry = self.clients[steamID]
    if not clientEntry then
        return
    end

    net.Start( "CFCHTTP_ProxyUpdate" )
    net.WriteString( proxyURL:GetString() )
    net.WriteString( clientEntry.token )
    net.Send( ply )
end

timer.Create( "CFCHTTP_ProxyUpdate", 30 * 60, 0, function()
    for _, ply in ipairs( player.GetHumans() ) do
        print( "Creating client for " .. ply:Nick() )
        local steamID = ply:SteamID()
        proxy:CreateClient( steamID )
    end
end )

hook.Add( "PlayerInitialSpawn", "CFCHTTP_ProxyUpdate", function( ply )
    timer.Simple( 15, function()
        local steamID = ply:SteamID()
        proxy:CreateClient( steamID )
    end )
end )
