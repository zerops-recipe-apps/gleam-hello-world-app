-module(glenvy@dotenv).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([read_from/1, load_from/1, load/0]).
-export_type([error/0]).

-type error() :: {io, simplifile:file_error()}.

-file("/var/www/build/packages/glenvy/src/glenvy/dotenv.gleam", 47).
-spec find(binary()) -> {ok, binary()} | {error, error()}.
find(Filepath) ->
    gleam@result:'try'(
        begin
            _pipe = simplifile:read(Filepath),
            gleam@result:map_error(_pipe, fun(Field@0) -> {io, Field@0} end)
        end,
        fun(Contents) -> {ok, Contents} end
    ).

-file("/var/www/build/packages/glenvy/src/glenvy/dotenv.gleam", 37).
-spec read_from(binary()) -> {ok, gleam@dict:dict(binary(), binary())} |
    {error, error()}.
read_from(Filepath) ->
    gleam@result:'try'(
        find(Filepath),
        fun(Env_file) ->
            Env_vars = begin
                _pipe = Env_file,
                glenvy@internal@parser:parse_env_file(_pipe)
            end,
            {ok, Env_vars}
        end
    ).

-file("/var/www/build/packages/glenvy/src/glenvy/dotenv.gleam", 22).
-spec load_from(binary()) -> {ok, nil} | {error, error()}.
load_from(Filepath) ->
    gleam@result:'try'(
        read_from(Filepath),
        fun(Env_vars) ->
            _pipe = Env_vars,
            _pipe@1 = maps:to_list(_pipe),
            gleam@list:each(
                _pipe@1,
                fun(Env_var) ->
                    {Key, Value} = Env_var,
                    glenvy@internal@os:set_env(Key, Value)
                end
            ),
            {ok, nil}
        end
    ).

-file("/var/www/build/packages/glenvy/src/glenvy/dotenv.gleam", 17).
-spec load() -> {ok, nil} | {error, error()}.
load() ->
    load_from(<<".env"/utf8>>).
