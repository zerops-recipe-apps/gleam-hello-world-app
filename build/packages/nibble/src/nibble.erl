-module(nibble).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([return/1, succeed/1, lazy/1, backtrackable/1, do/2, then/2, map/2, replace/2, span/0, loop/2, take_while/1, take_until/1, take_exactly/2, take_map_while/1, throw/1, fail/1, token/1, eof/0, guard/2, take_if/2, any/0, take_while1/2, take_until1/2, take_map/2, take_map_while1/2, run/2, one_of/1, sequence/2, many/1, many1/1, take_at_least/2, 'or'/2, take_up_to/2, optional/1, in/2, do_in/3, inspect/2]).
-export_type([parser/3, step/3, state/2, can_backtrack/0, loop/2, error/1, dead_end/2, bag/2]).

-opaque parser(GND, GNE, GNF) :: {parser,
        fun((state(GNE, GNF)) -> step(GND, GNE, GNF))}.

-type step(GNG, GNH, GNI) :: {cont, can_backtrack(), GNG, state(GNH, GNI)} |
    {fail, can_backtrack(), bag(GNH, GNI)}.

-type state(GNJ, GNK) :: {state,
        gleam@dict:dict(integer(), nibble@lexer:token(GNJ)),
        integer(),
        nibble@lexer:span(),
        list({nibble@lexer:span(), GNK})}.

-type can_backtrack() :: {can_backtrack, boolean()}.

-type loop(GNL, GNM) :: {continue, GNM} | {break, GNL}.

-type error(GNN) :: {bad_parser, binary()} |
    {custom, binary()} |
    end_of_input |
    {expected, binary(), GNN} |
    {unexpected, GNN}.

-type dead_end(GNO, GNP) :: {dead_end,
        nibble@lexer:span(),
        error(GNO),
        list({nibble@lexer:span(), GNP})}.

-type bag(GNQ, GNR) :: empty |
    {cons, bag(GNQ, GNR), dead_end(GNQ, GNR)} |
    {append, bag(GNQ, GNR), bag(GNQ, GNR)}.

-spec runwrap(state(GOF, GOG), parser(GOJ, GOF, GOG)) -> step(GOJ, GOF, GOG).
runwrap(State, Parser) ->
    {parser, Parse} = Parser,
    Parse(State).

-spec next(state(GOQ, GOR)) -> {gleam@option:option(GOQ), state(GOQ, GOR)}.
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

-spec return(GOX) -> parser(GOX, any(), any()).
return(Value) ->
    {parser, fun(State) -> {cont, {can_backtrack, false}, Value, State} end}.

-spec succeed(GPD) -> parser(GPD, any(), any()).
succeed(Value) ->
    return(Value).

-spec lazy(fun(() -> parser(GPV, GPW, GPX))) -> parser(GPV, GPW, GPX).
lazy(Parser) ->
    {parser, fun(State) -> runwrap(State, Parser()) end}.

-spec backtrackable(parser(GQE, GQF, GQG)) -> parser(GQE, GQF, GQG).
backtrackable(Parser) ->
    {parser, fun(State) -> case runwrap(State, Parser) of
                {cont, _, A, State@1} ->
                    {cont, {can_backtrack, false}, A, State@1};

                {fail, _, Bag} ->
                    {fail, {can_backtrack, false}, Bag}
            end end}.

-spec should_commit(can_backtrack(), can_backtrack()) -> can_backtrack().
should_commit(A, B) ->
    {can_backtrack, A@1} = A,
    {can_backtrack, B@1} = B,
    {can_backtrack, A@1 orelse B@1}.

-spec do(parser(GQN, GQO, GQP), fun((GQN) -> parser(GQT, GQO, GQP))) -> parser(GQT, GQO, GQP).
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

-spec then(parser(GRN, GRO, GRP), fun((GRN) -> parser(GRT, GRO, GRP))) -> parser(GRT, GRO, GRP).
then(Parser, F) ->
    do(Parser, F).

-spec map(parser(GSA, GSB, GSC), fun((GSA) -> GSG)) -> parser(GSG, GSB, GSC).
map(Parser, F) ->
    do(Parser, fun(A) -> return(F(A)) end).

