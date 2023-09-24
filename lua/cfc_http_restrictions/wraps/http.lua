local function wrapHTTP()
    _HTTP = _HTTP or HTTP
    print( "HTTP wrapped, original function at '_G._HTTP'" )

    HTTP = function( req )
        print( "HTTP request to " .. req.url )
        local options = CFCHTTP.GetOptionsForURL( req.url )
        local isAllowed = options and options.allowed
        local noisy = options and options.noisy

        local stack = string.Split( debug.traceback(), "\n" )
        CFCHTTP.LogRequest( {
            noisy = noisy,
            method = req.method,
            fileLocation = stack[3],
            urls = { { url = req.url, status = isAllowed and "allowed" or "blocked" } },
        } )

        local onFailure = req.failed
        if not isAllowed then
            if onFailure then onFailure( "URL is not whitelisted" ) end
            return
        end
        _HTTP( req )
    end
end
wrapHTTP()
