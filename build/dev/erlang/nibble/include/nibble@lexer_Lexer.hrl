-record(lexer, {
    matchers :: fun((any()) -> list(nibble@lexer:matcher(any(), any())))
}).
