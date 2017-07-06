package require json

#ctrl_ce::get_events -calendar_id "hey"

set firstBody "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=eyJhbGciOiAiUlMyNTYiLCAgInR5cCI6ICJKV1QifQ.eyJpc3MiOiAicHJpbWFyeUBzdG9uZS1hcmNoLTE2NzgxOC5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbSIsICAic2NvcGUiOiAiaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jYWxlbmRhciIsICAiYXVkIjogImh0dHBzOi8vYWNjb3VudHMuZ29vZ2xlLmNvbS9vL29hdXRoMi90b2tlbiIsICAiZXhwIjogIjE0OTkzODEwNzgiLCAgImlhdCI6ICIxNDk5Mzc3NDc4IiB9.iJaEsQugKtKimOcQojM7plScw7rJ1OMy-hfNOH3eXPVBgidMjDSkVwM5okK8xbEt8ms1GH7x1G2SaT04zmXLl9bkyK3uIT52vkpvoWHjhfbYyhOh09rcwXa8CTSoHzC5hC43BYZ8QPEHOqWHBJkWLrQm-vmVhaKgbtWcCaOW18I3VKkywV7-QNQ4excmYdy3_LmJsIkdGT2zMRkEvP6pt20hN43yXzUxCodZy5b62_nA_eojN6ZfDp_HQFEZKHkab5RZluGpf8hNIR6xn-ycZJUxe4Epx8_mSRqV6B1_l4kDK6QDoO7-hunVOj7ywqO60j6EqH7bUSO_l7gVVJ_Q0w"

set result [util::http::post -url "https://accounts.google.com/o/oauth2/token" -body $firstBody]
set json_part [lindex $result 3]
set pretty_json [::json::json2dict $json_part]
set access_token [dict get $pretty_json "access_token"]
#doc_return 200 text/json "$json_part\n$access_token"



set myset [ns_set create myset "Authorization" "Bearer ya29.Elh_BC-D0VSVFYU4Wvi34dfNBIFovrYQRMKdWYTFKxqPwc6nq9nx97Ie9jxg64NrD3Fqd7VSD7M9rOGk7_pkRFigKnaq6Xtl01kldAePJc7nbCEwDveyq9kr"]

set events_unformatted [util::http::get -url "https://www.googleapis.com/calendar/v3/calendars/ctrlcalendar%40gmail.com/events" -headers $myset]

set events_formatted "[lindex $events_unformatted 3]"
#set temp [json::json2dict $events_formatted]

set events [dict get [json::json2dict $events_formatted] "items"]

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