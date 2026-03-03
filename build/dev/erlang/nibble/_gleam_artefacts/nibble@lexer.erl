-module(nibble@lexer).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([simple/1, advanced/1, keep/1, drop/1, custom/1, map/2, then/2, into/2, ignore/1, token/2, symbol/3, keyword/3, string/2, identifier/4, try_identifier/4, variable/2, spaces_/1, spaces/1, whitespace/1, comment/2, run/2, run_advanced/3, float_with_separator/2, float/1, int_with_separator/2, int/1, number_with_separator/3, number/2]).
-export_type([matcher/2, match/2, token/1, span/0, error/0, lexer/2, state/1]).

-opaque matcher(MRO, MRP) :: {matcher,
        fun((MRP, binary(), binary()) -> match(MRO, MRP))}.

-type match(MRQ, MRR) :: {keep, MRQ, MRR} | skip | {drop, MRR} | no_match.

-type token(MRS) :: {token, span(), binary(), MRS}.

-type span() :: {span, integer(), integer(), integer(), integer()}.

-type error() :: {no_match_found, integer(), integer(), binary()}.

-opaque lexer(MRT, MRU) :: {lexer, fun((MRU) -> list(matcher(MRT, MRU)))}.

-type state(MRV) :: {state,
        list(binary()),
        list(token(MRV)),
        {integer(), integer(), binary()},
        integer(),
        integer()}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 108).
-spec simple(list(matcher(MRW, nil))) -> lexer(MRW, nil).
simple(Matchers) ->
    {lexer, fun(_) -> Matchers end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 116).
-spec advanced(fun((MSC) -> list(matcher(MSD, MSC)))) -> lexer(MSD, MSC).
advanced(Matchers) ->
    {lexer, fun(Mode) -> Matchers(Mode) end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 130).
-spec keep(fun((binary(), binary()) -> {ok, MSJ} | {error, nil})) -> matcher(MSJ, any()).
keep(F) ->
    {matcher, fun(Mode, Lexeme, Lookahead) -> _pipe = F(Lexeme, Lookahead),
            _pipe@1 = gleam@result:map(
                _pipe,
                fun(_capture) -> {keep, _capture, Mode} end
            ),
            gleam@result:unwrap(_pipe@1, no_match) end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 146).
-spec drop(fun((binary(), binary()) -> boolean())) -> matcher(any(), any()).
drop(F) ->
    {matcher, fun(Mode, Lexeme, Lookahead) -> case F(Lexeme, Lookahead) of
                true ->
                    {drop, Mode};

                false ->
                    no_match
            end end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 161).
-spec custom(fun((MST, binary(), binary()) -> match(MSU, MST))) -> matcher(MSU, MST).
custom(F) ->
    {matcher, F}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 168).
-spec map(matcher(MSZ, MTA), fun((MSZ) -> MTD)) -> matcher(MTD, MTA).
map(Matcher, F) ->
    {matcher,
        fun(Mode, Lexeme, Lookahead) ->
            case (erlang:element(2, Matcher))(Mode, Lexeme, Lookahead) of
                {keep, Value, Mode@1} ->
                    {keep, F(Value), Mode@1};

                skip ->
                    skip;

                {drop, Mode@2} ->
                    {drop, Mode@2};

                no_match ->
                    no_match
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 184).
-spec then(matcher(MTG, MTH), fun((MTG) -> match(MTK, MTH))) -> matcher(MTK, MTH).
then(Matcher, F) ->
    {matcher,
        fun(Mode, Lexeme, Lookahead) ->
            case (erlang:element(2, Matcher))(Mode, Lexeme, Lookahead) of
                {keep, Value, _} ->
                    F(Value);

                skip ->
                    skip;

                {drop, Mode@1} ->
                    {drop, Mode@1};

                no_match ->
                    no_match
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 202).
-spec into(matcher(MTP, MTQ), fun((MTQ) -> MTQ)) -> matcher(MTP, MTQ).
into(Matcher, F) ->
    {matcher,
        fun(Mode, Lexeme, Lookahead) ->
            case (erlang:element(2, Matcher))(Mode, Lexeme, Lookahead) of
                {keep, Value, Mode@1} ->
                    {keep, Value, F(Mode@1)};

                skip ->
                    skip;

                {drop, Mode@2} ->
                    {drop, F(Mode@2)};

                no_match ->
                    no_match
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 217).
-spec ignore(matcher(any(), MTW)) -> matcher(any(), MTW).
ignore(Matcher) ->
    {matcher,
        fun(Mode, Lexeme, Lookahead) ->
            case (erlang:element(2, Matcher))(Mode, Lexeme, Lookahead) of
                {keep, _, Mode@1} ->
                    {drop, Mode@1};

                skip ->
                    skip;

                {drop, Mode@2} ->
                    {drop, Mode@2};

                no_match ->
                    no_match
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 232).
-spec token(binary(), MUC) -> matcher(MUC, any()).
token(Str, Value) ->
    {matcher, fun(Mode, Lexeme, _) -> case Lexeme =:= Str of
                true ->
                    {keep, Value, Mode};

                false ->
                    no_match
            end end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 245).
