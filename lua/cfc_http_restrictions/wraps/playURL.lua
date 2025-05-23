CFCHTTP = CFCHTTP or {}

-- the URI was blocked because it was not in the whitelist
CFCHTTP.BASS_ERROR_BLOCKED_URI = 11001
-- unused: the request was blocked after inspecting the content
-- this is likely because the content could result in playing blocked URIs
CFCHTTP.BASS_ERROR_BLOCKED_CONTENT = 11002

local function wrapPlayURL()
    _sound_PlayURL = _sound_PlayURL or sound.PlayURL
    print( "sound.PlayURL wrapped, original function at _sound_PlayUrl" )

    ---@diagnostic disable-next-line: duplicate-set-field
    sound.PlayURL = function( url, flags, callback )
        local stack = string.Split( debug.traceback(), "\n" )

        local options = CFCHTTP.GetOptionsForURL( url )
        local isAllowed = options and options.allowed
        local noisy = options and options.noisy

        local logData = {
            noisy = noisy,
            method = "GET",
            fileLocation = stack[3],
            urls = { { url = url, status = isAllowed and "allowed" or "blocked" } },
        }

        if not isAllowed then
            CFCHTTP.LogRequest( logData )
            if callback then callback( nil, CFCHTTP.BASS_ERROR_BLOCKED_URI, "BASS_ERROR_BLOCKED_URI" ) end
            return
        end

        CFCHTTP.GetFileDataURLS( url, function( uris, err, code )
            if err ~= nil then
                logData.urls[1].status = "blocked"
                logData.urls[1].reason = err

                CFCHTTP.LogRequest( logData )
                if callback then
                    if code == 401 or code == 403 then
                        callback( nil, 49, "BASS_ERROR_DENIED" )
                    elseif code == 404 then
                        callback( nil, 2, "BASS_ERROR_FILEOPEN" )
                    else
                        callback( nil, CFCHTTP.BASS_ERROR_BLOCKED_CONTENT, "BASS_ERROR_BLOCKED_CONTENT" )
                    end
                end
                return
            end
            if #uris == 0 then
                CFCHTTP.LogRequest( logData )
                _sound_PlayURL( url, flags, callback )
                return
            end

            isAllowed = false
            logData.urls[1].status = "blocked"
            logData.urls[1].reason = "cant load files containing urls"

            CFCHTTP.LogRequest( logData )
            if callback then callback( nil, CFCHTTP.BASS_ERROR_BLOCKED_CONTENT, "BASS_ERROR_BLOCKED_CONTENT" ) end
        end )
    end
end

wrapPlayURL()
