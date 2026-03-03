-module(gleam@otp@task).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([async/1, try_await/2, await/2, pid/1, try_await_forever/1, await_forever/1, try_await2/3, try_await3/4, try_await4/5]).
-export_type([task/1, await_error/0, message2/2, message3/3, message4/4]).

-opaque task(LAB) :: {task,
        gleam@erlang@process:pid_(),
        gleam@erlang@process:pid_(),
        gleam@erlang@process:subject(LAB)}.

-type await_error() :: timeout | {exit, gleam@dynamic:dynamic_()}.

-type message2(LAC, LAD) :: {m2_from_subject1, LAC} |
    {m2_from_subject2, LAD} |
    m2_timeout.

-type message3(LAE, LAF, LAG) :: {m3_from_subject1, LAE} |
    {m3_from_subject2, LAF} |
    {m3_from_subject3, LAG} |
    m3_timeout.

-type message4(LAH, LAI, LAJ, LAK) :: {m4_from_subject1, LAH} |
    {m4_from_subject2, LAI} |
    {m4_from_subject3, LAJ} |
    {m4_from_subject4, LAK} |
    m4_timeout.

-file("/var/www/build/packages/gleam_otp/src/gleam/otp/task.gleam", 50).
-spec async(fun(() -> LAL)) -> task(LAL).
async(Work) ->
    Owner = erlang:self(),
    Subject = gleam@erlang@process:new_subject(),
    Pid = gleam@erlang@process:start(
        fun() -> gleam@erlang@process:send(Subject, Work()) end,
        true
    ),
    {task, Owner, Pid, Subject}.

-file("/var/www/build/packages/gleam_otp/src/gleam/otp/task.gleam", 65).
-spec assert_owner(task(any())) -> nil.
assert_owner(Task) ->
    Self = erlang:self(),
    case erlang:element(2, Task) =:= Self of
        true ->
            nil;

        false ->
            gleam@erlang@process:send_abnormal_exit(
                Self,
                <<"awaited on a task that does not belong to this process"/utf8>>
            )
    end.

-file("/var/www/build/packages/gleam_otp/src/gleam/otp/task.gleam", 83).
-spec try_await(task(LAP), integer()) -> {ok, LAP} | {error, await_error()}.
try_await(Task, Timeout) ->
    assert_owner(Task),
    Selector = begin
        _pipe = gleam_erlang_ffi:new_selector(),
        gleam@erlang@process:selecting(
            _pipe,
            erlang:element(4, Task),
            fun gleam@function:identity/1
        )
    end,
    case gleam_erlang_ffi:select(Selector, Timeout) of
        {ok, X} ->
            {ok, X};

        {error, nil} ->
            {error, timeout}
    end.

-file("/var/www/build/packages/gleam_otp/src/gleam/otp/task.gleam", 102).
-spec await(task(LAT), integer()) -> LAT.
await(Task, Timeout) ->
    _assert_subject = try_await(Task, Timeout),
    {ok, Value} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"gleam/otp/task"/utf8>>,
                        function => <<"await"/utf8>>,
                        line => 103})
    end,
    Value.

-file("/var/www/build/packages/gleam_otp/src/gleam/otp/task.gleam", 109).
-spec pid(task(any())) -> gleam@erlang@process:pid_().
pid(Task) ->
    erlang:element(3, Task).

-file("/var/www/build/packages/gleam_otp/src/gleam/otp/task.gleam", 114).
-spec try_await_forever(task(LAX)) -> {ok, LAX} | {error, await_error()}.
try_await_forever(Task) ->
    assert_owner(Task),
    Selector = begin
        _pipe = gleam_erlang_ffi:new_selector(),
        gleam@erlang@process:selecting(
            _pipe,
            erlang:element(4, Task),
            fun gleam@function:identity/1
        )
    end,
    case gleam_erlang_ffi:select(Selector) of
        X ->
            {ok, X}
    end.

-file("/var/www/build/packages/gleam_otp/src/gleam/otp/task.gleam", 132).
-spec await_forever(task(LBB)) -> LBB.
await_forever(Task) ->
    assert_owner(Task),
    Selector = begin
        _pipe = gleam_erlang_ffi:new_selector(),
        gleam@erlang@process:selecting(
            _pipe,
            erlang:element(4, Task),
            fun gleam@function:identity/1
        )
    end,
    gleam_erlang_ffi:select(Selector).

