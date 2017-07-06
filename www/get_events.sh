#!/bin/bash

first_arg=$1
curl https://www.googleapis.com/calendar/v3/calendars/ctrlcalendar%40gmail.com/events?access_token\=$first_arg