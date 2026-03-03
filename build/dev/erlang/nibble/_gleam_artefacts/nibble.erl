-module(nibble).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([return/1, succeed/1, lazy/1, backtrackable/1, do/2, then/2, map/2, replace/2, span/0, loop/2, take_while/1, take_until/1, take_exactly/2, take_map_while/1, throw/1, fail/1, token/1, eof/0, guard/2, take_if/2, any/0, take_while1/2, take_until1/2, take_map/2, take_map_while1/2, run/2, one_of/1, sequence/2, many/1, many1/1, take_at_least/2, 'or'/2, take_up_to/2, optional/1, in/2, do_in/3, inspect/2]).
-export_type([parser/3, step/3, state/2, can_backtrack/0, loop/2, error/1, dead_end/2, bag/2]).

-opaque parser(NQL, NQM, NQN) :: {parser,
        fun((state(NQM, NQN)) -> step(NQL, NQM, NQN))}.

-type step(NQO, NQP, NQQ) :: {cont, can_backtrack(), NQO, state(NQP, NQQ)} |
    {fail, can_backtrack(), bag(NQP, NQQ)}.

-type state(NQR, NQS) :: {state,
        gleam@dict:dict(integer(), nibble@lexer:token(NQR)),
        integer(),
        nibble@lexer:span(),
        list({nibble@lexer:span(), NQS})}.

-type can_backtrack() :: {can_backtrack, boolean()}.

-type loop(NQT, NQU) :: {continue, NQU} | {break, NQT}.

-type error(NQV) :: {bad_parser, binary()} |
    {custom, binary()} |
    end_of_input |
    {expected, binary(), NQV} |
    {unexpected, NQV}.

-type dead_end(NQW, NQX) :: {dead_end,
        nibble@lexer:span(),
        error(NQW),
        list({nibble@lexer:span(), NQX})}.

-type bag(NQY, NQZ) :: empty |
    {cons, bag(NQY, NQZ), dead_end(NQY, NQZ)} |
    {append, bag(NQY, NQZ), bag(NQY, NQZ)}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 93).
-spec runwrap(state(NRN, NRO), parser(NRR, NRN, NRO)) -> step(NRR, NRN, NRO).
runwrap(State, Parser) ->
    {parser, Parse} = Parser,
    Parse(State).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 101).
-spec next(state(NRY, NRZ)) -> {gleam@option:option(NRY), state(NRY, NRZ)}.
next(State) ->
    case gleam@dict:get(erlang:element(2, State), erlang:element(3, State)) of
        {error, _} ->
            {none, State};

        {ok, {token, Span, _, Tok}} ->
            {{some, Tok},
                erlang:setelement(
                    4,
                    erlang:setelement(3, State, erlang:element(3, State) + 1),
                    Span
                )}
    end.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 141).
-spec return(NSF) -> parser(NSF, any(), any()).
return(Value) ->
    {parser, fun(State) -> {cont, {can_backtrack, false}, Value, State} end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 172).
-spec succeed(NSL) -> parser(NSL, any(), any()).
succeed(Value) ->
    return(Value).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 197).
-spec lazy(fun(() -> parser(NTD, NTE, NTF))) -> parser(NTD, NTE, NTF).
lazy(Parser) ->
    {parser, fun(State) -> runwrap(State, Parser()) end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 222).
-spec backtrackable(parser(NTM, NTN, NTO)) -> parser(NTM, NTN, NTO).
backtrackable(Parser) ->
    {parser, fun(State) -> case runwrap(State, Parser) of
                {cont, _, A, State@1} ->
                    {cont, {can_backtrack, false}, A, State@1};

                {fail, _, Bag} ->
                    {fail, {can_backtrack, false}, Bag}
            end end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 231).
-spec should_commit(can_backtrack(), can_backtrack()) -> can_backtrack().
should_commit(A, B) ->
    {can_backtrack, A@1} = A,
    {can_backtrack, B@1} = B,
    {can_backtrack, A@1 orelse B@1}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 242).
