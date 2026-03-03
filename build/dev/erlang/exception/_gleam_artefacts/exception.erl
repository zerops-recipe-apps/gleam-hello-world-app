-module(exception).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([rescue/1, defer/2]).
-export_type([exception/0]).

-type exception() :: {errored, gleam@dynamic:dynamic_()} |
    {thrown, gleam@dynamic:dynamic_()} |
    {exited, gleam@dynamic:dynamic_()}.

-file("/var/www/build/packages/exception/src/exception.gleam", 29).
-spec rescue(fun(() -> HZL)) -> {ok, HZL} | {error, exception()}.
rescue(Body) ->
    exception_ffi:rescue(Body).

-file("/var/www/build/packages/exception/src/exception.gleam", 51).
-spec defer(fun(() -> any()), fun(() -> HZP)) -> HZP.
defer(Cleanup, Body) ->
    exception_ffi:defer(Cleanup, Body).
