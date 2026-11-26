---@class URLData
---@field protocol string
---@field address string
---@field port number|nil
---@field path string


-- Characters allowed in a hostname: ASCII alphanumerics, '.', '-', '_' and any non-ASCII byte (IDNs)
CFCHTTP.HostCharClass = "[%w%.%-_\128-\255]"

-- Deprecated, use CFCHTTP.ParseURL
CFCHTTP.URLPattern = "^(%a[%w%+%.%-]*)://([^/\\%?#]*)(.*)$"

-- Deprecated
CFCHTTP.URLPatternNoGroups = "%a+://[^:/ \t\"]+:?%d*/?[^\n\" \\]*"

-- Matches scheme + full authority (including any userinfo/port) so the whole authority is validated
CFCHTTP.URLPatternNoGroupsNoPath = "%a+://[^/\\%?#;'%(%)%s\"<>`]+"
CFCHTTP.URLPatternNoGroupsHasPath = CFCHTTP.URLPatternNoGroupsNoPath .. "/[^\n\" \\]*"


---@param url string
---@return URLData|nil
function CFCHTTP.ParseURL( url )
    if type( url ) ~= "string" then return end

    -- Browsers strip tabs/newlines anywhere and leading/trailing whitespace/control chars, so do the same
    url = string.gsub( url, "[\t\r\n]", "" )
    url = string.match( url, "^[%c ]*(.-)[%c ]*$" )

    -- Anchored: the URL must start with scheme://, otherwise a later URL in the string could be matched
    local protocol, authority, remainder = string.match( url, CFCHTTP.URLPattern )
    if not protocol then return end

    -- Userinfo (user:pass@host) lets an allowed host be placed before the real host
    if string.find( authority, "@", 1, true ) then return end

    local host, port = string.match( authority, "^([^:]*):?(.*)$" )
    if host == "" then return end
    if not string.match( port, "^%d*$" ) then return end
    if string.find( host, "[^%w%.%-_\128-\255]" ) then return end

    return {
        protocol = string.lower( protocol ),
        address = string.lower( host ),
        port = tonumber( port ),
        path = remainder
    }
end

---@param text string
---@return string[]
function CFCHTTP.FindURLs( text )
    local pattern = CFCHTTP.URLPatternNoGroups

    local urls = {}
    for url in string.gmatch( text, pattern ) do
        table.insert( urls, url )
    end

    return urls
end

---@param url string
---@return string
function CFCHTTP.URLEncode( url )
    url = url:gsub( "[^%w ]", function( c )
        return string.format( "%%%02X", string.byte( c ) )
    end )
    return url
end

function CFCHTTP.GetRedirectURL( url )
    url = string.Replace( url, "\n", "" )
    url = string.Trim( url )
    local b64 = CFCHTTP.URLEncode( url )

    return "https://gmhttp.pages.dev/redirect?url=" .. b64
end

---@param text string
---@param f fun( url:string ):string
---@return string
function CFCHTTP.ReplaceURLs( text, f )
    local html = string.gsub( text, CFCHTTP.URLPatternNoGroupsNoPath, f )
    html = string.gsub( html, CFCHTTP.URLPatternNoGroupsHasPath, f )
    return html
end

---@param url string
---@return string|nil
function CFCHTTP.GetAddress( url )
    if not url then return end
    local data = CFCHTTP.ParseURL( url )
    if not data then return end

    return data.address
end

function CFCHTTP.IsAssetURI( url )
    local assetURIProtocols = CFCHTTP.config.assetURIProtocols

    for _, protocol in pairs( assetURIProtocols ) do
        if string.StartsWith( url, protocol .. "://" ) then
            return true
        end
    end
    return false
end