-spec do(parser(NTV, NTW, NTX), fun((NTV) -> parser(NUB, NTW, NTX))) -> parser(NUB, NTW, NTX).
do(Parser, F) ->
    {parser, fun(State) -> case runwrap(State, Parser) of
                {cont, To_a, A, State@1} ->
                    case runwrap(State@1, F(A)) of
                        {cont, To_b, B, State@2} ->
                            {cont, should_commit(To_a, To_b), B, State@2};

                        {fail, To_b@1, Bag} ->
                            {fail, should_commit(To_a, To_b@1), Bag}
                    end;

                {fail, Can_backtrack, Bag@1} ->
                    {fail, Can_backtrack, Bag@1}
            end end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 271).
-spec then(parser(NUV, NUW, NUX), fun((NUV) -> parser(NVB, NUW, NUX))) -> parser(NVB, NUW, NUX).
then(Parser, F) ->
    do(Parser, F).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 280).
-spec map(parser(NVI, NVJ, NVK), fun((NVI) -> NVO)) -> parser(NVO, NVJ, NVK).
map(Parser, F) ->
    do(Parser, fun(A) -> return(F(A)) end).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 288).
-spec replace(parser(any(), NVT, NVU), NVY) -> parser(NVY, NVT, NVU).
replace(Parser, B) ->
    map(Parser, fun(_) -> B end).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 296).
-spec span() -> parser(nibble@lexer:span(), any(), any()).
span() ->
    {parser,
        fun(State) ->
            {cont, {can_backtrack, false}, erlang:element(4, State), State}
        end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 424).
-spec loop_help(
    fun((OMM) -> parser(loop(OMV, OMM), OMQ, OMR)),
    can_backtrack(),
    OMM,
    state(OMQ, OMR)
) -> step(OMV, OMQ, OMR).
loop_help(F, Commit, Loop_state, State) ->
    case runwrap(State, F(Loop_state)) of
        {cont, Can_backtrack, {continue, Next_loop_state}, Next_state} ->
            loop_help(
                F,
                should_commit(Commit, Can_backtrack),
                Next_loop_state,
                Next_state
            );

        {cont, Can_backtrack@1, {break, Result}, Next_state@1} ->
            {cont, should_commit(Commit, Can_backtrack@1), Result, Next_state@1};

        {fail, Can_backtrack@2, Bag} ->
            {fail, should_commit(Commit, Can_backtrack@2), Bag}
    end.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 415).
-spec loop(NZC, fun((NZC) -> parser(loop(NZD, NZC), NZG, NZH))) -> parser(NZD, NZG, NZH).
loop(Init, Step) ->
    {parser,
        fun(State) -> loop_help(Step, {can_backtrack, false}, Init, State) end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 477).
-spec take_while(fun((OAD) -> boolean())) -> parser(list(OAD), OAD, any()).
take_while(Predicate) ->
    {parser,
        fun(State) ->
            {Tok, Next_state} = next(State),
            case {Tok, gleam@option:map(Tok, Predicate)} of
                {{some, Tok@1}, {some, true}} ->
                    runwrap(
                        Next_state,
                        (do(
                            take_while(Predicate),
                            fun(Toks) -> return([Tok@1 | Toks]) end
                        ))
                    );

                {{some, _}, {some, false}} ->
                    {cont, {can_backtrack, false}, [], State};

                {_, _} ->
                    {cont, {can_backtrack, false}, [], State}
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 509).
-spec take_until(fun((OAP) -> boolean())) -> parser(list(OAP), OAP, any()).
take_until(Predicate) ->
    take_while(fun(Tok) -> gleam@bool:negate(Predicate(Tok)) end).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 563).
-spec take_exactly(parser(OBV, OBW, OBX), integer()) -> parser(list(OBV), OBW, OBX).
take_exactly(Parser, Count) ->
    case Count of
        0 ->
            return([]);

        _ ->
            do(
                Parser,
                fun(X) ->
                    do(
                        take_exactly(Parser, Count - 1),
                        fun(Xs) -> return([X | Xs]) end
                    )
                end
            )
    end.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 617).
