-module(beamjs_mod_events).

-behaviour(erlv8_module).
-export([exports/0, init/1]).

%-behaviour(gen_event). % commented this out just because of init/1 conflict warning
-export([handle_event/2, terminate/2, handle_call/2, handle_info/2, code_change/3]).


-include_lib("erlv8/include/erlv8.hrl").

init({gen_event, Type, Event, Listener}) -> %% gen_event
	{ok, {Type, Event, Listener}};
init(_VM) -> %% erlv8_module
	ok.

	   
exports() ->
	?V8Obj([{"EventEmitter", fun new_event_emitter/2}]).

prototype() ->
	?V8Obj([{"emit", fun emit/2},
			{"addListener", fun add_listener/2},
			{"on", fun add_listener/2},
			{"once", fun once/2},
			{"listeners", fun listeners/2},
			{"removeListener", fun remove_listener/2},
			{"removeAllListeners", fun remove_all_listeners/2}]).

new_event_emitter(#erlv8_fun_invocation{ this = This },[]) ->
	This:set_prototype(prototype()),
	{ok, Pid} = gen_event:start(), %% not sure if we want start or start_link here
	This:set_hidden_value("eventManager", Pid),
	This:set_hidden_value("_listeners",?V8Obj([])),
	undefined.

emit(#erlv8_fun_invocation{ this = This },[Event|Args]) ->
	Pid = This:get_hidden_value("eventManager"),
	gen_event:notify(Pid,{event, Event, Args}),
	undefined.

add_listener(Type, #erlv8_fun_invocation{ this = This },[Event, Listener]) ->
	Pid = This:get_hidden_value("eventManager"),
	Ref = make_ref(),
	gen_event:add_handler(Pid, {?MODULE, {Ref, Event, Listener}}, {gen_event, Type, Event, Listener}),
	Listeners = This:get_hidden_value("_listeners"),
	EventListeners = Listeners:get_value(Event,[]),
	Listeners:set_value(Event,[Listener|EventListeners]),
	undefined.

add_listener(#erlv8_fun_invocation{}=I,Args) ->
	add_listener(normal, I, Args).

once(#erlv8_fun_invocation{}=I,Args) ->
	add_listener(once, I, Args).

listeners(#erlv8_fun_invocation{}, []) ->
	{throw, {error, "Event name should be specified"}};

listeners(#erlv8_fun_invocation{ this = This}, [Event]) -> %% half: the array we return can not be manipulated
	Listeners = This:get_hidden_value("_listeners"),
	Listeners:get_value(Event).

remove_listener(#erlv8_fun_invocation{ this = This}, [Listener]) -> %% broken
	Pid = This:get_hidden_value("eventManager"),
	gen_event:notify(Pid,{remove_listener, Listener}),
	undefined.	

remove_all_listeners(#erlv8_fun_invocation{ this = This },[Event]) ->
	Pid = This:get_hidden_value("eventManager"),
	gen_event:notify(Pid,{remove_all, Event}),
	undefined.


%% gen_event
handle_event({event, Event, Args}, {normal, Event, Listener}=State) ->
	Listener:call(Args),
    {ok, State};

handle_event({event, Event, Args}, {once, Event, Listener}) ->
	Listener:call(Args),
	remove_handler;

handle_event({remove_all, Event}, {_, Event, _}) ->
	remove_handler;

handle_event({remove_listener, Listener}, {_, _, Listener}) ->
	remove_handler;


handle_event(_, State) ->
	{ok, State}.

handle_call(_Req,State) ->
	{ok, ok, State}.

handle_info(_Info,State) ->
	{ok, State}.

terminate(_Args, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.



	