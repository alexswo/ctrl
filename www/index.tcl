package require sha256
package require base64
package require http
package require tls
package require pki
package require json
package require Tcl 8.5


proc base64_url_encode {input} {
    return [string map {\n "" "=" "" + - / _} [::base64::encode $input]]
}

# Access token only lasts for 60 minutes. 
proc make_access_token {} {
    # JWT follows this format: {Base64url encoded header}.{Base64url encoded claim set}.{Base64url encoded signature}
    set header [::json::write object \                
		"alg" "\"RS256\"" \
		"typ" "\"JWT\""]

    set header [base64_url_encode $header]

    # Token is accessible for maximum of 1 Hour.
    set claims [::json::write object \
                "iss" "\"primary@stone-arch-167818.iam.gserviceaccount.com\"" \
                "scope" "\"https://www.googleapis.com/auth/calendar\"" \
                "aud" "\"https://accounts.google.com/o/oauth2/token\"" \
		"exp" "\"[expr {[clock seconds] + 3600}]\"" \
	        "iat" "\"[clock seconds]\"" ]
    set claims [base64_url_encode $claims]

    set signature "$header.$claims"

    # Current directory that privatekey.pem resides in is: /web/dev/nnab-codebook/packages/planilla/sql/postgresql
    set fp [open "privatekey.pem" r]
    set keydata [read $fp]
    close $fp

    set key [::pki::pkcs::parse_key $keydata]
    set sig [base64_url_encode [::pki::sign $signature $key sha256]]
    set final "$signature.$sig"

    set postdata [::http::formatQuery grant_type "urn:ietf:params:oauth:grant-type:jwt-bearer" assertion $final]

    # Must initialize the tls before using ::http::geturl            
    # tls::init -tls1 true -ssl2 false -ssl3 false	

    ::http::register https 443 ::tls::socket
    set fp [::http::geturl "https://accounts.google.com/o/oauth2/token" -query $postdata]
    set status [::http::status $fp]
    set ncode [::http::ncode $fp]
    set html [::http::data $fp]
    ::http::cleanup $fp
    set response_dict [::json::json2dict $html]
    set access_token [dict get $response_dict access_token]
    return $access_token
}

proc get_events {calendar_id} {
    set access_token [make_access_token]
    set auth "Authorization"
    set token "Bearer $access_token"
    set token_for_header [list "$auth" "$token"]
    #ctrlcalendar@gmail.com -> ctrlcalendar%40gmail.com (for url font)
    set my_url "https://www.googleapis.com/calendar/v3/calendars/$calendar_id/events"
    set request_calendar [::http::geturl $my_url -headers $token_for_header]
    # calendars/PRIMARY/events where primary decides which calendar you are looking at                    
    set calendar [::http::data $request_calendar]
    ::http::cleanup $request_calendar
    return [save_events $calendar]
}

proc save_events {calendar} {
 
    set calendar [json::json2dict $calendar]
    set events [dict get $calendar "items"]
    set retVal_events ""
    foreach item $events {

                         # If you want to get more info from each of the events, then
                         # look at the following documentation for it:                                                           
                         # https://developers.google.com/google-apps/calendar/v3/reference/events                                                                                        
	set currVal [::json::write object \
			 title "\"[dict get $item "summary"]\"" \
			 description "\"[dict get $item "description"]\"" \
			 startTime "\"[dict get $item "start"]\"" \
			 endTime "\"[dict get $item "end"]\""
			 id "\"[dict get $item "iCalUID"]\"" ] 

	lappend retVal_events $currVal "<break>"
    }	

    # Can't have any new lines or else javascript doesnt parse it correctly.
    set removeNewLine [regsub -all "\n" $retVal_events ""]

    # Can't have any double opening and closing braces. Does not fit the json format. 
    set removeLeftBrace [regsub -all {\{\{} $removeNewLine "\{"]  
    set removeRightBrace [regsub -all {\}\}} $removeLeftBrace "\}"]

    return $removeRightBrace
}



set calendar_events [get_events "ctrlcalendar%40gmail.com"]
