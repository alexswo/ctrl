<?xml version="1.0"?>
<queryset>
  <fullquery name="cra::calendar_events::new.insert_calendar_events">
    <querytext>
      insert into ctrl_calendar_events
      (event_id, title, description, start_date, end_date)
      values
      (:event_id, :title, :description, :start_date, :end_date)
    </querytext>
  </fullquery>

  <fullquery name="cra::calendar_events::delete_all.delete_all_calendar_events">
    <querytext>
      delete from ctrl_calendar_events
      where
      creation_date <  NOW()  -  INTERVAL '5 minutes'
    </querytext>
  </fullquery>
</queryset> 
	    