-spec take_map_while(fun((ODF) -> gleam@option:option(ODG))) -> parser(list(ODG), ODF, any()).
take_map_while(F) ->
    {parser,
        fun(State) ->
            {Tok, Next_state} = next(State),
            case {Tok, gleam@option:then(Tok, F)} of
                {none, _} ->
                    {cont, {can_backtrack, true}, [], State};

                {{some, _}, none} ->
                    {cont, {can_backtrack, true}, [], State};

                {_, {some, X}} ->
                    runwrap(
                        Next_state,
                        begin
                            _pipe = take_map_while(F),
                            map(
                                _pipe,
                                fun(_capture) ->
                                    gleam@list:prepend(_capture, X)
                                end
                            )
                        end
                    )
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 676).
-spec bag_from_state(state(ODV, ODW), error(ODV)) -> bag(ODV, ODW).
bag_from_state(State, Problem) ->
    {cons,
        empty,
        {dead_end, erlang:element(4, State), Problem, erlang:element(5, State)}}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 179).
-spec throw(binary()) -> parser(any(), any(), any()).
throw(Message) ->
    {parser,
        fun(State) ->
            Error = {custom, Message},
            Bag = bag_from_state(State, Error),
            {fail, {can_backtrack, false}, Bag}
        end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 190).
-spec fail(binary()) -> parser(any(), any(), any()).
fail(Message) ->
    throw(Message).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 312).
-spec token(NWM) -> parser(nil, NWM, any()).
token(Tok) ->
    {parser, fun(State) -> case next(State) of
                {{some, T}, State@1} when Tok =:= T ->
                    {cont, {can_backtrack, true}, nil, State@1};

                {{some, T@1}, State@2} ->
                    {fail,
                        {can_backtrack, false},
                        bag_from_state(
                            State@2,
                            {expected, gleam@string:inspect(Tok), T@1}
                        )};

                {none, State@3} ->
                    {fail,
                        {can_backtrack, false},
                        bag_from_state(State@3, end_of_input)}
            end end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 329).
-spec eof() -> parser(nil, any(), any()).
eof() ->
    {parser, fun(State) -> case next(State) of
                {{some, Tok}, State@1} ->
                    {fail,
                        {can_backtrack, false},
                        bag_from_state(State@1, {unexpected, Tok})};

                {none, _} ->
                    {cont, {can_backtrack, false}, nil, State}
            end end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 443).
-spec guard(boolean(), binary()) -> parser(nil, any(), any()).
guard(Cond, Expecting) ->
    case Cond of
        true ->
            return(nil);

        false ->
            fail(Expecting)
    end.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 452).
-spec take_if(binary(), fun((NZY) -> boolean())) -> parser(NZY, NZY, any()).
take_if(Expecting, Predicate) ->
    {parser,
        fun(State) ->
            {Tok, Next_state} = next(State),
            case {Tok, gleam@option:map(Tok, Predicate)} of
                {{some, Tok@1}, {some, true}} ->
                    {cont, {can_backtrack, false}, Tok@1, Next_state};

                {{some, Tok@2}, {some, false}} ->
                    {fail,
                        {can_backtrack, false},
                        bag_from_state(Next_state, {expected, Expecting, Tok@2})};

                {_, _} ->
                    {fail,
                        {can_backtrack, false},
                        bag_from_state(Next_state, end_of_input)}
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 306).
-spec any() -> parser(NWH, NWH, any()).
any() ->
    take_if(<<"a single token"/utf8>>, fun(_) -> true end).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 497).
-spec take_while1(binary(), fun((OAJ) -> boolean())) -> parser(list(OAJ), OAJ, any()).
take_while1(Expecting, Predicate) ->
    do(
        take_if(Expecting, Predicate),
        fun(X) -> do(take_while(Predicate), fun(Xs) -> return([X | Xs]) end) end
    ).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 518).
-spec take_until1(binary(), fun((OAV) -> boolean())) -> parser(list(OAV), OAV, any()).
take_until1(Expecting, Predicate) ->
    take_while1(Expecting, fun(Tok) -> gleam@bool:negate(Predicate(Tok)) end).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 597).
