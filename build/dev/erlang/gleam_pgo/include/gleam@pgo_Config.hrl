-record(config, {
    host :: binary(),
    port :: integer(),
    database :: binary(),
    user :: binary(),
    password :: gleam@option:option(binary()),
    ssl :: boolean(),
    connection_parameters :: list({binary(), binary()}),
    pool_size :: integer(),
    queue_target :: integer(),
    queue_interval :: integer(),
    idle_interval :: integer(),
    trace :: boolean(),
    ip_version :: gleam@pgo:ip_version(),
    rows_as_map :: boolean()
}).