-spec symbol(binary(), binary(), MUG) -> matcher(MUG, any()).
symbol(Str, Breaker, Value) ->
    _assert_subject = gleam@regex:from_string(Breaker),
    {ok, Break} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"symbol"/utf8>>,
                        line => 246})
    end,
    {matcher,
        fun(Mode, Lexeme, Lookahead) ->
            case (Lexeme =:= Str) andalso ((Lookahead =:= <<""/utf8>>) orelse gleam@regex:check(
                Break,
                Lookahead
            )) of
                true ->
                    {keep, Value, Mode};

                false ->
                    no_match
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 261).
-spec keyword(binary(), binary(), MUK) -> matcher(MUK, any()).
keyword(Str, Breaker, Value) ->
    _assert_subject = gleam@regex:from_string(Breaker),
    {ok, Break} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"keyword"/utf8>>,
                        line => 262})
    end,
    {matcher,
        fun(Mode, Lexeme, Lookahead) ->
            case (Lexeme =:= Str) andalso ((Lookahead =:= <<""/utf8>>) orelse gleam@regex:check(
                Break,
                Lookahead
            )) of
                true ->
                    {keep, Value, Mode};

                false ->
                    no_match
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 388).
-spec string(binary(), fun((binary()) -> MVM)) -> matcher(MVM, any()).
string(Char, To_value) ->
    _assert_subject = gleam@regex:from_string(
        <<<<<<<<<<<<"^"/utf8, Char/binary>>/binary, "([^"/utf8>>/binary,
                        Char/binary>>/binary,
                    "\\\\]|\\\\[\\s\\S])*"/utf8>>/binary,
                Char/binary>>/binary,
            "$"/utf8>>
    ),
    {ok, Is_string} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"string"/utf8>>,
                        line => 389})
    end,
    {matcher,
        fun(Mode, Lexeme, _) -> case gleam@regex:check(Is_string, Lexeme) of
                true ->
                    _pipe = Lexeme,
                    _pipe@1 = gleam@string:drop_left(_pipe, 1),
                    _pipe@2 = gleam@string:drop_right(_pipe@1, 1),
                    _pipe@3 = To_value(_pipe@2),
                    {keep, _pipe@3, Mode};

                false ->
                    no_match
            end end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 408).