-file("/var/www/build/packages/gleam_otp/src/gleam/otp/task.gleam", 169).
-spec try_await2_loop(
    gleam@erlang@process:selector(message2(LBL, LBM)),
    gleam@option:option({ok, LBL} | {error, await_error()}),
    gleam@option:option({ok, LBM} | {error, await_error()}),
    gleam@erlang@process:timer()
) -> {{ok, LBL} | {error, await_error()}, {ok, LBM} | {error, await_error()}}.
try_await2_loop(Selector, T1, T2, Timeout) ->
    case {T1, T2} of
        {{some, T1@1}, {some, T2@1}} ->
            {T1@1, T2@1};

        {_, _} ->
            case gleam_erlang_ffi:select(Selector) of
                {m2_from_subject1, X} ->
                    T1@2 = {some, {ok, X}},
                    try_await2_loop(Selector, T1@2, T2, Timeout);

                {m2_from_subject2, X@1} ->
                    T2@2 = {some, {ok, X@1}},
                    try_await2_loop(Selector, T1, T2@2, Timeout);

                m2_timeout ->
                    {gleam@option:unwrap(T1, {error, timeout}),
                        gleam@option:unwrap(T2, {error, timeout})}
            end
    end.

-file("/var/www/build/packages/gleam_otp/src/gleam/otp/task.gleam", 151).
-spec try_await2(task(LBD), task(LBF), integer()) -> {{ok, LBD} |
        {error, await_error()},
    {ok, LBF} | {error, await_error()}}.
try_await2(Task1, Task2, Timeout) ->
    assert_owner(Task1),
    assert_owner(Task2),
    Timeout_subject = gleam@erlang@process:new_subject(),
    Timer = gleam@erlang@process:send_after(
        Timeout_subject,
        Timeout,
        m2_timeout
    ),
    _pipe = gleam_erlang_ffi:new_selector(),
    _pipe@1 = gleam@erlang@process:selecting(
        _pipe,
        erlang:element(4, Task1),
        fun(Field@0) -> {m2_from_subject1, Field@0} end
    ),
    _pipe@2 = gleam@erlang@process:selecting(
        _pipe@1,
        erlang:element(4, Task2),
        fun(Field@0) -> {m2_from_subject2, Field@0} end
    ),
    _pipe@3 = gleam@erlang@process:selecting(
        _pipe@2,
        Timeout_subject,
        fun gleam@function:identity/1
    ),
    try_await2_loop(_pipe@3, none, none, Timer).

-file("/var/www/build/packages/gleam_otp/src/gleam/otp/task.gleam", 234).
-spec try_await3_loop(
    gleam@erlang@process:selector(message3(LCM, LCN, LCO)),
    gleam@option:option({ok, LCM} | {error, await_error()}),
    gleam@option:option({ok, LCN} | {error, await_error()}),
    gleam@option:option({ok, LCO} | {error, await_error()}),
    gleam@erlang@process:timer()
) -> {{ok, LCM} | {error, await_error()},
    {ok, LCN} | {error, await_error()},
    {ok, LCO} | {error, await_error()}}.
try_await3_loop(Selector, T1, T2, T3, Timeout) ->
    case {T1, T2, T3} of
        {{some, T1@1}, {some, T2@1}, {some, T3@1}} ->
            {T1@1, T2@1, T3@1};

        {_, _, _} ->
            case gleam_erlang_ffi:select(Selector) of
                {m3_from_subject1, X} ->
                    T1@2 = {some, {ok, X}},
                    try_await3_loop(Selector, T1@2, T2, T3, Timeout);

                {m3_from_subject2, X@1} ->
                    T2@2 = {some, {ok, X@1}},
                    try_await3_loop(Selector, T1, T2@2, T3, Timeout);

                {m3_from_subject3, X@2} ->
                    T3@2 = {some, {ok, X@2}},
                    try_await3_loop(Selector, T1, T2, T3@2, Timeout);

                m3_timeout ->
                    {gleam@option:unwrap(T1, {error, timeout}),
                        gleam@option:unwrap(T2, {error, timeout}),
                        gleam@option:unwrap(T3, {error, timeout})}
            end
    end.

-file("/var/www/build/packages/gleam_otp/src/gleam/otp/task.gleam", 213).
-spec try_await3(task(LCA), task(LCC), task(LCE), integer()) -> {{ok, LCA} |
        {error, await_error()},
    {ok, LCC} | {error, await_error()},
    {ok, LCE} | {error, await_error()}}.
