-module(app).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([main/0]).

-file("/var/www/src/app.gleam", 60).
-spec get_env(binary()) -> {ok, binary()} | {error, binary()}.
get_env(Name) ->
    _pipe = glenvy@env:get_string(Name),
    gleam@result:map_error(
        _pipe,
        fun(_) -> <<Name/binary, " environment variable not set"/utf8>> end
    ).

-file("/var/www/src/app.gleam", 34).
-spec connect_db() -> {ok, gleam@pgo:connection()} | {error, binary()}.
connect_db() ->
    gleam@result:'try'(
        get_env(<<"DB_HOST"/utf8>>),
        fun(Host) ->
            gleam@result:'try'(
                get_env(<<"DB_PORT"/utf8>>),
                fun(Port_str) ->
                    gleam@result:'try'(
                        begin
                            _pipe = gleam@int:parse(Port_str),
                            gleam@result:map_error(
                                _pipe,
                                fun(_) ->
                                    <<"DB_PORT is not a valid integer"/utf8>>
                                end
                            )
                        end,
                        fun(Port) ->
                            gleam@result:'try'(
                                get_env(<<"DB_USER"/utf8>>),
                                fun(User) ->
                                    gleam@result:'try'(
                                        get_env(<<"DB_PASS"/utf8>>),
                                        fun(Password) ->
                                            gleam@result:'try'(
                                                get_env(<<"DB_NAME"/utf8>>),
                                                fun(Database) ->
                                                    {ok,
                                                        gleam_pgo_ffi:connect(
                                                            erlang:setelement(
                                                                9,
                                                                erlang:setelement(
                                                                    4,
                                                                    erlang:setelement(
                                                                        6,
                                                                        erlang:setelement(
                                                                            5,
                                                                            erlang:setelement(
                                                                                3,
                                                                                erlang:setelement(
                                                                                    2,
                                                                                    gleam@pgo:default_config(
                                                                                        
                                                                                    ),
                                                                                    Host
                                                                                ),
                                                                                Port
                                                                            ),
                                                                            User
                                                                        ),
                                                                        {some,
                                                                            Password}
                                                                    ),
                                                                    Database
                                                                ),
                                                                2
                                                            )
                                                        )}
                                                end
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("/var/www/src/app.gleam", 118).
-spec pgo_error_to_string(gleam@pgo:query_error()) -> binary().
pgo_error_to_string(Error) ->
    case Error of
        connection_unavailable ->
            <<"connection unavailable"/utf8>>;

        {constraint_violated, Msg, C, _} ->
            <<<<<<"constraint violated ("/utf8, C/binary>>/binary, "): "/utf8>>/binary,
                Msg/binary>>;

        {postgresql_error, _, _, Msg@1} ->
            Msg@1;

        {unexpected_argument_count, E, G} ->
            <<<<<<"wrong argument count: expected "/utf8,
                        (gleam@int:to_string(E))/binary>>/binary,
                    ", got "/utf8>>/binary,
                (gleam@int:to_string(G))/binary>>;

        {unexpected_argument_type, E@1, G@1} ->
            <<<<<<"wrong argument type: expected "/utf8, E@1/binary>>/binary,
                    ", got "/utf8>>/binary,
                G@1/binary>>;

        {unexpected_result_type, _} ->
            <<"unexpected result type"/utf8>>
    end.

-file("/var/www/src/app.gleam", 102).
-spec query_greeting(gleam@pgo:connection()) -> {ok, binary()} |
    {error, binary()}.
query_greeting(Db) ->
    _pipe = gleam@pgo:execute(
        <<"SELECT message FROM greetings LIMIT 1"/utf8>>,
        Db,
        [],
        fun(Row) ->
            (gleam@dynamic:element(0, fun gleam@dynamic:string/1))(Row)
        end
    ),
    _pipe@1 = gleam@result:map_error(_pipe, fun pgo_error_to_string/1),
    gleam@result:then(
        _pipe@1,
        fun(Returned) -> case erlang:element(3, Returned) of
                [Message | _] ->
                    {ok, Message};

                [] ->
                    {error,
                        <<"greetings table is empty — migration may not have run"/utf8>>}
            end end
    ).

-file("/var/www/src/app.gleam", 72).
-spec health_check(gleam@pgo:connection()) -> gleam@http@response:response(wisp:body()).
health_check(Db) ->
    case query_greeting(Db) of
        {ok, Greeting} ->
            wisp:json_response(
                gleam@json:to_string_builder(
                    gleam@json:object(
                        [{<<"type"/utf8>>, gleam@json:string(<<"gleam"/utf8>>)},
                            {<<"greeting"/utf8>>, gleam@json:string(Greeting)},
                            {<<"status"/utf8>>,
                                gleam@json:object(
                                    [{<<"database"/utf8>>,
                                            gleam@json:string(<<"OK"/utf8>>)}]
                                )}]
                    )
                ),
                200
            );

        {error, Err} ->
            wisp:json_response(
                gleam@json:to_string_builder(
                    gleam@json:object(
                        [{<<"type"/utf8>>, gleam@json:string(<<"gleam"/utf8>>)},
                            {<<"greeting"/utf8>>, gleam@json:null()},
                            {<<"status"/utf8>>,
                                gleam@json:object(
                                    [{<<"database"/utf8>>,
                                            gleam@json:string(
                                                <<"ERROR: "/utf8, Err/binary>>
                                            )}]
                                )}]
                    )
                ),
                503
            )
    end.

-file("/var/www/src/app.gleam", 65).
-spec handle_request(
    gleam@http@request:request(wisp@internal:connection()),
    gleam@pgo:connection()
) -> gleam@http@response:response(wisp:body()).
handle_request(Req, Db) ->
    case {erlang:element(2, Req), fun gleam@http@request:path_segments/1(Req)} of
        {get, []} ->
            health_check(Db);

        {_, _} ->
            wisp:not_found()
    end.

-file("/var/www/src/app.gleam", 15).
-spec main() -> nil.
main() ->
    wisp:configure_logger(),
    _assert_subject = connect_db(),
    {ok, Db} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 18})
    end,
    gleam@io:println(<<"Database connected — starting server on :3000"/utf8>>),
    Secret_key_base = wisp:random_string(64),
    _assert_subject@1 = begin
        _pipe = fun(Req) -> handle_request(Req, Db) end,
        _pipe@1 = wisp@wisp_mist:handler(_pipe, Secret_key_base),
        _pipe@2 = mist:new(_pipe@1),
        _pipe@3 = mist:bind(_pipe@2, <<"0.0.0.0"/utf8>>),
        _pipe@4 = mist:port(_pipe@3, 3000),
        mist:start_http(_pipe@4)
    end,
    {ok, _} = case _assert_subject@1 of
        {ok, _} -> _assert_subject@1;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail@1,
                        module => <<"app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 23})
    end,
    gleam_erlang_ffi:sleep_forever().