-spec identifier(
    binary(),
    binary(),
    gleam@set:set(binary()),
    fun((binary()) -> MVR)
) -> matcher(MVR, any()).
identifier(Start, Inner, Reserved, To_value) ->
    _assert_subject = gleam@regex:from_string(
        <<<<<<"^"/utf8, Start/binary>>/binary, Inner/binary>>/binary,
            "*$"/utf8>>
    ),
    {ok, Ident} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"identifier"/utf8>>,
                        line => 414})
    end,
    _assert_subject@1 = gleam@regex:from_string(Inner),
    {ok, Inner@1} = case _assert_subject@1 of
        {ok, _} -> _assert_subject@1;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail@1,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"identifier"/utf8>>,
                        line => 415})
    end,
    {matcher,
        fun(Mode, Lexeme, Lookahead) ->
            case {gleam@regex:check(Inner@1, Lookahead),
                gleam@regex:check(Ident, Lexeme)} of
                {true, true} ->
                    skip;

                {false, true} ->
                    case gleam@set:contains(Reserved, Lexeme) of
                        true ->
                            no_match;

                        false ->
                            {keep, To_value(Lexeme), Mode}
                    end;

                {_, _} ->
                    no_match
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 432).
-spec try_identifier(
    binary(),
    binary(),
    gleam@set:set(binary()),
    fun((binary()) -> MVW)
) -> {ok, matcher(MVW, any())} | {error, gleam@regex:compile_error()}.
try_identifier(Start, Inner, Reserved, To_value) ->
    gleam@result:then(
        gleam@regex:from_string(
            <<<<<<"^"/utf8, Start/binary>>/binary, Inner/binary>>/binary,
                "*$"/utf8>>
        ),
        fun(Ident) ->
            gleam@result:map(
                gleam@regex:from_string(Inner),
                fun(Inner@1) ->
                    {matcher,
                        fun(Mode, Lexeme, Lookahead) ->
                            case {gleam@regex:check(Inner@1, Lookahead),
                                gleam@regex:check(Ident, Lexeme)} of
                                {true, true} ->
                                    skip;

                                {false, true} ->
                                    case gleam@set:contains(Reserved, Lexeme) of
                                        true ->
                                            no_match;

                                        false ->
                                            {keep, To_value(Lexeme), Mode}
                                    end;

                                {_, _} ->
                                    no_match
                            end
                        end}
                end
            )
        end
    ).

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 456).
-spec variable(gleam@set:set(binary()), fun((binary()) -> MWD)) -> matcher(MWD, any()).
variable(Reserved, To_value) ->
    identifier(<<"[a-z]"/utf8>>, <<"[a-zA-Z0-9_]"/utf8>>, Reserved, To_value).

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 471).
-spec spaces_(fun((binary()) -> MWL)) -> matcher(MWL, any()).
spaces_(To_value) ->
    _assert_subject = gleam@regex:from_string(<<"^[ \\t]+"/utf8>>),
    {ok, Spaces} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"spaces_"/utf8>>,
                        line => 472})
    end,
    {matcher, fun(Mode, Lexeme, _) -> case gleam@regex:check(Spaces, Lexeme) of
                true ->
                    {keep, To_value(Lexeme), Mode};

                false ->
                    no_match
            end end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 465).
-spec spaces(MWH) -> matcher(MWH, any()).
spaces(Token) ->
    spaces_(gleam@function:constant(Token)).

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 484).
-spec whitespace(MWP) -> matcher(MWP, any()).
whitespace(Token) ->
    _assert_subject = gleam@regex:from_string(<<"^\\s+$"/utf8>>),
    {ok, Whitespace} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"whitespace"/utf8>>,
                        line => 485})
    end,
    {matcher,
        fun(Mode, Lexeme, _) -> case gleam@regex:check(Whitespace, Lexeme) of
                true ->
                    {keep, Token, Mode};

                false ->
                    no_match
            end end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 496).
-spec comment(binary(), fun((binary()) -> MWT)) -> matcher(MWT, any()).
comment(Start, To_value) ->
    Drop_length = gleam@string:length(Start),
    {matcher,
        fun(Mode, Lexeme, Lookahead) ->
            case {gleam@string:starts_with(Lexeme, Start), Lookahead} of
                {true, <<"\n"/utf8>>} ->
                    _pipe = Lexeme,
                    _pipe@1 = gleam@string:drop_left(_pipe, Drop_length),
                    _pipe@2 = To_value(_pipe@1),
                    {keep, _pipe@2, Mode};

                {true, _} ->
                    skip;

                {false, _} ->
                    no_match
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 643).
-spec do_match(MXV, binary(), binary(), list(matcher(MXW, MXV))) -> match(MXW, MXV).
do_match(Mode, Str, Lookahead, Matchers) ->
    gleam@list:fold_until(
        Matchers,
        no_match,
        fun(_, Matcher) ->
            case (erlang:element(2, Matcher))(Mode, Str, Lookahead) of
                {keep, _, _} = Match ->
                    {stop, Match};

                skip ->
                    {stop, skip};

                {drop, _} = Match@1 ->
                    {stop, Match@1};

                no_match ->
                    {continue, no_match}
            end
        end
    ).

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 661).
-spec next_col(integer(), binary()) -> integer().
next_col(Col, Str) ->
    case Str of
        <<"\n"/utf8>> ->
            1;

        _ ->
            Col + 1
    end.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 668).
