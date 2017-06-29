package require Tcl 8.5
package require http
package require sha256
package require base64
package require tls
package require pki
package require json

ad_library {

    @author Alex Oh
    @creation-date 2017-06-29
}



namespace eval ctrl_ce {}

ad_proc -public ctrl_ce::new { 
    {-event_id:required}
    {-title_id:required}
    {-description_id:required}
    {-start_date:required}
    {-end_date:required}
} {
    Load the newly fetched data into db.
} {
    set error_p 0
    db_transaction { 
	db_dml ce_new {} 
    } on_error { 
	set error_p 1
	db_abort_transaction
    }
    if $error_p { 
	ad_return_complaint $error_p $errmsg
	return 
    }
}

ad_proc -public ctrl_ce::dump {
} {
    Remove all previous entries in the table.
} {
    set error_p 0
    db_transaction {
        db_dml ce_dump {}
    } on_error {
        set error_p 1
        db_abort_transaction
    }
    if $error_p {
        ad_return_complaint $error_p $errmsg
        return
    }
}

ad_proc -public ctrl_ce::make_access_token {
} {
   Creating an access token for a "service to service" account
} {
    # JWT follows this format: {Base64url encoded header}.{Base64url encoded claim set}.{Base64url encoded signature}                  
    set header [::json::write object \
                "alg" "\"RS256\"" \
		    "typ" "\"JWT\""]

    set header [ctrl_ce::base64_url_encode -input $header]

    # Token is accessible for maximum of 1 Hour.                                                                            
    set claims [::json::write object \
                "iss" "\"primary@stone-arch-167818.iam.gserviceaccount.com\"" \
                "scope" "\"https://www.googleapis.com/auth/calendar\"" \
                "aud" "\"https://accounts.google.com/o/oauth2/token\"" \
		    "exp" "\"[expr {[clock seconds] + 3600}]\"" \
		    "iat" "\"[clock seconds]\"" ]
    set claims [ctrl_ce::base64_url_encode -input $claims]

    set signature "$header.$claims"

    # Current directory that privatekey.pem resides in is: /web/dev/nnab-codebook/packages/planilla/sql/postgresql                                                                            
    set fp [open "privatekey.pem" r]
    set keydata [read $fp]
    close $fp

    set key [::pki::pkcs::parse_key $keydata]

    set sig [ctrl_ce::base64_url_encode -input [::pki::sign $signature $key sha256]]

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

ad_proc -public ctrl_ce::make_access_token_cache {
} {
   Creating an access token for a "service to service" account -- cached 
} {
    set token [util_memoize  "ctrl_ce::make_access_token" 3600]
    return $token
}


ad_proc -public ctrl_ce::get_events {
    {-calendar_id:required}
} {
    After obtaining an access token to perform a "service to service" call, 
    use the access token to make an api call for retrieving calendar events.
} {

    set access_token ctrl_ce::make_access_token
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


ad_proc -public ctrl_ce::get_events_cache {
    {-calendar_id:required}
} {
    Wrapper for get_events
    Caches output of the calendar events for 15 minutes.
} {
    set events [util_memoize [list "ctrl_ce::get_events" $calendar_id] 900]
    return $events
}

ad_proc -public ctrl_ce::save_events {
    {-calendar_id:required}
} {
    Parses the retrieved events and saves them into db.
} {
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

ad_proc -public ctrl_ce::base64_url_encode {
    {-input:required}
} {
    Base 64 URL encoding scheme. 
} {
    return [string map {\n "" "=" "" + - / _} [::base64::encode $input]]  
}