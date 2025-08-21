
local cfc_http_restrictions_sv_chat_enabled = CreateConVar( "cfc_http_restrictions_sv_chat_enabled", "0", FCVAR_ARCHIVE, "Enable the whitelist for URLs in chat messages?" )

hook.Add( "PlayerSay", "CFC_HTTP_ChatFilter", function( _, text )
    if not cfc_http_restrictions_sv_chat_enabled:GetBool() then return end

    local foundBlocked = false
    local urls = CFCHTTP.FindURLs( text )
    for _, url in ipairs( urls ) do
        local options = CFCHTTP.GetOptionsForURL( url )
        if options.allowed == false then
            text = string.gsub( text, url, "BLOCKED URL" )
            foundBlocked = true
        end
    end

    if foundBlocked then
        return text
    end
end )
