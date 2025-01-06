local enableProxy = CreateConVar( "cfc_http_experimental_enable_proxy", "1", FCVAR_ARCHIVE, "Enable the HTTP proxy", 0, 1 )

local proxy = CFCHTTP.Proxy or {}
CFCHTTP.Proxy = proxy

net.Receive( "CFCHTTP_ProxyUpdate", function( _, ply )
    local proxyURL = net.ReadString()
    local token = net.ReadString()
    proxy.url = proxyURL
    proxy.token = token

    proxy:CheckHealth()
end )

---@param url string
---@param opts {trusted: boolean, audio: boolean}
function proxy:WrapURL( url, opts )
    local opts = {
        audio = opts.audio and "true" or "false",
        url = CFCHTTP.URLEncode( url ),
        trusted = opts.trusted and "true" or "false",
        token = self.token
    }

    url = self.url .. "/proxy?"
    for k, v in pairs( opts ) do
        url = url .. k .. "=" .. v .. "&"
    end

    return url
end

if proxy.health == nil then
    proxy.health = false
end

function proxy:IsHealthy()
    if not enableProxy:GetBool() then return false end

    return self.url and self.token and self.healthy
end

function proxy:CheckHealth()
    if not self.url or not self.token then
        self.healthy = false
        return
    end

    local url = self.url .. "/health"
    _HTTP {
        url = url,
        method = "GET",
        headers = {
            Authorization = self.token
        },
        success = function( code )
            self.healthy = code == 200
        end,
        failed = function( err )
            print( "Failed to check health: " .. err )
            self.healthy = false
        end
    }
end

timer.Create( "CFCHTTP_ProxyHealth", 60, 0, function()
    proxy:CheckHealth()
end )

hook.Add( "InitPostEntity", "CFCHTTP_ProxyHealth", function()
    timer.Simple( 10, function()
        proxy:CheckHealth()
    end )
end )