-spec replace(parser(any(), GSL, GSM), GSQ) -> parser(GSQ, GSL, GSM).
replace(Parser, B) ->
    map(Parser, fun(_) -> B end).

-spec span() -> parser(nibble@lexer:span(), any(), any()).
span() ->
    {parser,
        fun(State) ->
            {cont, {can_backtrack, false}, erlang:element(4, State), State}
        end}.

-spec loop_help(
    fun((HJE) -> parser(loop(HJN, HJE), HJI, HJJ)),
    can_backtrack(),
    HJE,
    state(HJI, HJJ)
) -> step(HJN, HJI, HJJ).
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

-spec loop(GVU, fun((GVU) -> parser(loop(GVV, GVU), GVY, GVZ))) -> parser(GVV, GVY, GVZ).
loop(Init, Step) ->
    {parser,
        fun(State) -> loop_help(Step, {can_backtrack, false}, Init, State) end}.

-spec take_while(fun((GWV) -> boolean())) -> parser(list(GWV), GWV, any()).
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

-spec take_until(fun((GXH) -> boolean())) -> parser(list(GXH), GXH, any()).
take_until(Predicate) ->
    take_while(fun(Tok) -> gleam@bool:negate(Predicate(Tok)) end).

-spec take_exactly(parser(GYN, GYO, GYP), integer()) -> parser(list(GYN), GYO, GYP).
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

-spec take_map_while(fun((GZX) -> gleam@option:option(GZY))) -> parser(list(GZY), GZX, any()).
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

-spec bag_from_state(state(HAN, HAO), error(HAN)) -> bag(HAN, HAO).
bag_from_state(State, Problem) ->
    {cons,
        empty,
        {dead_end, erlang:element(4, State), Problem, erlang:element(5, State)}}.

-spec throw(binary()) -> parser(any(), any(), any()).
throw(Message) ->
    {parser,
        fun(State) ->
            Error = {custom, Message},
            Bag = bag_from_state(State, Error),
            {fail, {can_backtrack, false}, Bag}
        end}.

-spec fail(binary()) -> parser(any(), any(), any()).
fail(Message) ->
    throw(Message).

-spec token(GTE) -> parser(nil, GTE, any()).
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

-spec guard(boolean(), binary()) -> parser(nil, any(), any()).
guard(Cond, Expecting) ->
    case Cond of
        true ->
            return(nil);

        false ->
            fail(Expecting)
    end.

-spec take_if(binary(), fun((GWQ) -> boolean())) -> parser(GWQ, GWQ, any()).
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

-spec any() -> parser(GSZ, GSZ, any()).
any() ->
    take_if(<<"a single token"/utf8>>, fun(_) -> true end).

-spec take_while1(binary(), fun((GXB) -> boolean())) -> parser(list(GXB), GXB, any()).
take_while1(Expecting, Predicate) ->
    do(
        take_if(Expecting, Predicate),
        fun(X) -> do(take_while(Predicate), fun(Xs) -> return([X | Xs]) end) end
    ).

-spec take_until1(binary(), fun((GXN) -> boolean())) -> parser(list(GXN), GXN, any()).
take_until1(Expecting, Predicate) ->
    take_while1(Expecting, fun(Tok) -> gleam@bool:negate(Predicate(Tok)) end).

-spec take_map(binary(), fun((GZQ) -> gleam@option:option(GZR))) -> parser(GZR, GZQ, any()).
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

-spec take_map_while1(binary(), fun((HAF) -> gleam@option:option(HAG))) -> parser(list(HAG), HAF, any()).
take_map_while1(Expecting, F) ->
    do(
        take_map(Expecting, F),
        fun(X) -> do(take_map_while(F), fun(Xs) -> return([X | Xs]) end) end
    ).

-spec to_deadends(bag(HAU, HAV), list(dead_end(HAU, HAV))) -> list(dead_end(HAU, HAV)).
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

-spec run(list(nibble@lexer:token(GNS)), parser(GNV, GNS, GNW)) -> {ok, GNV} |
    {error, list(dead_end(GNS, GNW))}.
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

