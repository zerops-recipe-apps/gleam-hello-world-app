-module(migrate).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([main/0]).

-file("/var/www/src/migrate.gleam", 8).
-spec main() -> nil.
main() ->
    gleam@io:println(<<"Running database migration..."/utf8>>),
    _assert_subject = glenvy@env:get_string(<<"DB_HOST"/utf8>>),
    {ok, Host} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"migrate"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 11})
    end,
    _assert_subject@1 = glenvy@env:get_string(<<"DB_PORT"/utf8>>),
    {ok, Port_str} = case _assert_subject@1 of
        {ok, _} -> _assert_subject@1;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail@1,
                        module => <<"migrate"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 12})
    end,
    _assert_subject@2 = gleam@int:parse(Port_str),
    {ok, Port} = case _assert_subject@2 of
        {ok, _} -> _assert_subject@2;
        _assert_fail@2 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail@2,
                        module => <<"migrate"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 13})
    end,
    _assert_subject@3 = glenvy@env:get_string(<<"DB_USER"/utf8>>),
    {ok, User} = case _assert_subject@3 of
        {ok, _} -> _assert_subject@3;
        _assert_fail@3 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail@3,
                        module => <<"migrate"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 14})
    end,
    _assert_subject@4 = glenvy@env:get_string(<<"DB_PASS"/utf8>>),
    {ok, Password} = case _assert_subject@4 of
        {ok, _} -> _assert_subject@4;
        _assert_fail@4 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail@4,
                        module => <<"migrate"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 15})
    end,
    _assert_subject@5 = glenvy@env:get_string(<<"DB_NAME"/utf8>>),
    {ok, Database} = case _assert_subject@5 of
        {ok, _} -> _assert_subject@5;
        _assert_fail@5 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail@5,
                        module => <<"migrate"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 16})
    end,
    Db = gleam_pgo_ffi:connect(
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
                                gleam@pgo:default_config(),
                                Host
                            ),
                            Port
                        ),
                        User
                    ),
                    {some, Password}
                ),
                Database
            ),
            1
        )
    ),
    _assert_subject@6 = gleam@pgo:execute(
        <<"CREATE TABLE IF NOT EXISTS greetings (
         id INTEGER PRIMARY KEY,
         message TEXT NOT NULL
       )"/utf8>>,
        Db,
        [],
        fun gleam@dynamic:dynamic/1
    ),
    {ok, _} = case _assert_subject@6 of
        {ok, _} -> _assert_subject@6;
        _assert_fail@6 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail@6,
                        module => <<"migrate"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 31})
    end,
    _assert_subject@7 = gleam@pgo:execute(
        <<"INSERT INTO greetings (id, message)
       VALUES (1, 'Hello from Zerops!')
       ON CONFLICT (id) DO NOTHING"/utf8>>,
        Db,
        [],
        fun gleam@dynamic:dynamic/1
    ),
    {ok, _} = case _assert_subject@7 of
        {ok, _} -> _assert_subject@7;
        _assert_fail@7 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail@7,
                        module => <<"migrate"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 42})
    end,
    gleam_pgo_ffi:disconnect(Db),
    gleam@io:println(<<"Migration complete."/utf8>>).
