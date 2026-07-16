hook.Add( "OnCHTTPRequest", "CFC_HTTP_CHTTP", function( req )
    if not req.url and not req.method then return end

    local options = CFCHTTP.GetOptionsForURL( req.url )
    local isAllowed = options and options.allowed
    local noisy = options and options.noisy

    local stack = string.Split( debug.traceback(), "\n" )
    CFCHTTP.LogRequest( {
        noisy = noisy,
        method = req.method,
        fileLocation = getSourceFromStack( stack ),
        urls = { { url = req.url, status = isAllowed and "allowed" or "blocked" } },
    } )

    if not isAllowed then
        return "URL is not whitelisted"
    end
end )
