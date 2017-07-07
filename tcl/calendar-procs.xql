<?xml version="1.0"?>
<queryset>
  <fullquery name="ctrl_ce::save_events.ce_new">
    <querytext>                                                                                                                                                   
      insert into ctrl_calendar_events
      (event_id, title, description, start_date, end_date)                                                                                                        
      values                                                                                                                                               
      (:event_id, :title, :description, :start_date, :end_date)

    </querytext>
  </fullquery>

  <fullquery name="ctrl_ce::save_events.ce_dump">
    <querytext>                                                                                                                                                  
      delete from ctrl_calendar_events                                                                                                                          
      where
    creation_date <  NOW()  -  INTERVAL '5 minutes'                                                                                                                  
    </querytext>
  </fullquery>

  <fullquery name="ctrl_ce::get_events.ce_get_events">
    <querytext>                           
      select title||', '||description||', '|| start_date||', '||end_date as event,
      event_id
      from ctrl_calendar_events
      order by start_date asc
     </querytext>
   </fullquery>

  <fullquery name="ctrl_ce::get_user_events.ce_get_user_events">
    <querytext>                                                                                           
      select event_id 
      from ctrl_calendar_user_events                                                                          
      where user_id = :user_id
    </querytext>
  </fullquery>

  <fullquery name="ctrl_ce::modify_user_events.ce_delete_user_events">
    <querytext>                                                                                           
      delete from                                                                                                                                            
      ctrl_calendar_user_events                                                                                                                              
      where                                                                                                                                                  
      user_id = :user_id and event_id [in: events_deletes]    
    </querytext>
  </fullquery>

  <fullquery name="ctrl_ce::modify_user_events.ce_insert_user_events">
    <querytext>                                                                                           
      insert into ctrl_calendar_user_events
      (event_id, user_id)
      values
      (:new_events_id, :user_id)
    </querytext>
  </fullquery>
  

</queryset>  
