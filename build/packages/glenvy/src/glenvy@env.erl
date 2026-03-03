-module(glenvy@env).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([get_all/0, get_string/1, get/2, get_int/1, get_float/1, get_bool/1]).
-export_type([error/0]).

-type error() :: {not_found, binary()} | {failed_to_parse, binary()}.

-spec get_all() -> gleam@dict:dict(binary(), binary()).
get_all() ->
    glenvy@internal@os:get_all_env().

-spec get_string(binary()) -> {ok, binary()} | {error, error()}.
get_string(Name) ->
    _pipe = glenvy@internal@os:get_env(Name),
    gleam@result:map_error(_pipe, fun(_) -> {not_found, Name} end).

-spec get(binary(), fun((binary()) -> {ok, RYP} | {error, nil})) -> {ok, RYP} |
    {error, error()}.
get(Name, Parse) ->
    gleam@result:'try'(get_string(Name), fun(Value) -> _pipe = Value,
            _pipe@1 = Parse(_pipe),
            gleam@result:map_error(
                _pipe@1,
                fun(_) -> {failed_to_parse, Name} end
            ) end).

-spec get_int(binary()) -> {ok, integer()} | {error, error()}.
get_int(Name) ->
    _pipe = Name,
    get(_pipe, fun gleam@int:parse/1).

-spec get_float(binary()) -> {ok, float()} | {error, error()}.
get_float(Name) ->
    _pipe = Name,
    get(_pipe, fun gleam@float:parse/1).

-spec get_bool(binary()) -> {ok, boolean()} | {error, error()}.
get_bool(Name) ->
    Parse_bool = fun(Value) ->
        Value@1 = begin
            _pipe = Value,
            gleam@string:lowercase(_pipe)
        end,
        case Value@1 of
            <<"true"/utf8>> ->
                {ok, true};

            <<"t"/utf8>> ->
                {ok, true};

            <<"yes"/utf8>> ->
                {ok, true};

            <<"y"/utf8>> ->
                {ok, true};

            <<"1"/utf8>> ->
                {ok, true};

            <<"false"/utf8>> ->
                {ok, false};

            <<"f"/utf8>> ->
                {ok, false};

            <<"no"/utf8>> ->
                {ok, false};

            <<"n"/utf8>> ->
                {ok, false};

            <<"0"/utf8>> ->
                {ok, false};

            _ ->
                {error, nil}
        end
    end,
    _pipe@1 = Name,
    get(_pipe@1, Parse_bool).
