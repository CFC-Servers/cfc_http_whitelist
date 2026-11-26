-- Table driven tests for URL parsing and whitelist matching against the default config.
-- Each row becomes its own test case so a failure names the exact URL that misbehaved.
--
-- urlCases rows:
--   url             - the input passed to CFCHTTP.GetAddress / CFCHTTP.GetOptionsForURL
--   expectedAddress - the expected CFCHTTP.GetAddress result (nil means the URL must not parse)
--   expectedAllowed - whether CFCHTTP.GetOptionsForURL must report the URL as allowed
--   note            - optional description of why the row exists

local urlCases = {
    -- Exact entries
    { url = "https://google.com", expectedAddress = "google.com", expectedAllowed = true },
    { url = "https://google.com/", expectedAddress = "google.com", expectedAllowed = true },
    { url = "http://google.com/search?q=gmod", expectedAddress = "google.com", expectedAllowed = true },
    { url = "https://www.google.com/", expectedAddress = "www.google.com", expectedAllowed = true },
    { url = "https://i.imgur.com/abc.png", expectedAddress = "i.imgur.com", expectedAllowed = true },
    { url = "https://raw.githubusercontent.com/owner/repo/main/file.lua", expectedAddress = "raw.githubusercontent.com", expectedAllowed = true },
    { url = "https://gmhttp.pages.dev/redirect?url=x", expectedAddress = "gmhttp.pages.dev", expectedAllowed = true },
    { url = "https://files.catbox.moe/abc.mp3", expectedAddress = "files.catbox.moe", expectedAllowed = true },
    { url = "https://youtu.be/dQw4w9WgXcQ", expectedAddress = "youtu.be", expectedAllowed = true },

    -- Ports, queries, fragments and empty paths
    { url = "https://google.com:443/x", expectedAddress = "google.com", expectedAllowed = true },
    { url = "http://google.com:80", expectedAddress = "google.com", expectedAllowed = true },
    { url = "https://google.com:/x", expectedAddress = "google.com", expectedAllowed = true, note = "empty port" },
    { url = "https://google.com?q=1", expectedAddress = "google.com", expectedAllowed = true },
    { url = "https://google.com#frag", expectedAddress = "google.com", expectedAllowed = true },
    { url = "https://google.com/a/b/../c?x=1&y=2#z", expectedAddress = "google.com", expectedAllowed = true },
    { url = "https://google.com:abc/", expectedAddress = nil, expectedAllowed = false, note = "non-numeric port" },
    { url = "https://google.com:443:80/", expectedAddress = nil, expectedAllowed = false, note = "two ports" },

    -- Case insensitivity
    { url = "HTTPS://GOOGLE.COM/", expectedAddress = "google.com", expectedAllowed = true },
    { url = "https://Google.Com/Path/Keeps/Case", expectedAddress = "google.com", expectedAllowed = true },
    { url = "https://CDN.DiscordApp.com/a.png", expectedAddress = "cdn.discordapp.com", expectedAllowed = true },
    { url = "https://A.STEAMSTATIC.COM/x", expectedAddress = "a.steamstatic.com", expectedAllowed = true },

    -- Wildcard entries
    { url = "https://cdn.steamstatic.com/x.jpg", expectedAddress = "cdn.steamstatic.com", expectedAllowed = true },
    { url = "https://a.b.steamstatic.com/x", expectedAddress = "a.b.steamstatic.com", expectedAllowed = true },
    { url = "https://lh3.googleusercontent.com/x", expectedAddress = "lh3.googleusercontent.com", expectedAllowed = true },
    { url = "https://forum.facepunch.com/", expectedAddress = "forum.facepunch.com", expectedAllowed = true },
    { url = "https://steamstatic.com/", expectedAddress = "steamstatic.com", expectedAllowed = false, note = "wildcard needs a subdomain" },
    { url = "https://evilsteamstatic.com/", expectedAddress = "evilsteamstatic.com", expectedAllowed = false },
    { url = "https://steamstatic.com.evil.com/", expectedAddress = "steamstatic.com.evil.com", expectedAllowed = false },
    { url = "https://a.steamstatic.com.evil.com/", expectedAddress = "a.steamstatic.com.evil.com", expectedAllowed = false },

    -- Pattern entries
    { url = "https://cdn.discordapp.com/attachments/1/2/a.png", expectedAddress = "cdn.discordapp.com", expectedAllowed = true },
    { url = "https://cdn1.discordapp.com/a.png", expectedAddress = "cdn1.discordapp.com", expectedAllowed = true },
    { url = "https://cdn-eu_2.discordapp.com/a.png", expectedAddress = "cdn-eu_2.discordapp.com", expectedAllowed = true },
    { url = "https://cdnxdiscordapp.com/a.png", expectedAddress = "cdnxdiscordapp.com", expectedAllowed = false, note = "dot is literal" },
    { url = "https://cdn.discordapp.com.evil.com/", expectedAddress = "cdn.discordapp.com.evil.com", expectedAllowed = false },
    { url = "https://xcdn.discordapp.com/", expectedAddress = "xcdn.discordapp.com", expectedAllowed = false, note = "pattern is anchored" },
    { url = "https://images-ext-1.discordapp.net/x", expectedAddress = "images-ext-1.discordapp.net", expectedAllowed = true },
    { url = "https://imagesx.discordapp.net/x", expectedAddress = "imagesx.discordapp.net", expectedAllowed = false, note = "dash is literal" },
    { url = "https://imagex.discordapp.net/x", expectedAddress = "imagex.discordapp.net", expectedAllowed = false, note = "dash is not a lazy quantifier" },
    { url = "https://images-.discordapp.net/x", expectedAddress = "images-.discordapp.net", expectedAllowed = false },
    { url = "https://media.discordapp.net/x.png", expectedAddress = "media.discordapp.net", expectedAllowed = true },
    { url = "https://foo.keybase.pub/", expectedAddress = "foo.keybase.pub", expectedAllowed = true },
    { url = "https://foo-bar.keybase.pub/", expectedAddress = "foo-bar.keybase.pub", expectedAllowed = true },
    { url = "https://abc.keybasexpub/", expectedAddress = "abc.keybasexpub", expectedAllowed = false },
    { url = "https://keybase.pub/", expectedAddress = "keybase.pub", expectedAllowed = false },

    -- Hosts that are not whitelisted
    { url = "https://evil.com/", expectedAddress = "evil.com", expectedAllowed = false },
    { url = "https://maps.google.com/", expectedAddress = "maps.google.com", expectedAllowed = false, note = "no wildcard for google.com" },
    { url = "https://google.co/", expectedAddress = "google.co", expectedAllowed = false },
    { url = "https://googlexcom/", expectedAddress = "googlexcom", expectedAllowed = false, note = "dot in exact entry is literal" },
    { url = "https://google.com.evil.com/", expectedAddress = "google.com.evil.com", expectedAllowed = false },
    { url = "https://evil-google.com/", expectedAddress = "evil-google.com", expectedAllowed = false },
    { url = "https://google.com./", expectedAddress = "google.com.", expectedAllowed = false, note = "trailing dot fails closed" },
    { url = "https://ievil.tinypic.com/", expectedAddress = "ievil.tinypic.com", expectedAllowed = false, note = "tinypic removed" },

    -- IP addresses and IDNs
    { url = "http://127.0.0.1/", expectedAddress = "127.0.0.1", expectedAllowed = false },
    { url = "http://192.168.1.1:8080/admin", expectedAddress = "192.168.1.1", expectedAllowed = false },
    { url = "https://24.321.483.222", expectedAddress = "24.321.483.222", expectedAllowed = false },
    { url = "http://[::1]/", expectedAddress = nil, expectedAllowed = false, note = "IPv6 literals fail closed" },
    { url = "http://лиса.рф/static/img/test.png", expectedAddress = "лиса.рф", expectedAllowed = false },

    -- Userinfo can put an allowed host in front of the real host
    { url = "http://google.com@evil.com/", expectedAddress = nil, expectedAllowed = false },
    { url = "http://google.com:@evil.com/", expectedAddress = nil, expectedAllowed = false },
    { url = "http://google.com:80@evil.com/x", expectedAddress = nil, expectedAllowed = false },
    { url = "https://i.imgur.com:443@evil.com/a.png", expectedAddress = nil, expectedAllowed = false },
    { url = "https://user:pass@google.com/", expectedAddress = nil, expectedAllowed = false, note = "userinfo is always rejected" },
    { url = "https://@google.com/", expectedAddress = nil, expectedAllowed = false },
    { url = "https://google.com\\@evil.com/", expectedAddress = nil, expectedAllowed = false, note = "Steam HTTP sends this to evil.com" },
    { url = "https://google.com\\:@evil.com/", expectedAddress = nil, expectedAllowed = false, note = "Steam HTTP sends this to evil.com" },
    { url = "https://google.com\\x@evil.com/a.png", expectedAddress = nil, expectedAllowed = false },
    { url = "https://google.com\\a\\b@evil.com/", expectedAddress = nil, expectedAllowed = false },
    { url = "https://google.com:443\\@evil.com/", expectedAddress = nil, expectedAllowed = false },

    -- Delimiters that end the host in a browser must end it here too
    { url = "http://evil.com?.steamstatic.com/", expectedAddress = "evil.com", expectedAllowed = false },
    { url = "http://evil.com#.googleusercontent.com/", expectedAddress = "evil.com", expectedAllowed = false },
    { url = "http://evil.com\\.facepunch.com/", expectedAddress = "evil.com", expectedAllowed = false },
    { url = "http://evil.com/.steamstatic.com", expectedAddress = "evil.com", expectedAllowed = false },
    { url = "http://evil.com?@google.com", expectedAddress = "evil.com", expectedAllowed = false },
    { url = "http://evil.com#@google.com", expectedAddress = "evil.com", expectedAllowed = false },
    { url = "http://evil.com/@google.com", expectedAddress = "evil.com", expectedAllowed = false },
    { url = "https://google.com?@evil.com", expectedAddress = "google.com", expectedAllowed = true, note = "@ after the host is just query" },
    { url = "https://google.com/@evil.com", expectedAddress = "google.com", expectedAllowed = true, note = "@ after the host is just path" },

    -- Characters that are not valid in a host
    { url = "http://evil.com;.steamstatic.com/", expectedAddress = nil, expectedAllowed = false },
    { url = "http://evil.com%2f.facepunch.com/", expectedAddress = nil, expectedAllowed = false },
    { url = "http://evil.com%2e.steamstatic.com/", expectedAddress = nil, expectedAllowed = false },
    { url = "http://evil .steamstatic.com/", expectedAddress = nil, expectedAllowed = false },
    { url = "http://evil.com\".steamstatic.com/", expectedAddress = nil, expectedAllowed = false },
    { url = "http://evil.com<.steamstatic.com/", expectedAddress = nil, expectedAllowed = false },
    { url = "http://evil.com\0.steamstatic.com/", expectedAddress = nil, expectedAllowed = false },

    -- Malformed scheme separators
    { url = "http:/evil.com/?https://google.com", expectedAddress = nil, expectedAllowed = false },
    { url = "http:\\\\evil.com/?https://google.com", expectedAddress = nil, expectedAllowed = false },
    { url = "http:evil.com/?u=https://google.com", expectedAddress = nil, expectedAllowed = false },
    { url = "//google.com/", expectedAddress = nil, expectedAllowed = false, note = "protocol relative" },
    { url = "google.com", expectedAddress = nil, expectedAllowed = false, note = "no scheme" },
    { url = "://google.com", expectedAddress = nil, expectedAllowed = false },
    { url = "https://", expectedAddress = nil, expectedAllowed = false },
    { url = "https:///google.com", expectedAddress = nil, expectedAllowed = false, note = "empty authority" },
    { url = "evil https://google.com", expectedAddress = nil, expectedAllowed = false, note = "URL must be at the start" },
    { url = "x" .. "https://google.com", expectedAddress = "google.com", expectedAllowed = true, note = "xhttps is a valid scheme" },

    -- Other schemes
    { url = "ftp://google.com/file", expectedAddress = "google.com", expectedAllowed = true },
    { url = "ws://google.com/socket", expectedAddress = "google.com", expectedAllowed = true },
    { url = "git+ssh://github.com/x", expectedAddress = "github.com", expectedAllowed = true },
    { url = "file:///etc/passwd", expectedAddress = nil, expectedAllowed = false },
    { url = "javascript:alert(1)", expectedAddress = nil, expectedAllowed = false },
    { url = "data:text/html,<script>alert(1)</script>", expectedAddress = nil, expectedAllowed = false },
    { url = "about:blank", expectedAddress = nil, expectedAllowed = false },

    -- Whitespace and control characters are stripped like a browser does
    { url = "  https://google.com/ ", expectedAddress = "google.com", expectedAllowed = true },
    { url = "\thttps://google.com/\n", expectedAddress = "google.com", expectedAllowed = true },
    { url = "https://goo\tgle.com/", expectedAddress = "google.com", expectedAllowed = true },
    { url = "https://goo\ngle.com/", expectedAddress = "google.com", expectedAllowed = true },
    { url = "https://evil\r\n.com/", expectedAddress = "evil.com", expectedAllowed = false },
    { url = "https://google.com\t@evil.com/", expectedAddress = nil, expectedAllowed = false },
    { url = "\1\2https://google.com", expectedAddress = "google.com", expectedAllowed = true },

    -- Non URL input
    { url = "", expectedAddress = nil, expectedAllowed = false },
    { url = "nil", expectedAddress = nil, expectedAllowed = false },
    { url = "   ", expectedAddress = nil, expectedAllowed = false },
}

