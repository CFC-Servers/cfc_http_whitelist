local function getSourceFromStack( stack )
    local s = stack[3]

    for i = 4, 5 do
        if not stack[i] then break end
        s = stack[i]

        if not string.EndsWith( s, "/http.lua" ) then break end
    end

    return s
end

local function wrapHTTP()
    _HTTP = _HTTP or HTTP

    HTTP = function( req )
        if not req.url and not req.method then
            return _HTTP({})
        end

        local options = CFCHTTP.GetOptionsForURL( req.url )
        local isAllowed = options and options.allowed

        local noisy = options and options.noisy

        local stack = string.Split( debug.traceback(), "\n" )
        local status = isAllowed and "allowed" or "blocked"

        CFCHTTP.LogRequest( {
            noisy = noisy,
            method = req.method,
            fileLocation = getSourceFromStack( stack ),
            urls = { { url = req.url, status = status } }
        } )

        local onFailure = req.failed
        if not isAllowed then
            if onFailure then onFailure( "URL is not whitelisted" ) end
            return
        end

        return _HTTP( req )
    end
end

wrapHTTP()
