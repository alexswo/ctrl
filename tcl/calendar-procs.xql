<?xml version="1.0"?>
<queryset>
  <fullquery name="ctrl_ce::new.ce_new">
    <querytext>                                                                                                                                                   
      insert into ctrl_calendar_events
      (event_id, title, description, start_date, end_date)                                                                                                        
      values                                                                                                                                                      
      (:event_id, :title, :description, :start_date, :end_date)                                                                                                   
   
    </querytext>
  </fullquery>

  <fullquery name="ctrl_ce::dump.ce_dump">
    <querytext>                                                                                                                                                  
      delete from ctrl_calendar_events                                                                                                                          
      where
      creation_date <  NOW()  -  INTERVAL '5 minutes'                                                                                                                  </querytext>
  </fullquery>
</queryset>  
