set user_id [ad_conn user_id]

set events_options [ctrl_ce::get_events -calendar_id "ctrlcalendar%40gmail.com"]
set selected_events [ctrl_ce::get_user_events -user_id $user_id]


ad_form -name calendar -export {user_id return_url} -form {
    {events:integer(checkbox),multiple,optional
	{options $events_options}
	{values $selected_events}
    }
} -html {
} -on_submit {
    ctrl_ce::modify_user_events -user_id $user_id -selected_events $selected_events -events $events
} -after_submit {
}