-spec take_map(binary(), fun((OCY) -> gleam@option:option(OCZ))) -> parser(OCZ, OCY, any()).
take_map(Expecting, F) ->
    {parser,
        fun(State) ->
            {Tok, Next_state} = next(State),
            case {Tok, gleam@option:then(Tok, F)} of
                {none, _} ->
                    {fail,
                        {can_backtrack, false},
                        bag_from_state(Next_state, end_of_input)};

                {{some, Tok@1}, none} ->
                    {fail,
                        {can_backtrack, false},
                        bag_from_state(Next_state, {expected, Expecting, Tok@1})};

                {_, {some, A}} ->
                    {cont, {can_backtrack, false}, A, Next_state}
            end
        end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 638).
-spec take_map_while1(binary(), fun((ODN) -> gleam@option:option(ODO))) -> parser(list(ODO), ODN, any()).
take_map_while1(Expecting, F) ->
    do(
        take_map(Expecting, F),
        fun(X) -> do(take_map_while(F), fun(Xs) -> return([X | Xs]) end) end
    ).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 680).
-spec to_deadends(bag(OEC, OED), list(dead_end(OEC, OED))) -> list(dead_end(OEC, OED)).
to_deadends(Bag, Acc) ->
    case Bag of
        empty ->
            Acc;

        {cons, empty, Deadend} ->
            [Deadend | Acc];

        {cons, Bag@1, Deadend@1} ->
            to_deadends(Bag@1, [Deadend@1 | Acc]);

        {append, Left, Right} ->
            to_deadends(Left, to_deadends(Right, Acc))
    end.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 77).
-spec run(list(nibble@lexer:token(NRA)), parser(NRD, NRA, NRE)) -> {ok, NRD} |
    {error, list(dead_end(NRA, NRE))}.
run(Src, Parser) ->
    Src@1 = gleam@list:index_fold(
        Src,
        gleam@dict:new(),
        fun(Dict, Tok, Idx) -> gleam@dict:insert(Dict, Idx, Tok) end
    ),
    Init = {state, Src@1, 0, {span, 1, 1, 1, 1}, []},
    case runwrap(Init, Parser) of
        {cont, _, A, _} ->
            {ok, A};

        {fail, _, Bag} ->
            {error, to_deadends(Bag, [])}
    end.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 692).
-spec add_bag_to_step(step(OEM, OEN, OEO), bag(OEN, OEO)) -> step(OEM, OEN, OEO).
add_bag_to_step(Step, Left) ->
    case Step of
        {cont, Can_backtrack, A, State} ->
            {cont, Can_backtrack, A, State};

        {fail, Can_backtrack@1, Right} ->
            {fail, Can_backtrack@1, {append, Left, Right}}
    end.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 343).
-spec one_of(list(parser(NWW, NWX, NWY))) -> parser(NWW, NWX, NWY).
one_of(Parsers) ->
    {parser,
        fun(State) ->
            Init = {fail, {can_backtrack, false}, empty},
            gleam@list:fold_until(
                Parsers,
                Init,
                fun(Result, Next) -> case Result of
                        {cont, _, _, _} ->
                            {stop, Result};

                        {fail, {can_backtrack, true}, _} ->
                            {stop, Result};

                        {fail, _, Bag} ->
                            _pipe = runwrap(State, Next),
                            _pipe@1 = add_bag_to_step(_pipe, Bag),
                            {continue, _pipe@1}
                    end end
            )
        end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 387).
-spec more(NYO, parser(NYO, NYP, NYQ), parser(any(), NYP, NYQ)) -> parser(list(NYO), NYP, NYQ).
more(X, Parser, Separator) ->
    loop(
        [X],
        fun(Xs) ->
            Break = fun() -> return({break, lists:reverse(Xs)}) end,
            Continue = (do(
                Separator,
                fun(_) ->
                    do(Parser, fun(X@1) -> return({continue, [X@1 | Xs]}) end)
                end
            )),
            one_of([Continue, lazy(Break)])
        end
    ).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 361).