-spec next_row(integer(), binary()) -> integer().
next_row(Row, Str) ->
    case Str of
        <<"\n"/utf8>> ->
            Row + 1;

        _ ->
            Row
    end.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 534).
-spec do_run(lexer(MXM, MXN), MXN, state(MXM)) -> {ok, list(token(MXM))} |
    {error, error()}.
do_run(Lexer, Mode, State) ->
    Matchers = (erlang:element(2, Lexer))(Mode),
    case {erlang:element(2, State), erlang:element(4, State)} of
        {[], {_, _, <<""/utf8>>}} ->
            {ok, lists:reverse(erlang:element(3, State))};

        {[], {Start_row, Start_col, Lexeme}} ->
            case do_match(Mode, Lexeme, <<""/utf8>>, Matchers) of
                no_match ->
                    {error, {no_match_found, Start_row, Start_col, Lexeme}};

                skip ->
                    {error, {no_match_found, Start_row, Start_col, Lexeme}};

                {drop, _} ->
                    {ok, lists:reverse(erlang:element(3, State))};

                {keep, Value, _} ->
                    Span = {span,
                        Start_row,
                        Start_col,
                        erlang:element(5, State),
                        erlang:element(6, State)},
                    Token = {token, Span, Lexeme, Value},
                    {ok, lists:reverse([Token | erlang:element(3, State)])}
            end;

        {[Lookahead | Rest], {Start_row@1, Start_col@1, Lexeme@1}} ->
            Row = next_row(erlang:element(5, State), Lookahead),
            Col = next_col(erlang:element(6, State), Lookahead),
            case do_match(Mode, Lexeme@1, Lookahead, Matchers) of
                {keep, Value@1, Mode@1} ->
                    Span@1 = {span,
                        Start_row@1,
                        Start_col@1,
                        erlang:element(5, State),
                        erlang:element(6, State)},
                    Token@1 = {token, Span@1, Lexeme@1, Value@1},
                    do_run(
                        Lexer,
                        Mode@1,
                        {state,
                            Rest,
                            [Token@1 | erlang:element(3, State)],
                            {erlang:element(5, State),
                                erlang:element(6, State),
                                Lookahead},
                            Row,
                            Col}
                    );

                skip ->
                    do_run(
                        Lexer,
                        Mode,
                        {state,
                            Rest,
                            erlang:element(3, State),
                            {Start_row@1,
                                Start_col@1,
                                <<Lexeme@1/binary, Lookahead/binary>>},
                            Row,
                            Col}
                    );

                {drop, Mode@2} ->
                    do_run(
                        Lexer,
                        Mode@2,
                        {state,
                            Rest,
                            erlang:element(3, State),
                            {erlang:element(5, State),
                                erlang:element(6, State),
                                Lookahead},
                            Row,
                            Col}
                    );

                no_match ->
                    do_run(
                        Lexer,
                        Mode,
                        {state,
                            Rest,
                            erlang:element(3, State),
                            {Start_row@1,
                                Start_col@1,
                                <<Lexeme@1/binary, Lookahead/binary>>},
                            Row,
                            Col}
                    )
            end
    end.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 515).
-spec run(binary(), lexer(MWX, nil)) -> {ok, list(token(MWX))} |
    {error, error()}.
run(Source, Lexer) ->
    _pipe = gleam@string:to_graphemes(Source),
    _pipe@1 = {state, _pipe, [], {1, 1, <<""/utf8>>}, 1, 1},
    do_run(Lexer, nil, _pipe@1).

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 526).
-spec run_advanced(binary(), MXE, lexer(MXF, MXE)) -> {ok, list(token(MXF))} |
    {error, error()}.
