-module(glisten@socket@options).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([to_dict/1, merge_with_defaults/1]).
-export_type([socket_mode/0, active_state/0, interface/0, tcp_option/0, ip_address/0]).

-type socket_mode() :: binary.

-type active_state() :: once | passive | {count, integer()} | active.

-type interface() :: {address, ip_address()} | any | loopback.

-type tcp_option() :: {backlog, integer()} |
    {nodelay, boolean()} |
    {linger, {boolean(), integer()}} |
    {send_timeout, integer()} |
    {send_timeout_close, boolean()} |
    {reuseaddr, boolean()} |
    {active_mode, active_state()} |
    {mode, socket_mode()} |
    {certfile, binary()} |
    {keyfile, binary()} |
    {alpn_preferred_protocols, list(binary())} |
    ipv6 |
    {buffer, integer()} |
    {ip, interface()}.

-type ip_address() :: {ip_v4, integer(), integer(), integer(), integer()} |
    {ip_v6,
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer()}.

-file("/home/alex/gleams/glisten/src/glisten/socket/options.gleam", 44).
-spec to_dict(list(tcp_option())) -> gleam@dict:dict(gleam@dynamic:dynamic_(), gleam@dynamic:dynamic_()).
to_dict(Options) ->
    Opt_decoder = gleam@dynamic:tuple2(
        fun gleam@dynamic:dynamic/1,
        fun gleam@dynamic:dynamic/1
    ),
    Active = erlang:binary_to_atom(<<"active"/utf8>>),
    Ip = erlang:binary_to_atom(<<"ip"/utf8>>),
    _pipe = Options,
    _pipe@1 = gleam@list:map(_pipe, fun(Opt) -> case Opt of
                {active_mode, passive} ->
                    gleam@dynamic:from({Active, false});

                {active_mode, active} ->
                    gleam@dynamic:from({Active, true});

                {active_mode, {count, N}} ->
                    gleam@dynamic:from({Active, N});

                {active_mode, once} ->
                    gleam@dynamic:from(
                        {Active, erlang:binary_to_atom(<<"once"/utf8>>)}
                    );

                {ip, {address, {ip_v4, A, B, C, D}}} ->
                    gleam@dynamic:from({Ip, gleam@dynamic:from({A, B, C, D})});

                {ip, {address, {ip_v6, A@1, B@1, C@1, D@1, E, F, G, H}}} ->
                    gleam@dynamic:from(
                        {Ip,
                            gleam@dynamic:from({A@1, B@1, C@1, D@1, E, F, G, H})}
                    );

                {ip, any} ->
                    gleam@dynamic:from(
                        {Ip, erlang:binary_to_atom(<<"any"/utf8>>)}
                    );

                {ip, loopback} ->
                    gleam@dynamic:from(
                        {Ip, erlang:binary_to_atom(<<"loopback"/utf8>>)}
                    );

                ipv6 ->
                    gleam@dynamic:from(erlang:binary_to_atom(<<"inet6"/utf8>>));

                Other ->
                    gleam@dynamic:from(Other)
            end end),
    _pipe@2 = gleam@list:filter_map(_pipe@1, Opt_decoder),
    maps:from_list(_pipe@2).

-file("/home/alex/gleams/glisten/src/glisten/socket/options.gleam", 77).
-spec merge_with_defaults(list(tcp_option())) -> list(tcp_option()).
merge_with_defaults(Options) ->
    Overrides = to_dict(Options),
    Has_ipv6 = gleam@list:contains(Options, ipv6),
    _pipe = [{backlog, 1024},
        {nodelay, true},
        {send_timeout, 30000},
        {send_timeout_close, true},
        {reuseaddr, true},
        {mode, binary},
        {active_mode, passive}],
    _pipe@1 = to_dict(_pipe),
    _pipe@2 = gleam@dict:merge(_pipe@1, Overrides),
    _pipe@3 = maps:to_list(_pipe@2),
    _pipe@4 = gleam@list:map(_pipe@3, fun gleam@dynamic:from/1),
    _pipe@5 = (fun(Opts) -> case Has_ipv6 of
            true ->
                [gleam@dynamic:from(erlang:binary_to_atom(<<"inet6"/utf8>>)) |
                    Opts];

            _ ->
                Opts
        end end)(_pipe@4),
    gleam@function:identity(_pipe@5).
