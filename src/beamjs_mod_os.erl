-module(beamjs_mod_os).
-export([exports/1,init/1]).
-behaviour(erlv8_module).
-include_lib("erlv8/include/erlv8.hrl").

%% Operating System Specific Functions

init(_VM) ->
	ok.

exports(_VM) ->
	?V8Obj([
			{"cmd", erlv8_fun:new(fun cmd/2,
					?V8Obj([{"__doc__",
						"`cmd(name)` -> String\n\n"
						"Executes Command in a command shell of the target OS,"
						"captures the standard output of the command and returns this result as a string."}]))},
			{"find_executable", erlv8_fun:new(fun find_executable/2,
					?V8Obj([{"__doc__",
						"`find_executable(name[, path])` -> String\n\n"
						"These function look up an executable program given its name and a search path, in the same way as the underlying operating system.\n\n"
						"The absolute filename of the executable program Name is returned, or false if the program was not found."}]))},
			{"getenv", erlv8_fun:new(fun getenv/2,
					?V8Obj([{"__doc__",
						"`getenv(varname)` -> String\n\n"
						"Returns the Value of the environment variable VarName.\n\n"
						"Returns `false` if the environment variable is undefined."}]))},
			{"putenv", erlv8_fun:new(fun putenv/2,
					?V8Obj([{"__doc__",
						"`putenv(varname, value)` -> true\n\n"
						"Sets a new Value for the environment variable VarName."}]))},
			{"type", erlv8_fun:new(fun type/2,
					?V8Obj([{"__doc__",
						"`type()` -> [unix, linux]\n\n"
						"Returns the Osfamily and, in some cases, Osname of the current operating system."}]))},
			{"version", erlv8_fun:new(fun version/2, ?V8Obj([{"__doc__",
						"<code>version()</code> -> [2,6,37] \n\n"
						"Returns the Osfamily and, in some cases, Osname of the current operating system."}]))}
	]).

cmd(#erlv8_fun_invocation{},[Command]) when is_list(Command) ->
	os:cmd(Command).

find_executable(#erlv8_fun_invocation{},[Command, Path]) when is_list(Command) andalso is_list(Path) ->
	os:find_executable(Command, Path);

find_executable(#erlv8_fun_invocation{},[Command]) when is_list(Command) ->
	os:find_executable(Command).


getenv(#erlv8_fun_invocation{},[VarName]) when is_list(VarName) ->
	os:getenv(VarName).

putenv(#erlv8_fun_invocation{},[VarName, Value]) when is_list(VarName) ->
	os:putenv(VarName, Value).

type(#erlv8_fun_invocation{},[]) ->
	{Osfamily, Osname} = os:type(),
	?V8Arr([Osfamily, Osname]).

version(#erlv8_fun_invocation{},[]) ->
	{Major, Minor, Release} = os:version(),
	?V8Arr([Major, Minor, Release]).
