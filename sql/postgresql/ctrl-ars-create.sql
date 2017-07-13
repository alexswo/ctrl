
create table ctrl_ars_questions (
   question_id  integer primary key,
   question varchar(100) ,
   session_id   integer constraint session_id_nn not null,
   response_1 varchar(50) ,
   response_2 varchar(50) ,
   response_3 varchar(50) ,
   response_4 varchar(50) ,
   response_5 varchar(50) ,
   active_p  char(1) default 'f' not null,
   time_to_respond integer,
   creation_date  timestamp default now()
);

create table ctrl_ars_responses (
   question_id integer,
   user_id  integer not null,
   response_selected integer,
   creation_date timestamp default now(),
   foreign key (question_id) references ctrl_ars_questions (question_id)
);


create table ctrl_calendar_events (
       id integer primary key,
       title varchar(200),
       description varchar(500),
       start_date timestamp,
       end_date timestamp,
       creation_date timestamp default now()
);