-spec add_bag_to_step(step(HBE, HBF, HBG), bag(HBF, HBG)) -> step(HBE, HBF, HBG).
add_bag_to_step(Step, Left) ->
    case Step of
        {cont, Can_backtrack, A, State} ->
            {cont, Can_backtrack, A, State};

        {fail, Can_backtrack@1, Right} ->
            {fail, Can_backtrack@1, {append, Left, Right}}
    end.

-spec one_of(list(parser(GTO, GTP, GTQ))) -> parser(GTO, GTP, GTQ).
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

-spec more(GVG, parser(GVG, GVH, GVI), parser(any(), GVH, GVI)) -> parser(list(GVG), GVH, GVI).
more(X, Parser, Separator) ->
    loop(
        [X],
        fun(Xs) ->
            Break = fun() -> return({break, gleam@list:reverse(Xs)}) end,
            Continue = (do(
                Separator,
                fun(_) ->
                    do(Parser, fun(X@1) -> return({continue, [X@1 | Xs]}) end)
                end
            )),
            one_of([Continue, lazy(Break)])
        end
    ).

-spec sequence(parser(GTY, GTZ, GUA), parser(any(), GTZ, GUA)) -> parser(list(GTY), GTZ, GUA).
sequence(Parser, Sep) ->
    one_of(
        [begin
                _pipe = Parser,
                then(_pipe, fun(_capture) -> more(_capture, Parser, Sep) end)
            end,
            return([])]
    ).

-spec many(parser(GUM, GUN, GUO)) -> parser(list(GUM), GUN, GUO).
many(Parser) ->
    sequence(Parser, return(nil)).

-spec many1(parser(GUW, GUX, GUY)) -> parser(list(GUW), GUX, GUY).
many1(Parser) ->
    do(Parser, fun(X) -> do(many(Parser), fun(Xs) -> return([X | Xs]) end) end).

-spec take_at_least(parser(GYD, GYE, GYF), integer()) -> parser(list(GYD), GYE, GYF).
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

-spec 'or'(parser(GYX, GYY, GYZ), GYX) -> parser(GYX, GYY, GYZ).
'or'(Parser, Default) ->
    one_of([Parser, return(Default)]).

-spec take_up_to(parser(GXT, GXU, GXV), integer()) -> parser(list(GXT), GXU, GXV).
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

-spec optional(parser(GZG, GZH, GZI)) -> parser(gleam@option:option(GZG), GZH, GZI).
optional(Parser) ->
    one_of([map(Parser, fun(Field@0) -> {some, Field@0} end), return(none)]).

-spec push_context(state(HBY, HBZ), HBZ) -> state(HBY, HBZ).
push_context(State, Context) ->
    erlang:setelement(
        5,
        State,
        [{erlang:element(4, State), Context} | erlang:element(5, State)]
    ).

-spec pop_context(state(HCE, HCF)) -> state(HCE, HCF).
pop_context(State) ->
    case erlang:element(5, State) of
        [] ->
            State;

        [_ | Context] ->
            erlang:setelement(5, State, Context)
    end.

-spec in(parser(HBP, HBQ, HBR), HBR) -> parser(HBP, HBQ, HBR).
in(Parser, Context) ->
    {parser, fun(State) -> case runwrap(push_context(State, Context), Parser) of
                {cont, Can_backtrack, A, State@1} ->
                    {cont, Can_backtrack, A, pop_context(State@1)};

                {fail, Can_backtrack@1, Bag} ->
                    {fail, Can_backtrack@1, Bag}
            end end}.

-spec do_in(GRA, parser(GRB, GRC, GRA), fun((GRB) -> parser(GRG, GRC, GRA))) -> parser(GRG, GRC, GRA).
do_in(Context, Parser, F) ->
    _pipe = do(Parser, F),
    in(_pipe, Context).

-spec inspect(parser(HCK, HCL, HCM), binary()) -> parser(HCK, HCL, HCM).
inspect(Parser, Message) ->
    {parser,
        fun(State) ->
            gleam@io:println(<<Message/binary, ": "/utf8>>),
            _pipe = runwrap(State, Parser),
            gleam@io:debug(_pipe)
        end}.
