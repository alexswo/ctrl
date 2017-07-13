set user_id [ad_conn user_id]
set events_options [ctrl_ce::get_events_cache -calendar_id "ctrlcalendar%40gmail.com"]
set selected_events [ctrl_ce::get_user_events -user_id $user_id]
ns_log notice "These are the events options: $events_options"
ns_log notice "These are the selected events: $selected_events"

ad_form -name calendar -export {user_id return_url} -form {
    {events:string(checkbox),multiple,optional
	{options $events_options}
	{values $selected_events}
    }
} -html {
} -on_submit {
    ctrl_ce::modify_user_events -user_id $user_id -selected_events $selected_events -events $events
}