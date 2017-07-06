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
\"aud\": \"https://www.googleapis.com/oauth2/v4/token\", \
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

    set status [catch {exec /web/dev/nnab-codebook/packages/ctrl-ars/tcl/get_token.sh $final} access_token_unformatted]

    if {$status == 0} {
    puts "script exited normally (exit status 0) and wrote nothing to stderr"
    } elseif {$::errorCode eq "NONE"} {
    puts "script exited normally (exit status 0) but wrote something to stderr which is in $access_token_unformatted"
    } elseif {[lindex $::errorCode 0] eq "CHILDSTATUS"} {
	puts "script exited with status [lindex $::errorCode end]."
    }

    set access_token_formatted "\{[lindex $access_token_unformatted 0]\}"
    set access_token [dict get [json::json2dict $access_token_formatted] "access_token"]
    return $access_token
}




ad_proc -public ctrl_ce::get_events {
    {-calendar_id: required}
} {
    # TODO: The calendar id has not been passed into the bash script yet. Please push it in after testing.                                                                                  
    set access_token [ctrl_ce::make_access_token]
    set status [catch {exec /web/dev/nnab-codebook/packages/ctrl-ars/tcl/get_events.sh $access_token} events_unformatted]

    if {$status == 0} {
        puts "script exited normally (exit status 0) and wrote nothing to stderr"
    } elseif {$::errorCode eq "NONE"} {
        puts "script exited normally (exit status 0) but wrote something to stderr which is in $events_unformatted"
    } elseif {[lindex $::errorCode 0] eq "CHILDSTATUS"} {
        puts "script exited with status [lindex $::errorCode end]."
    }

    set events_formatted "\{[lindex $events_unformatted 0]\}"
    set events [dict get [json::json2dict $events_formatted] "items"]
    ctrl_ce::save_events -events $events
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
    set retVal_events ""
    foreach item $events {
                         # If you want to get more info from each of the events, then
                         # look at the following documentation for it:                                                           
                         # https://developers.google.com/google-apps/calendar/v3/reference/events                                                                                        

	lappend retVal_events [dict get $item "summary"]
	if 0 {
	    set currVal [::json::write object \
			     title "\"[dict get $item "summary"]\"" \
			     description "\"[dict get $item "description"]\"" \
			     startTime "\"[dict get $item "start"]\"" \
			     endTime "\"[dict get $item "end"]\""
			 id "\"[dict get $item "iCalUID"]\"" ] 

	    lappend retVal_events $currVal "<break>"
	}
    }	
    doc_return 200 text/html $retVal_events 
}