-record(config, {
    one_of :: list(fun((nibble@pratt:config(any(), any(), any())) -> nibble:parser(any(), any(), any()))),
    and_then_one_of :: list(nibble@pratt:operator(any(), any(), any())),
    spaces :: nibble:parser(nil, any(), any())
}).