-- Asset URIs are allowed by protocol rather than by host
local assetCases = {
    { url = "asset://garrysmod/materials/icon16/user.png", expectedAllowed = true },
    { url = "asset://anything/at/all", expectedAllowed = true },
}

-- replaceCases rows: html is passed through CFCHTTP.ReplaceURLs, replacing every non-allowed URL with BLOCKED
local replaceCases = {
    {
        name = "keeps an allowed URL",
        html = [[<img src="https://i.imgur.com/a.png">]],
        expectedHtml = [[<img src="https://i.imgur.com/a.png">]],
    },
    {
        name = "keeps an allowed URL with a port and query",
        html = [[<img src="https://google.com:443/x?y=1">]],
        expectedHtml = [[<img src="https://google.com:443/x?y=1">]],
    },
    {
        name = "replaces a blocked host",
        html = [[<img src="https://evil.com/a.png">]],
        expectedHtml = [[<img src="BLOCKED/a.png">]],
    },
    {
        name = "replaces a userinfo URL as a whole",
        html = [[<img src="http://google.com:@evil.com/a.png">]],
        expectedHtml = [[<img src="BLOCKED/a.png">]],
    },
    {
        name = "replaces a userinfo URL with a port",
        html = [[<img src="http://google.com:80@evil.com/a.png">]],
        expectedHtml = [[<img src="BLOCKED/a.png">]],
    },
    {
        name = "replaces a query smuggled wildcard URL",
        html = [[<img src="http://evil.com?.steamstatic.com/a.png">]],
        expectedHtml = [[<img src="BLOCKED?.steamstatic.com/a.png">]],
    },
    {
        name = "replaces a fragment smuggled wildcard URL",
        html = [[<img src="http://evil.com#.steamstatic.com/a.png">]],
        expectedHtml = [[<img src="BLOCKED#.steamstatic.com/a.png">]],
    },
    {
        name = "replaces a lookalike suffix host",
        html = [[<img src="https://google.com.evil.com/a.png">]],
        expectedHtml = [[<img src="BLOCKED/a.png">]],
    },
    {
        name = "handles single quoted attributes",
        html = [[<img src='https://evil.com/a.png'><img src='https://i.imgur.com/b.png'>]],
        expectedHtml = [[<img src='BLOCKED/a.png'><img src='https://i.imgur.com/b.png'>]],
    },
    {
        name = "handles CSS url()",
        html = [[<div style="background: url(https://evil.com/bg.png)"></div>]],
        expectedHtml = [[<div style="background: url(BLOCKED/bg.png)"></div>]],
    },
    {
        name = "handles several URLs in one document",
        html = [[<a href="https://google.com/">a</a><img src="https://evil.com/x.png"><script src="https://raw.githubusercontent.com/a/b/c.js"></script>]],
        expectedHtml = [[<a href="https://google.com/">a</a><img src="BLOCKED/x.png"><script src="https://raw.githubusercontent.com/a/b/c.js"></script>]],
    },
    {
        name = "handles URLs in javascript strings",
        html = [[fetch("https://evil.com/api"); fetch('https://google.com/ok');]],
        expectedHtml = [[fetch("BLOCKED/api"); fetch('https://google.com/ok');]],
    },
    {
        name = "matches the scheme case insensitively",
        html = [[<img src="HTTPS://EVIL.COM/a.png"><img src="HTTPS://I.IMGUR.COM/a.png">]],
        expectedHtml = [[<img src="BLOCKED/a.png"><img src="HTTPS://I.IMGUR.COM/a.png">]],
    },
    {
        name = "keeps asset URIs",
        html = [[<img src="asset://garrysmod/materials/a.png">]],
        expectedHtml = [[<img src="asset://garrysmod/materials/a.png">]],
    },
    {
        name = "leaves text without URLs unchanged",
        html = [[<p>hello: world, a:b, 10:30</p>]],
        expectedHtml = [[<p>hello: world, a:b, 10:30</p>]],
    },
}

