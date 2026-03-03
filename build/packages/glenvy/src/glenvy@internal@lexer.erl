-module(glenvy@internal@lexer).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([tokenize/1, is_newline/1]).
-export_type([token_kind/0]).

-type token_kind() :: equal |
    newline |
    {key, binary()} |
    {value, binary()} |
    export.

-spec lexer() -> nibble@lexer:lexer(token_kind(), nil).
lexer() ->
    Keywords = gleam@set:from_list([<<"export"/utf8>>]),
    Comments = begin
        _pipe = nibble@lexer:comment(<<"#"/utf8>>, fun(_) -> nil end),
        nibble@lexer:ignore(_pipe)
    end,
    Whitespace = begin
        _pipe@1 = nibble@lexer:spaces(nil),
        nibble@lexer:ignore(_pipe@1)
    end,
    nibble@lexer:simple(
        [nibble@lexer:token(<<"="/utf8>>, equal),
            nibble@lexer:token(<<"\n"/utf8>>, newline),
            nibble@lexer:token(<<"\r\n"/utf8>>, newline),
            nibble@lexer:keyword(<<"export"/utf8>>, <<"[\\W\\D]"/utf8>>, export),
            nibble@lexer:identifier(
                <<"[A-Za-z_]"/utf8>>,
                <<"[\\w]"/utf8>>,
                Keywords,
                fun(Field@0) -> {key, Field@0} end
            ),
            nibble@lexer:string(
                <<"\""/utf8>>,
                fun(Field@0) -> {value, Field@0} end
            ),
            nibble@lexer:string(
                <<"'"/utf8>>,
                fun(Field@0) -> {value, Field@0} end
            ),
            nibble@lexer:identifier(
                <<"[^\\s=#\"']"/utf8>>,
                <<"[.]"/utf8>>,
                Keywords,
                fun(Field@0) -> {value, Field@0} end
            ),
            Comments,
            Whitespace]
    ).

-spec tokenize(binary()) -> {ok, list(nibble@lexer:token(token_kind()))} |
    {error, nibble@lexer:error()}.
tokenize(Input) ->
    nibble@lexer:run(Input, lexer()).

-spec is_newline(token_kind()) -> boolean().
is_newline(Token) ->
    Token =:= newline.
