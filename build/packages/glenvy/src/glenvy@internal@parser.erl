-module(glenvy@internal@parser).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([parse_env_file/1]).

-spec key_parser() -> nibble:parser(binary(), glenvy@internal@lexer:token_kind(), any()).
key_parser() ->
    nibble:take_map(<<"KEY"/utf8>>, fun(Token) -> case Token of
                {key, Key} ->
                    {some, Key};

                export ->
                    {some, <<"export"/utf8>>};

                _ ->
                    none
            end end).

-spec exported_key_parser() -> nibble:parser(binary(), glenvy@internal@lexer:token_kind(), any()).
exported_key_parser() ->
    nibble:do(
        nibble:optional(nibble:token(export)),
        fun(Export) -> case Export of
                {some, _} ->
                    _pipe = key_parser(),
                    nibble:'or'(_pipe, <<"export"/utf8>>);

                none ->
                    key_parser()
            end end
    ).

-spec value_parser() -> nibble:parser(binary(), glenvy@internal@lexer:token_kind(), any()).
value_parser() ->
    nibble:do(
        nibble:take_until(fun glenvy@internal@lexer:is_newline/1),
        fun(Tokens) -> _pipe = Tokens,
            _pipe@1 = gleam@list:filter_map(_pipe, fun(Token) -> case Token of
                        {value, Value} ->
                            {ok, Value};

                        {key, Value@1} ->
                            {ok, Value@1};

                        equal ->
                            {ok, <<"="/utf8>>};

                        _ ->
                            {error, nil}
                    end end),
            _pipe@2 = gleam@string:join(_pipe@1, <<""/utf8>>),
            nibble:return(_pipe@2) end
    ).

-spec line_parser(gleam@dict:dict(binary(), binary())) -> nibble:parser(gleam@dict:dict(binary(), binary()), glenvy@internal@lexer:token_kind(), any()).
line_parser(Env_vars) ->
    nibble:do(
        exported_key_parser(),
        fun(Key) ->
            nibble:do(
                nibble:token(equal),
                fun(_) ->
                    nibble:do(
                        value_parser(),
                        fun(Value) ->
                            nibble:do(
                                nibble:one_of(
                                    [nibble:token(newline), nibble:eof()]
                                ),
                                fun(_) -> _pipe = Env_vars,
                                    _pipe@1 = gleam@dict:insert(
                                        _pipe,
                                        Key,
                                        Value
                                    ),
                                    nibble:return(_pipe@1) end
                            )
                        end
                    )
                end
            )
        end
    ).

-spec env_file_parser() -> nibble:parser(gleam@dict:dict(binary(), binary()), glenvy@internal@lexer:token_kind(), any()).
env_file_parser() ->
    nibble:loop(
        gleam@dict:new(),
        fun(Env_vars) ->
            nibble:one_of(
                [begin
                        _pipe = line_parser(Env_vars),
                        nibble:map(
                            _pipe,
                            fun(Field@0) -> {continue, Field@0} end
                        )
                    end,
                    begin
                        _pipe@1 = nibble:many1(nibble:token(newline)),
                        nibble:replace(_pipe@1, {continue, Env_vars})
                    end,
                    begin
                        _pipe@2 = nibble:eof(),
                        nibble:replace(_pipe@2, {break, Env_vars})
                    end]
            )
        end
    ).

-spec try_parse_env_file(binary()) -> {ok, gleam@dict:dict(binary(), binary())} |
    {error, nil}.
try_parse_env_file(Contents) ->
    gleam@result:'try'(
        begin
            _pipe = glenvy@internal@lexer:tokenize(Contents),
            gleam@result:nil_error(_pipe)
        end,
        fun(Tokens) -> _pipe@1 = Tokens,
            _pipe@2 = nibble:run(_pipe@1, env_file_parser()),
            gleam@result:nil_error(_pipe@2) end
    ).

-spec parse_env_file(binary()) -> gleam@dict:dict(binary(), binary()).
parse_env_file(Contents) ->
    _pipe = Contents,
    _pipe@1 = try_parse_env_file(_pipe),
    gleam@result:unwrap(_pipe@1, gleam@dict:new()).
