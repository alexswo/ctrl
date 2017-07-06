package require sha256
package require base64
package require http
package require tls
package require pki
package require json
package require json::write

proc base64_url_encode {input} {
    return [string map {\n "" "=" "" + - / _} [::base64::encode $input]]
}

# Access token only lasts for 60 minutes. 
proc make_access_token {} {

    set header "\{\"alg\": \"RS256\",  \"typ\": \"JWT\"\}"
    set header [base64_url_encode $header]

    set claims "\{\"iss\": \"primary@stone-arch-167818.iam.gserviceaccount.com\", \
	\"scope\": \"https://www.googleapis.com/auth/calendar\", \
	\"aud\": \"https://www.googleapis.com/oauth2/v4/token\", \
	\"exp\": \"[expr {[clock seconds] + 3600}]\", \
	\"iat\": \"[clock seconds]\" \}"

    set claims [base64_url_encode $claims]

    set signature "$header.$claims"

    set fp [open "/web/dev/nnab-codebook/packages/ctrl-ars/keys/privatekey.pem" r]
    set keydata [read $fp]
    close $fp

    set key [::pki::pkcs::parse_key $keydata]
    set sig [base64_url_encode [::pki::sign $signature $key sha256]]
    set final "$signature.$sig"

    set status [catch {exec /web/dev/nnab-codebook/packages/ctrl-ars/www/get_token.sh $final} access_token_unformatted]

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

proc get_events {calendar_id} {
    set access_token [make_access_token]
    set status [catch {exec /web/dev/nnab-codebook/packages/ctrl-ars/www/get_events.sh $access_token} events_unformatted]

    if {$status == 0} {
	puts "script exited normally (exit status 0) and wrote nothing to stderr"
    } elseif {$::errorCode eq "NONE"} {
	puts "script exited normally (exit status 0) but wrote something to stderr which is in $events_unformatted"
    } elseif {[lindex $::errorCode 0] eq "CHILDSTATUS"} {
        puts "script exited with status [lindex $::errorCode end]."
    }
    
    set events_formatted "\{[lindex $events_unformatted 0]\}"
    set events [dict get [json::json2dict $events_formatted] "items"]
    save_events $events
}

proc save_events {events} {

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

set calendar_events [get_events "ctrlcalendar%40gmail.com"]