local function isAllowed( url )
    local options = CFCHTTP.GetOptionsForURL( url )
    return options.allowed == true
end

local function replaceBlocked( text )
    return CFCHTTP.ReplaceURLs( text, function( url )
        if isAllowed( url ) then return url end
        return "BLOCKED"
    end )
end

local function describe( url )
    local escaped = string.gsub( url, "[%c]", function( c )
        return string.format( "\\%d", string.byte( c ) )
    end )

    return "\"" .. escaped .. "\""
end

local cases = {}

for _, row in ipairs( urlCases ) do
    local suffix = row.note and ( " (" .. row.note .. ")" ) or ""

    table.insert( cases, {
        name = "GetAddress " .. describe( row.url ) .. " returns " .. tostring( row.expectedAddress ) .. suffix,
        func = function()
            local address = CFCHTTP.GetAddress( row.url )
            expect( address ).to.equal( row.expectedAddress )
        end
    } )

    table.insert( cases, {
        name = ( row.expectedAllowed and "Allows " or "Blocks " ) .. describe( row.url ) .. suffix,
        func = function()
            local allowed = isAllowed( row.url )
            expect( allowed ).to.equal( row.expectedAllowed )
        end
    } )
end

for _, row in ipairs( assetCases ) do
    table.insert( cases, {
        name = ( row.expectedAllowed and "Allows asset URI " or "Blocks asset URI " ) .. describe( row.url ),
        func = function()
            local allowed = isAllowed( row.url )
            expect( allowed ).to.equal( row.expectedAllowed )
        end
    } )
