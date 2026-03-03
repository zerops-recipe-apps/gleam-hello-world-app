-module(nibble@pratt).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([sub_expression/2, expression/3, prefix/3, postfix/3, infix_left/3, infix_right/3]).
-export_type([config/3, operator/3]).

-opaque config(IEX, IEY, IEZ) :: {config,
        list(fun((config(IEX, IEY, IEZ)) -> nibble:parser(IEX, IEY, IEZ))),
        list(operator(IEX, IEY, IEZ)),
        nibble:parser(nil, IEY, IEZ)}.

-opaque operator(IFA, IFB, IFC) :: {operator,
        fun((config(IFA, IFB, IFC)) -> {integer(),
            fun((IFA) -> nibble:parser(IFA, IFB, IFC))})}.

-spec operation(IGG, config(IGG, IGH, IGI), integer()) -> nibble:parser(IGG, IGH, IGI).
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

-spec sub_expression(config(IFX, IFY, IFZ), integer()) -> nibble:parser(IFX, IFY, IFZ).
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

-spec expression(
    list(fun((config(IFD, IFE, IFF)) -> nibble:parser(IFD, IFE, IFF))),
    list(operator(IFD, IFE, IFF)),
    nibble:parser(nil, IFE, IFF)
) -> nibble:parser(IFD, IFE, IFF).
expression(First, Then, Spaces) ->
    Config = {config, First, Then, Spaces},
    sub_expression(Config, 0).

-spec prefix(integer(), nibble:parser(nil, IGP, IGQ), fun((IGU) -> IGU)) -> fun((config(IGU, IGP, IGQ)) -> nibble:parser(IGU, IGP, IGQ)).
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

-spec postfix(integer(), nibble:parser(nil, IHT, IHU), fun((IHY) -> IHY)) -> operator(IHY, IHT, IHU).
postfix(Precedence, Operator, Apply) ->
    {operator,
        fun(_) ->
            {Precedence,
                fun(Lhs) ->
                    nibble:do(Operator, fun(_) -> nibble:return(Apply(Lhs)) end)
                end}
        end}.

-spec make_infix(
    {integer(), integer()},
    nibble:parser(nil, IIC, IID),
    fun((IIH, IIH) -> IIH)
) -> operator(IIH, IIC, IID).
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

-spec infix_left(
    integer(),
    nibble:parser(nil, IHB, IHC),
    fun((IHG, IHG) -> IHG)
) -> operator(IHG, IHB, IHC).
infix_left(Precedence, Operator, Apply) ->
    make_infix({Precedence, Precedence}, Operator, Apply).

-spec infix_right(
    integer(),
    nibble:parser(nil, IHK, IHL),
    fun((IHP, IHP) -> IHP)
) -> operator(IHP, IHK, IHL).
infix_right(Precedence, Operator, Apply) ->
    make_infix({Precedence, Precedence - 1}, Operator, Apply).
