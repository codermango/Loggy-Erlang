-module(worker).
-export([start/5, stop/1]).

start(Name, Logger, Seed, Sleep, Jitter) ->
    spawn(fun() ->
		  init(Name, Logger, Seed, Sleep, Jitter) end).

stop(Worker) ->
    Worker ! stop.

init(Name, Log, Seed, Sleep, Jitter) ->
    random:seed(Seed, Seed, Seed),
    receive
	{peers, Peers} ->
	    loop(Name, Log, Peers, Sleep, Jitter, 0);
	stop ->
	    ok
    end.

loop(Name, Log, Peers, Sleep, Jitter, Counter) ->
    Wait = random:uniform(Sleep),
    receive
	{msg, Time, Msg} ->
	    NewTime = erlang:max(Counter,Time)+1,
	    Log ! {log, Name, NewTime, {received, Msg}},
	    loop(Name, Log, Peers, Sleep, Jitter, NewTime);
	stop ->
	    ok;
	Error ->
	    Log ! {log, Name, time, {error, Error}}
    after Wait ->
	    Selected = select(Peers),
	    Time = Counter + 1,
	    Message = {hello, random:uniform(100)},
	    Selected ! {msg, Time, Message},
	    jitter(Jitter),
	    Log ! {log, Name, Time, {sending, Message}},
	    loop(Name, Log, Peers, Sleep, Jitter, Time)
    end.

select(Peers) ->
    lists:nth(random:uniform(length(Peers)), Peers).

jitter(0) ->
    ok;
jitter(Jitter) ->
    timer:sleep(random:uniform(Jitter)).
