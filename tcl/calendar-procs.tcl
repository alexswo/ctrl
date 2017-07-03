#package require sha256
#package require base64
#package require pki
#package require json
#package require json::write
#package reuquire Tcl 8.5
#package require http 
#package require http 2.7
#package require tls


package require sha256
package require base64
package require http
package require tls
package require pki
package require json
package require json::write
package require Tcl 8.5

namespace eval ctrl_ce {}

ad_proc -private ctrl_ce::save_events {
    {-calendar:required}
} {
    Parses the retrieved events and saves them into db.
} {
    set calendar [json::json2dict $calendar]
    set events [dict get $calendar "items"]

    foreach item $events {
        # If you want to get more info from each of the events, then                                                                                     
	# look at the following documentation for it:
        # https://developers.google.com/google-apps/calendar/v3/reference/events                                                                                             
	set event_id [dict get $item "iCalUID"]
	set title [dict get $item "summary"]
	set decription [dict get $item "description"]
	set start_date [dict get $item "start"]
	set end_date [dict get $item "end"]
	db_dml ce_new {} 
    }

    db_dml ce_dump {}
} 

ad_proc -private ctrl_ce::base64_url_encode {
    {-input:required}
} {
    Base 64 URL encoding scheme. 
} {
    return [string map {\n "" "=" "" + - / _} [::base64::encode $input]]  
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
    
    set fp [::http::geturl "https://accounts.google.com/o/oauth2/token" -query $postdata]
    set status [::http::status $fp]
    set ncode [::http::ncode $fp]
    set html [::http::data $fp]
    ::http::cleanup $fp
    set response_dict [::json::json2dict $html]
    set access_token [dict get $response_dict access_token]
    return $access_token
}

ad_proc -private ctrl_ce::make_access_token_cache {
} {
   Creating an access token for a "service to service" account -- cached 
} {
    return [util_memoize  "ctrl_ce::make_access_token" 3600]
}

ad_proc -private ctrl_ce::fetch_events {
    {-calendar_id:required}
} {
    After obtaining an access token to perform a "service to service" call, 
    use the access token to make an api call for retrieving calendar events.
} {

    set access_token [ctrl_ce::make_access_token]
    set auth "Authorization"
    set token "Bearer $access_token"
    set token_for_header [list "$auth" "$token"]
    #ctrlcalendar@gmail.com -> ctrlcalendar%40gmail.com (for url font)                                                                                                                        
    set my_url "https://www.googleapis.com/calendar/v3/calendars/$calendar_id/events"
    set request_calendar [::http::geturl $my_url -headers $token_for_header]
    # calendars/PRIMARY/events where primary decides which calendar you are looking at                                                                   
    set calendar [::http::data $request_calendar]
    ::http::cleanup $request_calendar
    return [ctrl_ce::save_events -calendar $calendar]
}

ad_proc -private ctrl_ce::fetch_events_cache {
    {-calendar_id:required}
} {
    Wrapper for get_events
    Caches output of the calendar events for 15 minutes.
} {
    util_memoize [list "ctrl_ce::fetch_events -calendar_id $calendar_id"] 900
}


ad_proc -public ctrl_ce::nothing {
} {
    Just getting the stored information from db
} {
    doc_return 200 text/html "hellooooo"
}


ad_proc -public ctrl_ce::get_events {
} {
    Just getting the stored information from db
} {
    ctrl_ce::fetch_events_cache -calendar_id "ctrlcalendar%40gmail.com"
    return [db_list_of_lists ce_get_events {}]
}

ad_proc -public ctrl_ce::get_user_events {
    {-user_id:required}
} {
   Get the event IDs associated with a user ID.
    This does not get the event table. 
} {
    return [db_list ce_get_user_events {}]
}

ad_proc -public ctrl_ce::modify_user_events {
    {-user_id: required}
    {-selected_events: required}
    {-events: required}
} {
    Modifies the user events
} {
    lassign [build_insert_and_delete_lists $selected_events $events] \
        events_inserts \
        events_deletes

	db_dml ce_delete_user_events {}
        foreach new_events_id $events_inserts {
	    db_dml ce_insert_user_events {}
	}    
}

proc build_insert_and_delete_lists {old_ids new_ids} {
    set insert [list]
    set delete [list]

    foreach old_id $old_ids {
            set old($old_id) 1
    }

    foreach new_id $new_ids {
            set new($new_id) 1
    }

    foreach new_id $new_ids {
	if {![info exists old($new_id)]} {
                lappend insert $new_id
	}
    }

    foreach old_id $old_ids {
	if {![info exists new($old_id)]} {
                lappend delete $old_id
	}
    }

    return [list $insert $delete]
}



