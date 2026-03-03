-record(matcher, {
    run :: fun((any(), binary(), binary()) -> nibble@lexer:match(any(), any()))
}).
