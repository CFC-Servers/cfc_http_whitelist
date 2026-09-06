
local cfc_http_restrictions_sv_chat_enabled = CreateConVar( "cfc_http_restrictions_sv_chat_enabled", "0", FCVAR_ARCHIVE, "Enable the whitelist for URLs in chat messages?" )

hook.Add( "PlayerSay", "CFC_HTTP_ChatFilter", function( _, text )
    if not cfc_http_restrictions_sv_chat_enabled:GetBool() then return end

    local foundBlocked = false
    local urls = CFCHTTP.FindURLs( text )
    local blockedURLs = {}
    for _, url in ipairs( urls ) do
        local options = CFCHTTP.GetOptionsForURL( url )
        if options.allowed == false then
            text = string.gsub( text, string.PatternSafe( url ), "BLOCKED URL" )
            foundBlocked = true
            table.insert( blockedURLs, {
                url = url,
                status = "BLOCKED",
                reason = "Blocked URL in chat message"
            } )
        end
    end

    if foundBlocked then
        CFCHTTP.LogRequest( {
            method = "CHAT",
            urls = blockedURLs,
            fileLocation = debug.getinfo( 1, "S" ).short_src
        } )
        return text
    end
end )