try_await3(Task1, Task2, Task3, Timeout) ->
    assert_owner(Task1),
    assert_owner(Task2),
    assert_owner(Task3),
    Timeout_subject = gleam@erlang@process:new_subject(),
    Timer = gleam@erlang@process:send_after(
        Timeout_subject,
        Timeout,
        m3_timeout
    ),
    _pipe = gleam_erlang_ffi:new_selector(),
    _pipe@1 = gleam@erlang@process:selecting(
        _pipe,
        erlang:element(4, Task1),
        fun(Field@0) -> {m3_from_subject1, Field@0} end
    ),
    _pipe@2 = gleam@erlang@process:selecting(
        _pipe@1,
        erlang:element(4, Task2),
        fun(Field@0) -> {m3_from_subject2, Field@0} end
    ),
    _pipe@3 = gleam@erlang@process:selecting(
        _pipe@2,
        erlang:element(4, Task3),
        fun(Field@0) -> {m3_from_subject3, Field@0} end
    ),
    _pipe@4 = gleam@erlang@process:selecting(
        _pipe@3,
        Timeout_subject,
        fun gleam@function:identity/1
    ),
    try_await3_loop(_pipe@4, none, none, none, Timer).

-file("/var/www/build/packages/gleam_otp/src/gleam/otp/task.gleam", 313).
-spec try_await4_loop(
    gleam@erlang@process:selector(message4(LDY, LDZ, LEA, LEB)),
    gleam@option:option({ok, LDY} | {error, await_error()}),
    gleam@option:option({ok, LDZ} | {error, await_error()}),
    gleam@option:option({ok, LEA} | {error, await_error()}),
    gleam@option:option({ok, LEB} | {error, await_error()}),
    gleam@erlang@process:timer()
) -> {{ok, LDY} | {error, await_error()},
    {ok, LDZ} | {error, await_error()},
    {ok, LEA} | {error, await_error()},
    {ok, LEB} | {error, await_error()}}.
try_await4_loop(Selector, T1, T2, T3, T4, Timeout) ->
    case {T1, T2, T3, T4} of
        {{some, T1@1}, {some, T2@1}, {some, T3@1}, {some, T4@1}} ->
            {T1@1, T2@1, T3@1, T4@1};

        {_, _, _, _} ->
            case gleam_erlang_ffi:select(Selector) of
                {m4_from_subject1, X} ->
                    T1@2 = {some, {ok, X}},
                    try_await4_loop(Selector, T1@2, T2, T3, T4, Timeout);

                {m4_from_subject2, X@1} ->
                    T2@2 = {some, {ok, X@1}},
                    try_await4_loop(Selector, T1, T2@2, T3, T4, Timeout);

                {m4_from_subject3, X@2} ->
                    T3@2 = {some, {ok, X@2}},
                    try_await4_loop(Selector, T1, T2, T3@2, T4, Timeout);

                {m4_from_subject4, X@3} ->
                    T4@2 = {some, {ok, X@3}},
                    try_await4_loop(Selector, T1, T2, T3, T4@2, Timeout);

                m4_timeout ->
                    {gleam@option:unwrap(T1, {error, timeout}),
                        gleam@option:unwrap(T2, {error, timeout}),
                        gleam@option:unwrap(T3, {error, timeout}),
                        gleam@option:unwrap(T4, {error, timeout})}
            end
    end.

-file("/var/www/build/packages/gleam_otp/src/gleam/otp/task.gleam", 285).
-spec try_await4(task(LDI), task(LDK), task(LDM), task(LDO), integer()) -> {{ok,
            LDI} |
        {error, await_error()},
    {ok, LDK} | {error, await_error()},
    {ok, LDM} | {error, await_error()},
    {ok, LDO} | {error, await_error()}}.
try_await4(Task1, Task2, Task3, Task4, Timeout) ->
    assert_owner(Task1),
    assert_owner(Task2),
    assert_owner(Task3),
    Timeout_subject = gleam@erlang@process:new_subject(),
    Timer = gleam@erlang@process:send_after(
        Timeout_subject,
        Timeout,
        m4_timeout
    ),
    _pipe = gleam_erlang_ffi:new_selector(),
    _pipe@1 = gleam@erlang@process:selecting(
        _pipe,
        erlang:element(4, Task1),
        fun(Field@0) -> {m4_from_subject1, Field@0} end
    ),
    _pipe@2 = gleam@erlang@process:selecting(
        _pipe@1,
        erlang:element(4, Task2),
        fun(Field@0) -> {m4_from_subject2, Field@0} end
    ),
    _pipe@3 = gleam@erlang@process:selecting(
        _pipe@2,
        erlang:element(4, Task3),
        fun(Field@0) -> {m4_from_subject3, Field@0} end
    ),
    _pipe@4 = gleam@erlang@process:selecting(
        _pipe@3,
        erlang:element(4, Task4),
        fun(Field@0) -> {m4_from_subject4, Field@0} end
    ),
    _pipe@5 = gleam@erlang@process:selecting(
        _pipe@4,
        Timeout_subject,
        fun gleam@function:identity/1
    ),
    try_await4_loop(_pipe@5, none, none, none, none, Timer).
