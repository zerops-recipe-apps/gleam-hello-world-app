-module(gluid).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([guidv4/0]).

-spec split_to_chunks(binary(), integer()) -> list(binary()).
split_to_chunks(Src, Chunk_size) ->
    case gleam@string:length(Src) of
        Len when Len >= Chunk_size ->
            Head = gleam@string:slice(Src, 0, Chunk_size),
            Tail = gleam@string:slice(Src, Chunk_size, Len - Chunk_size),
            [Head | split_to_chunks(Tail, Chunk_size)];

        _ ->
            []
    end.

-spec binary_pprint(integer()) -> binary().
binary_pprint(Src) ->
    _pipe = Src,
    _pipe@1 = gleam@int:to_base2(_pipe),
    _pipe@2 = gleam@string:pad_left(_pipe@1, 32, <<"0"/utf8>>),
    _pipe@3 = split_to_chunks(_pipe@2, 4),
    gleam@string:join(_pipe@3, <<" "/utf8>>).

-spec format_uuid(binary()) -> binary().
format_uuid(Src) ->
    <<<<<<<<<<<<<<<<(gleam@string:slice(Src, 0, 8))/binary, "-"/utf8>>/binary,
                                (gleam@string:slice(Src, 8, 4))/binary>>/binary,
                            "-"/utf8>>/binary,
                        (gleam@string:slice(Src, 12, 4))/binary>>/binary,
                    "-"/utf8>>/binary,
                (gleam@string:slice(Src, 16, 4))/binary>>/binary,
            "-"/utf8>>/binary,
        (gleam@string:slice(Src, 20, 12))/binary>>.

-spec guidv4() -> binary().
guidv4() ->
    Randoma = gleam@int:random(16#FFFFFFFF),
    A = begin
        _pipe = gleam@int:to_base16(Randoma),
        gleam@string:pad_left(_pipe, 8, <<"0"/utf8>>)
    end,
    Randomb = gleam@int:random(16#FFFFFFFF),
    Clear_mask = erlang:'bnot'(erlang:'bsl'(16#F, 12)),
    Randomb@1 = erlang:'band'(Randomb, Clear_mask),
    Value_mask = erlang:'bsl'(16#4, 12),
    Randomb@2 = erlang:'bor'(Randomb@1, Value_mask),
    B = begin
        _pipe@1 = gleam@int:to_base16(Randomb@2),
        gleam@string:pad_left(_pipe@1, 8, <<"0"/utf8>>)
    end,
    Randomc = gleam@int:random(16#FFFFFFFF),
    Clear_mask@1 = erlang:'bnot'(erlang:'bsl'(16#3, 30)),
    Randomc@1 = erlang:'band'(Randomc, Clear_mask@1),
    Value_mask@1 = erlang:'bsl'(16#2, 30),
    Randomc@2 = erlang:'bor'(Randomc@1, Value_mask@1),
    C = begin
        _pipe@2 = gleam@int:to_base16(Randomc@2),
        gleam@string:pad_left(_pipe@2, 8, <<"0"/utf8>>)
    end,
    Randomd = gleam@int:random(16#FFFFFFFF),
    D = begin
        _pipe@3 = Randomd,
        _pipe@4 = gleam@int:to_base16(_pipe@3),
        gleam@string:pad_left(_pipe@4, 8, <<"0"/utf8>>)
    end,
    Concatened = <<<<<<A/binary, B/binary>>/binary, C/binary>>/binary,
        D/binary>>,
    format_uuid(Concatened).
