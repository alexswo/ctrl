package require sha256
package require base64
package require http
package require tls
package require pki
package require json

namespace eval ctrl_ce {}

ad_proc -private ctrl_ce::base64_url_encode {
    {-input:required}
} {
    Base 64 URL encoding scheme. 
} {
    return [string map {\n "" "=" "" + - / _} [::base64::encode $input]]  
}

ad_proc -private ctrl_ce::make_access_token {
} {
    Creating an access token for a "service to service" account
    Access token only lasts for 60 minutes.
} {
    set header "\{\"alg\": \"RS256\",  \"typ\": \"JWT\"\}"
    set header [ctrl_ce::base64_url_encode -input $header]

    set claims "\{\"iss\": \"primary@stone-arch-167818.iam.gserviceaccount.com\", \
\"scope\": \"https://www.googleapis.com/auth/calendar\", \
\"aud\": \"https://accounts.google.com/o/oauth2/token\", \
\"exp\": \"[expr {[clock seconds] + 3600}]\", \
\"iat\": \"[clock seconds]\" \}"

    set claims [ctrl_ce::base64_url_encode -input $claims]

    set signature "$header.$claims"

    set fp [open "/web/dev/nnab-codebook/packages/ctrl-ars/keys/privatekey.pem" r]
    set keydata [read $fp]
    close $fp

    set key [::pki::pkcs::parse_key $keydata]
    set sig [ctrl_ce::base64_url_encode -input [::pki::sign $signature $key sha256]]
    set final "$signature.$sig"
    
    set http_body "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion="
    append http_body $final

    set result [util::http::post -url "https://accounts.google.com/o/oauth2/token" -body $http_body]
    set result_with_access_token [lindex $result 3]
    set pretty_result_with_access_token [::json::json2dict $result_with_access_token]
    set access_token [dict get $pretty_result_with_access_token "access_token"]

    return $access_token
}




ad_proc -public ctrl_ce::get_events {
    {-calendar_id: required}
} {
    set access_token [ctrl_ce::make_access_token]

    set header [ns_set create myset "Authorization" "Bearer $access_token"]
    set events_unformatted [util::http::get -url "https://www.googleapis.com/calendar/v3/calendars/$calendar_id/events" -headers $header]
    set events_formatted "[lindex $events_unformatted 3]"
    set events [dict get [json::json2dict $events_formatted] "items"]

    ctrl_ce::save_events -events $events
    return [db_list_of_lists ce_get_events {}]
}

ad_proc -public ctrl_ce::get_events_cache {
    {-calendar_id: required}
} {
#    Just getting the stored information from db

    Wrapper for get_events
    Caches output of the calendar events for 15 minutes.
} {
    util_memoize [list "ctrl_ce::get_events -calendar_id $calendar_id"] 900
}

ad_proc -private ctrl_ce::save_events {
    {-events:required}
} {
    Parses the retrieved events and saves them into db.
} {
    foreach item $events {
	# If you want to get more info from each of the events, then
	# look at the following documentation for it:                                                           
	# https://developers.google.com/google-apps/calendar/v3/reference/events                                                                   
	set event_id [dict get $item "iCalUID"]
	set title [dict get $item "summary"]
	set description [dict get $item "description"]
	set start_date [ctrl_ce::format_date -date [dict get $item "start"]]
	set end_date [ctrl_ce::format_date -date [dict get $item "end"]]
	db_dml ce_new {} 
    }	
    db_dml ce_dump {}
}

ad_proc -private ctrl_ce::format_date {
    {-date:required}
} {
    Formats the date so that it goes into the db nicely.
} {
    set formatted_date ""
    set date_list [split $date " "]
    set day_and_time [lindex $date_list 1]
    return $day_and_time
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
    lassign [ctrl_ce::build_insert_and_delete_lists -old_ids $selected_events -new_ids $events] \
        events_inserts \
        events_deletes

    db_dml ce_delete_user_events {}
    foreach new_events_id $events_inserts {
	db_dml ce_insert_user_events {}
    }    
}

ad_proc -private ctrl_ce::build_insert_and_delete_lists {
    {-old_ids: required}
    {-new_ids: required}
} {
    
} {
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