run_advanced(Source, Mode, Lexer) ->
    do_run(
        Lexer,
        Mode,
        {state,
            gleam@string:to_graphemes(Source),
            [],
            {1, 1, <<""/utf8>>},
            1,
            1}
    ).

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 309).
-spec float_with_separator(binary(), fun((float()) -> MVA)) -> matcher(MVA, any()).
float_with_separator(Separator, To_value) ->
    _assert_subject = gleam@regex:from_string(
        <<<<"[0-9"/utf8, Separator/binary>>/binary, "]"/utf8>>
    ),
    {ok, Digit} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"float_with_separator"/utf8>>,
                        line => 313})
    end,
    _assert_subject@1 = gleam@regex:from_string(
        <<<<"^-*[0-9"/utf8, Separator/binary>>/binary, "]+$"/utf8>>
    ),
    {ok, Integer} = case _assert_subject@1 of
        {ok, _} -> _assert_subject@1;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail@1,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"float_with_separator"/utf8>>,
                        line => 314})
    end,
    _assert_subject@2 = gleam@regex:from_string(
        <<<<<<<<"^-*[0-9"/utf8, Separator/binary>>/binary, "]+\\.[0-9"/utf8>>/binary,
                Separator/binary>>/binary,
            "]+$"/utf8>>
    ),
    {ok, Number} = case _assert_subject@2 of
        {ok, _} -> _assert_subject@2;
        _assert_fail@2 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail@2,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"float_with_separator"/utf8>>,
                        line => 315})
    end,
    {matcher,
        fun(Mode, Lexeme, Lookahead) ->
            Is_int = not gleam@regex:check(Digit, Lookahead) andalso gleam@regex:check(
                Integer,
                Lexeme
            ),
            Is_float = not gleam@regex:check(Digit, Lookahead) andalso gleam@regex:check(
                Number,
                Lexeme
            ),
            case Lexeme of
                <<"."/utf8>> when Is_int ->
                    no_match;

                _ when Is_float ->
                    _assert_subject@3 = begin
                        _pipe = Lexeme,
                        _pipe@1 = gleam@string:replace(
                            _pipe,
                            Separator,
                            <<""/utf8>>
                        ),
                        gleam@float:parse(_pipe@1)
                    end,
                    {ok, Num} = case _assert_subject@3 of
                        {ok, _} -> _assert_subject@3;
                        _assert_fail@3 ->
                            erlang:error(#{gleam_error => let_assert,
                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                        value => _assert_fail@3,
                                        module => <<"nibble/lexer"/utf8>>,
                                        function => <<"float_with_separator"/utf8>>,
                                        line => 328})
                    end,
                    {keep, To_value(Num), Mode};

                _ ->
                    no_match
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 303).
-spec float(fun((float()) -> MUW)) -> matcher(MUW, any()).
float(To_value) ->
    float_with_separator(<<""/utf8>>, To_value).

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 280).
-spec int_with_separator(binary(), fun((integer()) -> MUS)) -> matcher(MUS, any()).
int_with_separator(Separator, To_value) ->
    _assert_subject = gleam@regex:from_string(
        <<<<"[0-9"/utf8, Separator/binary>>/binary, "]"/utf8>>
    ),
    {ok, Digit} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"int_with_separator"/utf8>>,
                        line => 284})
    end,
    _assert_subject@1 = gleam@regex:from_string(
        <<<<"^-*[0-9"/utf8, Separator/binary>>/binary, "]+$"/utf8>>
    ),
    {ok, Integer} = case _assert_subject@1 of
        {ok, _} -> _assert_subject@1;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail@1,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"int_with_separator"/utf8>>,
                        line => 285})
    end,
    {matcher,
        fun(Mode, Lexeme, Lookahead) ->
            case not gleam@regex:check(Digit, Lookahead) andalso gleam@regex:check(
                Integer,
                Lexeme
            ) of
                false ->
                    no_match;

                true ->
                    _assert_subject@2 = begin
                        _pipe = Lexeme,
                        _pipe@1 = gleam@string:replace(
                            _pipe,
                            Separator,
                            <<""/utf8>>
                        ),
                        gleam@int:parse(_pipe@1)
                    end,
                    {ok, Num} = case _assert_subject@2 of
                        {ok, _} -> _assert_subject@2;
                        _assert_fail@2 ->
                            erlang:error(#{gleam_error => let_assert,
                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                        value => _assert_fail@2,
                                        module => <<"nibble/lexer"/utf8>>,
                                        function => <<"int_with_separator"/utf8>>,
                                        line => 292})
                    end,
                    {keep, To_value(Num), Mode}
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 274).
-spec int(fun((integer()) -> MUO)) -> matcher(MUO, any()).
int(To_value) ->
    int_with_separator(<<""/utf8>>, To_value).

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 346).
-spec number_with_separator(
    binary(),
    fun((integer()) -> MVI),
    fun((float()) -> MVI)
) -> matcher(MVI, any()).
number_with_separator(Separator, From_int, From_float) ->
    _assert_subject = gleam@regex:from_string(
        <<<<"[0-9"/utf8, Separator/binary>>/binary, "]"/utf8>>
    ),
    {ok, Digit} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"number_with_separator"/utf8>>,
                        line => 351})
    end,
    _assert_subject@1 = gleam@regex:from_string(
        <<<<"^-*[0-9"/utf8, Separator/binary>>/binary, "]+$"/utf8>>
    ),
    {ok, Integer} = case _assert_subject@1 of
        {ok, _} -> _assert_subject@1;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail@1,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"number_with_separator"/utf8>>,
                        line => 352})
    end,
    _assert_subject@2 = gleam@regex:from_string(
        <<<<<<<<"^-*[0-9"/utf8, Separator/binary>>/binary, "]+\\.[0-9"/utf8>>/binary,
                Separator/binary>>/binary,
            "]+$"/utf8>>
    ),
    {ok, Number} = case _assert_subject@2 of
        {ok, _} -> _assert_subject@2;
        _assert_fail@2 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail@2,
                        module => <<"nibble/lexer"/utf8>>,
                        function => <<"number_with_separator"/utf8>>,
                        line => 353})
    end,
    {matcher,
        fun(Mode, Lexeme, Lookahead) ->
            Is_int = not gleam@regex:check(Digit, Lookahead) andalso gleam@regex:check(
                Integer,
                Lexeme
            ),
            Is_float = not gleam@regex:check(Digit, Lookahead) andalso gleam@regex:check(
                Number,
                Lexeme
            ),
            case {Lexeme, Lookahead} of
                {<<"."/utf8>>, _} when Is_int ->
                    no_match;

                {_, <<"."/utf8>>} when Is_int ->
                    no_match;

                {_, _} when Is_int ->
                    _assert_subject@3 = begin
                        _pipe = Lexeme,
                        _pipe@1 = gleam@string:replace(
                            _pipe,
                            Separator,
                            <<""/utf8>>
                        ),
                        gleam@int:parse(_pipe@1)
                    end,
                    {ok, Num} = case _assert_subject@3 of
                        {ok, _} -> _assert_subject@3;
                        _assert_fail@3 ->
                            erlang:error(#{gleam_error => let_assert,
                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                        value => _assert_fail@3,
                                        module => <<"nibble/lexer"/utf8>>,
                                        function => <<"number_with_separator"/utf8>>,
                                        line => 367})
                    end,
                    {keep, From_int(Num), Mode};

                {_, _} when Is_float ->
                    _assert_subject@4 = begin
                        _pipe@2 = Lexeme,
                        _pipe@3 = gleam@string:replace(
                            _pipe@2,
                            Separator,
                            <<""/utf8>>
                        ),
                        gleam@float:parse(_pipe@3)
                    end,
                    {ok, Num@1} = case _assert_subject@4 of
                        {ok, _} -> _assert_subject@4;
                        _assert_fail@4 ->
                            erlang:error(#{gleam_error => let_assert,
                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                        value => _assert_fail@4,
                                        module => <<"nibble/lexer"/utf8>>,
                                        function => <<"number_with_separator"/utf8>>,
                                        line => 375})
                    end,
                    {keep, From_float(Num@1), Mode};

                {_, _} ->
                    no_match
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble/lexer.gleam", 339).
-spec number(fun((integer()) -> MVE), fun((float()) -> MVE)) -> matcher(MVE, any()).
number(From_int, From_float) ->
    number_with_separator(<<""/utf8>>, From_int, From_float).
