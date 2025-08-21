local cfc_http_restrictions_cl_chat_enabled = CreateConVar( "cfc_http_restrictions_cl_chat_enabled", "1", FCVAR_ARCHIVE, "Enable the whitelist for URLs in chat messages?" )

hook.Add( "OnPlayerChat", "CFC_HTTP_ChatFilter", function( ply, text )
    if not cfc_http_restrictions_cl_chat_enabled:GetBool() then return end

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
        chat.AddText( ply, color_white, ": ", text )
        return true
    end
end )
