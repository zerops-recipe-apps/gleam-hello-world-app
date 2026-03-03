-record(dead_end, {
    pos :: nibble@lexer:span(),
    problem :: nibble:error(any()),
    context :: list({nibble@lexer:span(), any()})
}).
