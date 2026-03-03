-module(glenvy@internal@os).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([get_all_env/0, get_env/1, set_env/2, unset_env/1]).

-spec get_all_env() -> gleam@dict:dict(binary(), binary()).
get_all_env() ->
    gleam_erlang_ffi:get_all_env().

-spec get_env(binary()) -> {ok, binary()} | {error, nil}.
get_env(Name) ->
    gleam_erlang_ffi:get_env(Name).

-spec set_env(binary(), binary()) -> nil.
set_env(Name, Value) ->
    gleam_erlang_ffi:set_env(Name, Value).

-spec unset_env(binary()) -> nil.
unset_env(Name) ->
    gleam_erlang_ffi:unset_env(Name).
