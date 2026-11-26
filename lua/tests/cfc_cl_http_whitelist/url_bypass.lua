-- Regression tests for whitelist bypasses: each URL here is accepted by a browser/HTTP client
-- as pointing at a host that is NOT whitelisted, so it must never be reported as allowed.

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

---@type GLuaTestTestGroup
local group = {
    groupName = "CFC HTTP Whitelist URL Bypasses",

    beforeAll = function( state )
        state.originalConfig = CFCHTTP.config
        CFCHTTP.config = include( CFCHTTP.filenames.defaultLuaConfig )
    end,

    afterAll = function( state )
        CFCHTTP.config = state.originalConfig
    end,

    cases = {
        {
            name = "Blocks userinfo with an empty port placing an allowed host before the real host",
            func = function()
                local allowed = isAllowed( "http://google.com:@evil.com/" )
                expect( allowed ).to.beFalse()
            end
        },

        {
            name = "Blocks userinfo with a numeric port placing an allowed host before the real host",
            func = function()
                local allowedHttp = isAllowed( "http://google.com:80@evil.com/x" )
                expect( allowedHttp ).to.beFalse()

                local allowedHttps = isAllowed( "https://i.imgur.com:443@evil.com/a.png" )
                expect( allowedHttps ).to.beFalse()
            end
        },

        {
            name = "Blocks plain userinfo URLs",
            func = function()
                local allowed = isAllowed( "http://google.com@evil.com/" )
                expect( allowed ).to.beFalse()
            end
        },

        {
            name = "Blocks a non-standard scheme separator followed by an allowed URL later in the string",
            func = function()
                local singleSlash = isAllowed( "http:/evil.com/?https://google.com" )
                expect( singleSlash ).to.beFalse()

                local backslashes = isAllowed( "http:\\\\evil.com/?https://google.com" )
                expect( backslashes ).to.beFalse()

                local noSlashes = isAllowed( "http:evil.com/?u=https://google.com" )
                expect( noSlashes ).to.beFalse()
            end
        },

        {
            name = "Returns nil address for URLs that do not start with a scheme",
            func = function()
                local address = CFCHTTP.GetAddress( "http:/evil.com/?https://google.com" )
                expect( address ).to.beNil()
            end
        },

        {
            name = "Ends the host at a query delimiter so wildcard suffixes cannot be smuggled",
            func = function()
                local allowed = isAllowed( "http://evil.com?.steamstatic.com/" )
                expect( allowed ).to.beFalse()

                local address = CFCHTTP.GetAddress( "http://evil.com?.steamstatic.com/" )
                expect( address ).to.equal( "evil.com" )
            end
        },

        {
            name = "Ends the host at a fragment delimiter so wildcard suffixes cannot be smuggled",
            func = function()
                local allowed = isAllowed( "http://evil.com#.googleusercontent.com/" )
                expect( allowed ).to.beFalse()
            end
        },

        {
            name = "Ends the host at a backslash so wildcard suffixes cannot be smuggled",
            func = function()
                local allowed = isAllowed( "http://evil.com\\.facepunch.com/" )
                expect( allowed ).to.beFalse()
            end
        },

        {
            name = "Rejects hosts containing characters that are not valid in hostnames",
            func = function()
                local semicolon = isAllowed( "http://evil.com;.steamstatic.com/" )
                expect( semicolon ).to.beFalse()

                local percentEncoded = isAllowed( "http://evil.com%2f.facepunch.com/" )
                expect( percentEncoded ).to.beFalse()
            end
        },

        {
            name = "Does not treat the dot in the discord cdn pattern as a wildcard",
            func = function()
                local letter = isAllowed( "https://cdnxdiscordapp.com/a.png" )
                expect( letter ).to.beFalse()

                local dash = isAllowed( "https://cdn-discordapp.com/a.png" )
                expect( dash ).to.beFalse()
            end
        },

        {
            name = "Does not treat the dot in the keybase pattern as a wildcard",
            func = function()
                local letter = isAllowed( "https://abc.keybasexpub/" )
                expect( letter ).to.beFalse()

                local fragment = isAllowed( "https://abc.keybase#pub/" )
                expect( fragment ).to.beFalse()
            end
        },

        {
            name = "No longer allows the defunct tinypic domain",
            func = function()
                local allowed = isAllowed( "https://ievil.tinypic.com/" )
                expect( allowed ).to.beFalse()
            end
        },

        {
            name = "Blocks lookalike hosts that only share a prefix or suffix with an allowed host",
            func = function()
                local prefix = isAllowed( "http://google.com.evil.com/" )
                expect( prefix ).to.beFalse()

                local suffix = isAllowed( "http://evilsteamstatic.com/" )
                expect( suffix ).to.beFalse()
            end
        },

        {
            name = "Replaces userinfo URLs in HTML instead of keeping the allowed-looking prefix",
            func = function()
                local html = replaceBlocked( [[<img src="http://google.com:@evil.com/a.png">]] )
                expect( html ).to.equal( [[<img src="BLOCKED/a.png">]] )
            end
        },

        {
            name = "Replaces query-smuggled wildcard URLs in HTML",
            func = function()
                local html = replaceBlocked( [[<img src="http://evil.com?.steamstatic.com/a.png">]] )
                expect( html ).to.equal( [[<img src="BLOCKED?.steamstatic.com/a.png">]] )
            end
        },

        {
            name = "Keeps allowed URLs in HTML unchanged",
            func = function()
                local html = replaceBlocked( [[<img src="https://i.imgur.com/a.png">]] )
                expect( html ).to.equal( [[<img src="https://i.imgur.com/a.png">]] )
            end
        },

        {
            name = "Still allows exact entries with a port, query or fragment",
            func = function()
                local port = isAllowed( "https://google.com:443/x" )
                expect( port ).to.beTrue()

                local query = isAllowed( "https://google.com?q=1" )
                expect( query ).to.beTrue()

                local fragment = isAllowed( "https://google.com#a" )
                expect( fragment ).to.beTrue()
            end
        },

        {
            name = "Matches hosts and schemes case-insensitively",
            func = function()
                local allowed = isAllowed( "HTTPS://Google.COM/" )
                expect( allowed ).to.beTrue()
            end
        },

        {
            name = "Ignores surrounding whitespace like a browser does",
            func = function()
                local allowed = isAllowed( "  https://google.com/ " )
                expect( allowed ).to.beTrue()
            end
        },

        {
            name = "Still allows subdomains matched by wildcard entries",
            func = function()
                local nested = isAllowed( "https://a.b.steamstatic.com/x" )
                expect( nested ).to.beTrue()

                local single = isAllowed( "https://lh3.googleusercontent.com/x" )
                expect( single ).to.beTrue()
            end
        },

        {
            name = "Still allows hosts matched by pattern entries",
            func = function()
                local cdn = isAllowed( "https://cdn.discordapp.com/a.png" )
                expect( cdn ).to.beTrue()

                local numberedCdn = isAllowed( "https://cdn1.discordapp.com/a.png" )
                expect( numberedCdn ).to.beTrue()

                local images = isAllowed( "https://images-ext-1.discordapp.net/x" )
                expect( images ).to.beTrue()

                local keybase = isAllowed( "https://foo.keybase.pub/" )
                expect( keybase ).to.beTrue()
            end
        },
    }
}

return group
