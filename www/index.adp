<master>


<script src="https://code.jquery.com/jquery-1.10.2.js"></script>

<html>
  <head>
    <title>Google Calendar</title>
    <meta charset='utf-8' />
  </head>
  <body>
    <div id="calendar_container"></div>
  </body>
</html>

<script type="text/javascript">	
  

  function myFunc() {
	console.log("pickles")
  }
  $(function() {
	var mod = "@calendar_events@".replace(/&#34;/g, "\""); 
	var eventList = mod.split(" &lt;break&gt;");
        initDiv = document.getElementById('calendar_container');
	for (var i = 0; i < eventList.length; i++) {

            if (i == eventList.length - 1) break;
	    var eachEvent = JSON.parse(eventList[i]);
            var eachEventUL = document.createElement('ul');
            initDiv.appendChild(eachEventUL);

	    var event_name = document.createElement('li');
            event_name.setAttribute('onclick', 'myFunc');
            event_name.appendChild(document.createTextNode(eachEvent.title))
	    eachEventUL.appendChild(event_name)


	    var event_desc = document.createElement('li');
            event_desc.appendChild(document.createTextNode(eachEvent.description))                                                   
            eachEventUL.appendChild(event_desc)    

            var event_start = document.createElement('li');  
            event_start.appendChild(document.createTextNode(eachEvent.startTime))
            eachEventUL.appendChild(event_start)

            var event_end = document.createElement('li');
            event_end.appendChild(document.createTextNode(eachEvent.endTime))
            eachEventUL.appendChild(event_end)      

	    var event_id = document.createElement('li');
            event_id.appendChild(document.createTextNode(eachEvent.id))
            eachEventUL.appendChild(event_id) 

            console.log(eachEvent.eventName)
	
	}

  });

  
</script>

