-module(nibble@pratt).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([sub_expression/2, expression/3, prefix/3, postfix/3, infix_left/3, infix_right/3]).
-export_type([config/3, operator/3]).

-opaque config(PIF, PIG, PIH) :: {config,
        list(fun((config(PIF, PIG, PIH)) -> nibble:parser(PIF, PIG, PIH))),
        list(operator(PIF, PIG, PIH)),
        nibble:parser(nil, PIG, PIH)}.

-opaque operator(PII, PIJ, PIK) :: {operator,
        fun((config(PII, PIJ, PIK)) -> {integer(),
            fun((PII) -> nibble:parser(PII, PIJ, PIK))})}.

-file("/var/www/build/packages/nibble/src/nibble/pratt.gleam", 59).
-spec operation(PJO, config(PJO, PJP, PJQ), integer()) -> nibble:parser(PJO, PJP, PJQ).
operation(Expr, Config, Current_precedence) ->
    _pipe = erlang:element(3, Config),
    _pipe@1 = gleam@list:filter_map(
        _pipe,
        fun(Operator) ->
            {operator, Op} = Operator,
            case Op(Config) of
                {Precedence, Parser} when Precedence > Current_precedence ->
                    {ok, Parser(Expr)};

                _ ->
                    {error, nil}
            end
        end
    ),
    nibble:one_of(_pipe@1).

-file("/var/www/build/packages/nibble/src/nibble/pratt.gleam", 31).
-spec sub_expression(config(PJF, PJG, PJH), integer()) -> nibble:parser(PJF, PJG, PJH).
sub_expression(Config, Precedence) ->
    Expr = (nibble:lazy(fun() -> _pipe = erlang:element(2, Config),
            _pipe@1 = gleam@list:map(_pipe, fun(P) -> P(Config) end),
            nibble:one_of(_pipe@1) end)),
    Go = fun(Expr@1) ->
        nibble:do(
            erlang:element(4, Config),
            fun(_) ->
                nibble:one_of(
                    [begin
                            _pipe@2 = operation(Expr@1, Config, Precedence),
                            nibble:map(
                                _pipe@2,
                                fun(Field@0) -> {continue, Field@0} end
                            )
                        end,
                        begin
                            _pipe@3 = nibble:return(Expr@1),
                            nibble:map(
                                _pipe@3,
                                fun(Field@0) -> {break, Field@0} end
                            )
                        end]
                )
            end
        )
    end,
    nibble:do(
        erlang:element(4, Config),
        fun(_) -> nibble:do(Expr, fun(E) -> nibble:loop(E, Go) end) end
    ).

-file("/var/www/build/packages/nibble/src/nibble/pratt.gleam", 22).
-spec expression(
    list(fun((config(PIL, PIM, PIN)) -> nibble:parser(PIL, PIM, PIN))),
    list(operator(PIL, PIM, PIN)),
    nibble:parser(nil, PIM, PIN)
) -> nibble:parser(PIL, PIM, PIN).
expression(First, Then, Spaces) ->
    Config = {config, First, Then, Spaces},
    sub_expression(Config, 0).

-file("/var/www/build/packages/nibble/src/nibble/pratt.gleam", 79).
-spec prefix(integer(), nibble:parser(nil, PJX, PJY), fun((PKC) -> PKC)) -> fun((config(PKC, PJX, PJY)) -> nibble:parser(PKC, PJX, PJY)).
prefix(Precedence, Operator, Apply) ->
    fun(Config) ->
        nibble:do(
            Operator,
            fun(_) ->
                nibble:do(
                    sub_expression(Config, Precedence),
                    fun(Subexpr) -> nibble:return(Apply(Subexpr)) end
                )
            end
        )
    end.

-file("/var/www/build/packages/nibble/src/nibble/pratt.gleam", 108).
-spec postfix(integer(), nibble:parser(nil, PLB, PLC), fun((PLG) -> PLG)) -> operator(PLG, PLB, PLC).
postfix(Precedence, Operator, Apply) ->
    {operator,
        fun(_) ->
            {Precedence,
                fun(Lhs) ->
                    nibble:do(Operator, fun(_) -> nibble:return(Apply(Lhs)) end)
                end}
        end}.

-file("/var/www/build/packages/nibble/src/nibble/pratt.gleam", 123).
-spec make_infix(
    {integer(), integer()},
    nibble:parser(nil, PLK, PLL),
    fun((PLP, PLP) -> PLP)
) -> operator(PLP, PLK, PLL).
make_infix(Precedence, Operator, Apply) ->
    {Left_precedence, Right_precedence} = Precedence,
    {operator,
        fun(Config) ->
            {Left_precedence,
                fun(Lhs) ->
                    nibble:do(
                        Operator,
                        fun(_) ->
                            nibble:do(
                                sub_expression(Config, Right_precedence),
                                fun(Subexpr) ->
                                    nibble:return(Apply(Lhs, Subexpr))
                                end
                            )
                        end
                    )
                end}
        end}.

-file("/var/www/build/packages/nibble/src/nibble/pratt.gleam", 92).
-spec infix_left(
    integer(),
    nibble:parser(nil, PKJ, PKK),
    fun((PKO, PKO) -> PKO)
) -> operator(PKO, PKJ, PKK).
infix_left(Precedence, Operator, Apply) ->
    make_infix({Precedence, Precedence}, Operator, Apply).

-file("/var/www/build/packages/nibble/src/nibble/pratt.gleam", 100).
-spec infix_right(
    integer(),
    nibble:parser(nil, PKS, PKT),
    fun((PKX, PKX) -> PKX)
) -> operator(PKX, PKS, PKT).
infix_right(Precedence, Operator, Apply) ->
    make_infix({Precedence, Precedence - 1}, Operator, Apply).