-spec sequence(parser(NXG, NXH, NXI), parser(any(), NXH, NXI)) -> parser(list(NXG), NXH, NXI).
sequence(Parser, Sep) ->
    one_of(
        [begin
                _pipe = Parser,
                then(_pipe, fun(_capture) -> more(_capture, Parser, Sep) end)
            end,
            return([])]
    ).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 374).
-spec many(parser(NXU, NXV, NXW)) -> parser(list(NXU), NXV, NXW).
many(Parser) ->
    sequence(Parser, return(nil)).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 380).
-spec many1(parser(NYE, NYF, NYG)) -> parser(list(NYE), NYF, NYG).
many1(Parser) ->
    do(Parser, fun(X) -> do(many(Parser), fun(Xs) -> return([X | Xs]) end) end).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 546).
-spec take_at_least(parser(OBL, OBM, OBN), integer()) -> parser(list(OBL), OBM, OBN).
take_at_least(Parser, Count) ->
    case Count of
        0 ->
            many(Parser);

        _ ->
            do(
                Parser,
                fun(X) ->
                    do(
                        take_at_least(Parser, Count - 1),
                        fun(Xs) -> return([X | Xs]) end
                    )
                end
            )
    end.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 581).
-spec 'or'(parser(OCF, OCG, OCH), OCF) -> parser(OCF, OCG, OCH).
'or'(Parser, Default) ->
    one_of([Parser, return(Default)]).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 527).
-spec take_up_to(parser(OBB, OBC, OBD), integer()) -> parser(list(OBB), OBC, OBD).
take_up_to(Parser, Count) ->
    case Count of
        0 ->
            return([]);

        _ ->
            _pipe = (do(
                Parser,
                fun(X) ->
                    do(
                        take_up_to(Parser, Count - 1),
                        fun(Xs) -> return([X | Xs]) end
                    )
                end
            )),
            'or'(_pipe, [])
    end.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 589).
-spec optional(parser(OCO, OCP, OCQ)) -> parser(gleam@option:option(OCO), OCP, OCQ).
optional(Parser) ->
    one_of([map(Parser, fun(Field@0) -> {some, Field@0} end), return(none)]).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 715).
-spec push_context(state(OFG, OFH), OFH) -> state(OFG, OFH).
push_context(State, Context) ->
    erlang:setelement(
        5,
        State,
        [{erlang:element(4, State), Context} | erlang:element(5, State)]
    ).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 719).
-spec pop_context(state(OFM, OFN)) -> state(OFM, OFN).
pop_context(State) ->
    case erlang:element(5, State) of
        [] ->
            State;

        [_ | Context] ->
            erlang:setelement(5, State, Context)
    end.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 706).
-spec in(parser(OEX, OEY, OEZ), OEZ) -> parser(OEX, OEY, OEZ).
in(Parser, Context) ->
    {parser, fun(State) -> case runwrap(push_context(State, Context), Parser) of
                {cont, Can_backtrack, A, State@1} ->
                    {cont, Can_backtrack, A, pop_context(State@1)};

                {fail, Can_backtrack@1, Bag} ->
                    {fail, Can_backtrack@1, Bag}
            end end}.

-file("/var/www/build/packages/nibble/src/nibble.gleam", 260).
-spec do_in(NUI, parser(NUJ, NUK, NUI), fun((NUJ) -> parser(NUO, NUK, NUI))) -> parser(NUO, NUK, NUI).
do_in(Context, Parser, F) ->
    _pipe = do(Parser, F),
    in(_pipe, Context).

-file("/var/www/build/packages/nibble/src/nibble.gleam", 727).
-spec inspect(parser(OFS, OFT, OFU), binary()) -> parser(OFS, OFT, OFU).
inspect(Parser, Message) ->
    {parser,
        fun(State) ->
            gleam@io:println(<<Message/binary, ": "/utf8>>),
            _pipe = runwrap(State, Parser),
            gleam@io:debug(_pipe)
        end}.