end

for _, row in ipairs( replaceCases ) do
    table.insert( cases, {
        name = "ReplaceURLs " .. row.name,
        func = function()
            local html = replaceBlocked( row.html )
            expect( html ).to.equal( row.expectedHtml )
        end
    } )
end

table.insert( cases, {
    name = "Blocks a nil URL",
    func = function()
        local allowed = isAllowed( nil )
        expect( allowed ).to.beFalse()

        local address = CFCHTTP.GetAddress( nil )
        expect( address ).to.beNil()
    end
} )

table.insert( cases, {
    name = "Matches user added entries regardless of their case",
    func = function( state )
        state.addedAddress = "Example.COM"
        CFCHTTP.config.addresses[state.addedAddress] = { allowed = true }

        local allowed = isAllowed( "https://example.com/" )
        expect( allowed ).to.beTrue()

        local upperAllowed = isAllowed( "https://EXAMPLE.com/" )
        expect( upperAllowed ).to.beTrue()
    end,
    cleanup = function( state )
        CFCHTTP.config.addresses[state.addedAddress] = nil
    end
} )

table.insert( cases, {
    name = "Matches user added wildcard entries regardless of their case",
    func = function( state )
        state.addedAddress = "*.Example.COM"
        CFCHTTP.config.addresses[state.addedAddress] = { allowed = true }

        local allowed = isAllowed( "https://cdn.example.com/" )
        expect( allowed ).to.beTrue()

        local lookalike = isAllowed( "https://evil.com?.example.com/" )
        expect( lookalike ).to.beFalse()
    end,
    cleanup = function( state )
        CFCHTTP.config.addresses[state.addedAddress] = nil
    end
} )

---@type GLuaTestTestGroup
local group = {
    groupName = "CFC HTTP Whitelist URL Table",

    beforeAll = function( state )
        state.originalConfig = CFCHTTP.config
        CFCHTTP.config = include( CFCHTTP.filenames.defaultLuaConfig )
    end,

    afterAll = function( state )
        CFCHTTP.config = state.originalConfig
    end,

    cases = cases,
}

return group
