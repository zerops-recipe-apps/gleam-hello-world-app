-module(gleam@pgo).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([default_config/0, url_config/1, connect/1, disconnect/1, null/0, bool/1, int/1, float/1, text/1, bytea/1, array/1, timestamp/1, date/1, transaction/2, nullable/2, execute/4, error_code_name/1, decode_timestamp/1, decode_date/1]).
-export_type([config/0, ip_version/0, connection/0, value/0, transaction_error/0, returned/1, query_error/0]).

-type config() :: {config,
        binary(),
        integer(),
        binary(),
        binary(),
        gleam@option:option(binary()),
        boolean(),
        list({binary(), binary()}),
        integer(),
        integer(),
        integer(),
        integer(),
        boolean(),
        ip_version(),
        boolean()}.

-type ip_version() :: ipv4 | ipv6.

-type connection() :: any().

-type value() :: any().

-type transaction_error() :: {transaction_query_error, query_error()} |
    {transaction_rolled_back, binary()}.

-type returned(LPN) :: {returned, integer(), list(LPN)}.

-type query_error() :: {constraint_violated, binary(), binary(), binary()} |
    {postgresql_error, binary(), binary(), binary()} |
    {unexpected_argument_count, integer(), integer()} |
    {unexpected_argument_type, binary(), binary()} |
    {unexpected_result_type, list(gleam@dynamic:decode_error())} |
    connection_unavailable.

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 67).
-spec default_config() -> config().
default_config() ->
    {config,
        <<"127.0.0.1"/utf8>>,
        5432,
        <<"postgres"/utf8>>,
        <<"postgres"/utf8>>,
        none,
        false,
        [],
        1,
        50,
        1000,
        1000,
        false,
        ipv4,
        false}.

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 87).
-spec url_config(binary()) -> {ok, config()} | {error, nil}.
url_config(Database_url) ->
    gleam@result:then(
        gleam@uri:parse(Database_url),
        fun(Uri) -> gleam@result:then(case Uri of
                    {uri,
                        {some, Scheme},
                        {some, Userinfo},
                        {some, Host},
                        {some, Db_port},
                        Path,
                        _,
                        _} ->
                        case Scheme of
                            <<"postgres"/utf8>> ->
                                {ok, {Userinfo, Host, Path, Db_port}};

                            <<"postgresql"/utf8>> ->
                                {ok, {Userinfo, Host, Path, Db_port}};

                            _ ->
                                {error, nil}
                        end;

                    _ ->
                        {error, nil}
                end, fun(_use0) ->
                    {Userinfo@1, Host@1, Path@1, Db_port@1} = _use0,
                    gleam@result:then(
                        case gleam@string:split(Userinfo@1, <<":"/utf8>>) of
                            [User] ->
                                {ok, {User, none}};

                            [User@1, Password] ->
                                {ok, {User@1, {some, Password}}};

                            _ ->
                                {error, nil}
                        end,
                        fun(_use0@1) ->
                            {User@2, Password@1} = _use0@1,
                            case gleam@string:split(Path@1, <<"/"/utf8>>) of
                                [<<""/utf8>>, Database] ->
                                    {ok,
                                        erlang:setelement(
                                            6,
                                            erlang:setelement(
                                                5,
                                                erlang:setelement(
                                                    4,
                                                    erlang:setelement(
                                                        3,
                                                        erlang:setelement(
                                                            2,
                                                            default_config(),
                                                            Host@1
                                                        ),
                                                        Db_port@1
                                                    ),
                                                    Database
                                                ),
                                                User@2
                                            ),
                                            Password@1
                                        )};

                                _ ->
                                    {error, nil}
                            end
                        end
                    )
                end) end
    ).

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 140).
-spec connect(config()) -> connection().
connect(A) ->
    gleam_pgo_ffi:connect(A).

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 144).
-spec disconnect(connection()) -> nil.
disconnect(A) ->
    gleam_pgo_ffi:disconnect(A).

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 151).
-spec null() -> value().
null() ->
    gleam_pgo_ffi:null().

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 154).
-spec bool(boolean()) -> value().
bool(A) ->
    gleam_pgo_ffi:coerce(A).

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 157).
-spec int(integer()) -> value().
int(A) ->
    gleam_pgo_ffi:coerce(A).

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 160).
-spec float(float()) -> value().
float(A) ->
    gleam_pgo_ffi:coerce(A).

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 163).
-spec text(binary()) -> value().
text(A) ->
    gleam_pgo_ffi:coerce(A).

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 166).
-spec bytea(bitstring()) -> value().
bytea(A) ->
    gleam_pgo_ffi:coerce(A).

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 169).
-spec array(list(any())) -> value().
array(A) ->
    gleam_pgo_ffi:coerce(A).

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 173).
-spec timestamp(
    {{integer(), integer(), integer()}, {integer(), integer(), integer()}}
) -> value().
timestamp(A) ->
    gleam_pgo_ffi:coerce(A).

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 177).
-spec date({integer(), integer(), integer()}) -> value().
date(A) ->
    gleam_pgo_ffi:coerce(A).

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 191).
-spec transaction(
    connection(),
    fun((connection()) -> {ok, LPS} | {error, binary()})
) -> {ok, LPS} | {error, transaction_error()}.
transaction(Pool, Callback) ->
    gleam_pgo_ffi:transaction(Pool, Callback).

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 196).
-spec nullable(fun((LPX) -> value()), gleam@option:option(LPX)) -> value().
nullable(Inner_type, Value) ->
    case Value of
        {some, Term} ->
            Inner_type(Term);

        none ->
            gleam_pgo_ffi:null()
    end.

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 241).
-spec execute(
    binary(),
    connection(),
    list(value()),
    fun((gleam@dynamic:dynamic_()) -> {ok, LQE} |
        {error, list(gleam@dynamic:decode_error())})
) -> {ok, returned(LQE)} | {error, query_error()}.
execute(Sql, Pool, Arguments, Decoder) ->
    gleam@result:then(
        gleam_pgo_ffi:'query'(Pool, Sql, Arguments),
        fun(_use0) ->
            {Count, Rows} = _use0,
            gleam@result:then(
                begin
                    _pipe = gleam@list:try_map(Rows, Decoder),
                    gleam@result:map_error(
                        _pipe,
                        fun(Field@0) -> {unexpected_result_type, Field@0} end
                    )
                end,
                fun(Rows@1) -> {ok, {returned, Count, Rows@1}} end
            )
        end
    ).

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 263).
-spec error_code_name(binary()) -> {ok, binary()} | {error, nil}.
error_code_name(Error_code) ->
    case Error_code of
        <<"00000"/utf8>> ->
            {ok, <<"successful_completion"/utf8>>};

        <<"01000"/utf8>> ->
            {ok, <<"warning"/utf8>>};

        <<"0100C"/utf8>> ->
            {ok, <<"dynamic_result_sets_returned"/utf8>>};

        <<"01008"/utf8>> ->
            {ok, <<"implicit_zero_bit_padding"/utf8>>};

        <<"01003"/utf8>> ->
            {ok, <<"null_value_eliminated_in_set_function"/utf8>>};

        <<"01007"/utf8>> ->
            {ok, <<"privilege_not_granted"/utf8>>};

        <<"01006"/utf8>> ->
            {ok, <<"privilege_not_revoked"/utf8>>};

        <<"01004"/utf8>> ->
            {ok, <<"string_data_right_truncation"/utf8>>};

        <<"01P01"/utf8>> ->
            {ok, <<"deprecated_feature"/utf8>>};

        <<"02000"/utf8>> ->
            {ok, <<"no_data"/utf8>>};

        <<"02001"/utf8>> ->
            {ok, <<"no_additional_dynamic_result_sets_returned"/utf8>>};

        <<"03000"/utf8>> ->
            {ok, <<"sql_statement_not_yet_complete"/utf8>>};

        <<"08000"/utf8>> ->
            {ok, <<"connection_exception"/utf8>>};

        <<"08003"/utf8>> ->
            {ok, <<"connection_does_not_exist"/utf8>>};

        <<"08006"/utf8>> ->
            {ok, <<"connection_failure"/utf8>>};

        <<"08001"/utf8>> ->
            {ok, <<"sqlclient_unable_to_establish_sqlconnection"/utf8>>};

        <<"08004"/utf8>> ->
            {ok, <<"sqlserver_rejected_establishment_of_sqlconnection"/utf8>>};

        <<"08007"/utf8>> ->
            {ok, <<"transaction_resolution_unknown"/utf8>>};

        <<"08P01"/utf8>> ->
            {ok, <<"protocol_violation"/utf8>>};

        <<"09000"/utf8>> ->
            {ok, <<"triggered_action_exception"/utf8>>};

        <<"0A000"/utf8>> ->
            {ok, <<"feature_not_supported"/utf8>>};

        <<"0B000"/utf8>> ->
            {ok, <<"invalid_transaction_initiation"/utf8>>};

        <<"0F000"/utf8>> ->
            {ok, <<"locator_exception"/utf8>>};

        <<"0F001"/utf8>> ->
            {ok, <<"invalid_locator_specification"/utf8>>};

        <<"0L000"/utf8>> ->
            {ok, <<"invalid_grantor"/utf8>>};

        <<"0LP01"/utf8>> ->
            {ok, <<"invalid_grant_operation"/utf8>>};

        <<"0P000"/utf8>> ->
            {ok, <<"invalid_role_specification"/utf8>>};

        <<"0Z000"/utf8>> ->
            {ok, <<"diagnostics_exception"/utf8>>};

        <<"0Z002"/utf8>> ->
            {ok, <<"stacked_diagnostics_accessed_without_active_handler"/utf8>>};

        <<"20000"/utf8>> ->
            {ok, <<"case_not_found"/utf8>>};

        <<"21000"/utf8>> ->
            {ok, <<"cardinality_violation"/utf8>>};

        <<"22000"/utf8>> ->
            {ok, <<"data_exception"/utf8>>};

        <<"2202E"/utf8>> ->
            {ok, <<"array_subscript_error"/utf8>>};

        <<"22021"/utf8>> ->
            {ok, <<"character_not_in_repertoire"/utf8>>};

        <<"22008"/utf8>> ->
            {ok, <<"datetime_field_overflow"/utf8>>};

        <<"22012"/utf8>> ->
            {ok, <<"division_by_zero"/utf8>>};

        <<"22005"/utf8>> ->
            {ok, <<"error_in_assignment"/utf8>>};

        <<"2200B"/utf8>> ->
            {ok, <<"escape_character_conflict"/utf8>>};

        <<"22022"/utf8>> ->
            {ok, <<"indicator_overflow"/utf8>>};

        <<"22015"/utf8>> ->
            {ok, <<"interval_field_overflow"/utf8>>};

        <<"2201E"/utf8>> ->
            {ok, <<"invalid_argument_for_logarithm"/utf8>>};

        <<"22014"/utf8>> ->
            {ok, <<"invalid_argument_for_ntile_function"/utf8>>};

        <<"22016"/utf8>> ->
            {ok, <<"invalid_argument_for_nth_value_function"/utf8>>};

        <<"2201F"/utf8>> ->
            {ok, <<"invalid_argument_for_power_function"/utf8>>};

        <<"2201G"/utf8>> ->
            {ok, <<"invalid_argument_for_width_bucket_function"/utf8>>};

        <<"22018"/utf8>> ->
            {ok, <<"invalid_character_value_for_cast"/utf8>>};

        <<"22007"/utf8>> ->
            {ok, <<"invalid_datetime_format"/utf8>>};

        <<"22019"/utf8>> ->
            {ok, <<"invalid_escape_character"/utf8>>};

        <<"2200D"/utf8>> ->
            {ok, <<"invalid_escape_octet"/utf8>>};

        <<"22025"/utf8>> ->
            {ok, <<"invalid_escape_sequence"/utf8>>};

        <<"22P06"/utf8>> ->
            {ok, <<"nonstandard_use_of_escape_character"/utf8>>};

        <<"22010"/utf8>> ->
            {ok, <<"invalid_indicator_parameter_value"/utf8>>};

        <<"22023"/utf8>> ->
            {ok, <<"invalid_parameter_value"/utf8>>};

        <<"22013"/utf8>> ->
            {ok, <<"invalid_preceding_or_following_size"/utf8>>};

        <<"2201B"/utf8>> ->
            {ok, <<"invalid_regular_expression"/utf8>>};

        <<"2201W"/utf8>> ->
            {ok, <<"invalid_row_count_in_limit_clause"/utf8>>};

        <<"2201X"/utf8>> ->
            {ok, <<"invalid_row_count_in_result_offset_clause"/utf8>>};

        <<"2202H"/utf8>> ->
            {ok, <<"invalid_tablesample_argument"/utf8>>};

        <<"2202G"/utf8>> ->
            {ok, <<"invalid_tablesample_repeat"/utf8>>};

        <<"22009"/utf8>> ->
            {ok, <<"invalid_time_zone_displacement_value"/utf8>>};

        <<"2200C"/utf8>> ->
            {ok, <<"invalid_use_of_escape_character"/utf8>>};

        <<"2200G"/utf8>> ->
            {ok, <<"most_specific_type_mismatch"/utf8>>};

        <<"22004"/utf8>> ->
            {ok, <<"null_value_not_allowed"/utf8>>};

        <<"22002"/utf8>> ->
            {ok, <<"null_value_no_indicator_parameter"/utf8>>};

        <<"22003"/utf8>> ->
            {ok, <<"numeric_value_out_of_range"/utf8>>};

        <<"2200H"/utf8>> ->
            {ok, <<"sequence_generator_limit_exceeded"/utf8>>};

        <<"22026"/utf8>> ->
            {ok, <<"string_data_length_mismatch"/utf8>>};

        <<"22001"/utf8>> ->
            {ok, <<"string_data_right_truncation"/utf8>>};

        <<"22011"/utf8>> ->
            {ok, <<"substring_error"/utf8>>};

        <<"22027"/utf8>> ->
            {ok, <<"trim_error"/utf8>>};

        <<"22024"/utf8>> ->
            {ok, <<"unterminated_c_string"/utf8>>};

        <<"2200F"/utf8>> ->
            {ok, <<"zero_length_character_string"/utf8>>};

        <<"22P01"/utf8>> ->
            {ok, <<"floating_point_exception"/utf8>>};

        <<"22P02"/utf8>> ->
            {ok, <<"invalid_text_representation"/utf8>>};

        <<"22P03"/utf8>> ->
            {ok, <<"invalid_binary_representation"/utf8>>};

        <<"22P04"/utf8>> ->
            {ok, <<"bad_copy_file_format"/utf8>>};

        <<"22P05"/utf8>> ->
            {ok, <<"untranslatable_character"/utf8>>};

        <<"2200L"/utf8>> ->
            {ok, <<"not_an_xml_document"/utf8>>};

        <<"2200M"/utf8>> ->
            {ok, <<"invalid_xml_document"/utf8>>};

        <<"2200N"/utf8>> ->
            {ok, <<"invalid_xml_content"/utf8>>};

        <<"2200S"/utf8>> ->
            {ok, <<"invalid_xml_comment"/utf8>>};

        <<"2200T"/utf8>> ->
            {ok, <<"invalid_xml_processing_instruction"/utf8>>};

        <<"22030"/utf8>> ->
            {ok, <<"duplicate_json_object_key_value"/utf8>>};

        <<"22031"/utf8>> ->
            {ok, <<"invalid_argument_for_sql_json_datetime_function"/utf8>>};

        <<"22032"/utf8>> ->
            {ok, <<"invalid_json_text"/utf8>>};

        <<"22033"/utf8>> ->
            {ok, <<"invalid_sql_json_subscript"/utf8>>};

        <<"22034"/utf8>> ->
            {ok, <<"more_than_one_sql_json_item"/utf8>>};

        <<"22035"/utf8>> ->
            {ok, <<"no_sql_json_item"/utf8>>};

        <<"22036"/utf8>> ->
            {ok, <<"non_numeric_sql_json_item"/utf8>>};

        <<"22037"/utf8>> ->
            {ok, <<"non_unique_keys_in_a_json_object"/utf8>>};

        <<"22038"/utf8>> ->
            {ok, <<"singleton_sql_json_item_required"/utf8>>};

        <<"22039"/utf8>> ->
            {ok, <<"sql_json_array_not_found"/utf8>>};

        <<"2203A"/utf8>> ->
            {ok, <<"sql_json_member_not_found"/utf8>>};

        <<"2203B"/utf8>> ->
            {ok, <<"sql_json_number_not_found"/utf8>>};

        <<"2203C"/utf8>> ->
            {ok, <<"sql_json_object_not_found"/utf8>>};

        <<"2203D"/utf8>> ->
            {ok, <<"too_many_json_array_elements"/utf8>>};

        <<"2203E"/utf8>> ->
            {ok, <<"too_many_json_object_members"/utf8>>};

        <<"2203F"/utf8>> ->
            {ok, <<"sql_json_scalar_required"/utf8>>};

        <<"23000"/utf8>> ->
            {ok, <<"integrity_constraint_violation"/utf8>>};

        <<"23001"/utf8>> ->
            {ok, <<"restrict_violation"/utf8>>};

        <<"23502"/utf8>> ->
            {ok, <<"not_null_violation"/utf8>>};

        <<"23503"/utf8>> ->
            {ok, <<"foreign_key_violation"/utf8>>};

        <<"23505"/utf8>> ->
            {ok, <<"unique_violation"/utf8>>};

        <<"23514"/utf8>> ->
            {ok, <<"check_violation"/utf8>>};

        <<"23P01"/utf8>> ->
            {ok, <<"exclusion_violation"/utf8>>};

        <<"24000"/utf8>> ->
            {ok, <<"invalid_cursor_state"/utf8>>};

        <<"25000"/utf8>> ->
            {ok, <<"invalid_transaction_state"/utf8>>};

        <<"25001"/utf8>> ->
            {ok, <<"active_sql_transaction"/utf8>>};

        <<"25002"/utf8>> ->
            {ok, <<"branch_transaction_already_active"/utf8>>};

        <<"25008"/utf8>> ->
            {ok, <<"held_cursor_requires_same_isolation_level"/utf8>>};

        <<"25003"/utf8>> ->
            {ok, <<"inappropriate_access_mode_for_branch_transaction"/utf8>>};

        <<"25004"/utf8>> ->
            {ok,
                <<"inappropriate_isolation_level_for_branch_transaction"/utf8>>};

        <<"25005"/utf8>> ->
            {ok, <<"no_active_sql_transaction_for_branch_transaction"/utf8>>};

        <<"25006"/utf8>> ->
            {ok, <<"read_only_sql_transaction"/utf8>>};

        <<"25007"/utf8>> ->
            {ok, <<"schema_and_data_statement_mixing_not_supported"/utf8>>};

        <<"25P01"/utf8>> ->
            {ok, <<"no_active_sql_transaction"/utf8>>};

        <<"25P02"/utf8>> ->
            {ok, <<"in_failed_sql_transaction"/utf8>>};

        <<"25P03"/utf8>> ->
            {ok, <<"idle_in_transaction_session_timeout"/utf8>>};

        <<"26000"/utf8>> ->
            {ok, <<"invalid_sql_statement_name"/utf8>>};

        <<"27000"/utf8>> ->
            {ok, <<"triggered_data_change_violation"/utf8>>};

        <<"28000"/utf8>> ->
            {ok, <<"invalid_authorization_specification"/utf8>>};

        <<"28P01"/utf8>> ->
            {ok, <<"invalid_password"/utf8>>};

        <<"2B000"/utf8>> ->
            {ok, <<"dependent_privilege_descriptors_still_exist"/utf8>>};

        <<"2BP01"/utf8>> ->
            {ok, <<"dependent_objects_still_exist"/utf8>>};

        <<"2D000"/utf8>> ->
            {ok, <<"invalid_transaction_termination"/utf8>>};

        <<"2F000"/utf8>> ->
            {ok, <<"sql_routine_exception"/utf8>>};

        <<"2F005"/utf8>> ->
            {ok, <<"function_executed_no_return_statement"/utf8>>};

        <<"2F002"/utf8>> ->
            {ok, <<"modifying_sql_data_not_permitted"/utf8>>};

        <<"2F003"/utf8>> ->
            {ok, <<"prohibited_sql_statement_attempted"/utf8>>};

        <<"2F004"/utf8>> ->
            {ok, <<"reading_sql_data_not_permitted"/utf8>>};

        <<"34000"/utf8>> ->
            {ok, <<"invalid_cursor_name"/utf8>>};

        <<"38000"/utf8>> ->
            {ok, <<"external_routine_exception"/utf8>>};

        <<"38001"/utf8>> ->
            {ok, <<"containing_sql_not_permitted"/utf8>>};

        <<"38002"/utf8>> ->
            {ok, <<"modifying_sql_data_not_permitted"/utf8>>};

        <<"38003"/utf8>> ->
            {ok, <<"prohibited_sql_statement_attempted"/utf8>>};

        <<"38004"/utf8>> ->
            {ok, <<"reading_sql_data_not_permitted"/utf8>>};

        <<"39000"/utf8>> ->
            {ok, <<"external_routine_invocation_exception"/utf8>>};

        <<"39001"/utf8>> ->
            {ok, <<"invalid_sqlstate_returned"/utf8>>};

        <<"39004"/utf8>> ->
            {ok, <<"null_value_not_allowed"/utf8>>};

        <<"39P01"/utf8>> ->
            {ok, <<"trigger_protocol_violated"/utf8>>};

        <<"39P02"/utf8>> ->
            {ok, <<"srf_protocol_violated"/utf8>>};

        <<"39P03"/utf8>> ->
            {ok, <<"event_trigger_protocol_violated"/utf8>>};

        <<"3B000"/utf8>> ->
            {ok, <<"savepoint_exception"/utf8>>};

        <<"3B001"/utf8>> ->
            {ok, <<"invalid_savepoint_specification"/utf8>>};

        <<"3D000"/utf8>> ->
            {ok, <<"invalid_catalog_name"/utf8>>};

        <<"3F000"/utf8>> ->
            {ok, <<"invalid_schema_name"/utf8>>};

        <<"40000"/utf8>> ->
            {ok, <<"transaction_rollback"/utf8>>};

        <<"40002"/utf8>> ->
            {ok, <<"transaction_integrity_constraint_violation"/utf8>>};

        <<"40001"/utf8>> ->
            {ok, <<"serialization_failure"/utf8>>};

        <<"40003"/utf8>> ->
            {ok, <<"statement_completion_unknown"/utf8>>};

        <<"40P01"/utf8>> ->
            {ok, <<"deadlock_detected"/utf8>>};

        <<"42000"/utf8>> ->
            {ok, <<"syntax_error_or_access_rule_violation"/utf8>>};

        <<"42601"/utf8>> ->
            {ok, <<"syntax_error"/utf8>>};

        <<"42501"/utf8>> ->
            {ok, <<"insufficient_privilege"/utf8>>};

        <<"42846"/utf8>> ->
            {ok, <<"cannot_coerce"/utf8>>};

        <<"42803"/utf8>> ->
            {ok, <<"grouping_error"/utf8>>};

        <<"42P20"/utf8>> ->
            {ok, <<"windowing_error"/utf8>>};

        <<"42P19"/utf8>> ->
            {ok, <<"invalid_recursion"/utf8>>};

        <<"42830"/utf8>> ->
            {ok, <<"invalid_foreign_key"/utf8>>};

        <<"42602"/utf8>> ->
            {ok, <<"invalid_name"/utf8>>};

        <<"42622"/utf8>> ->
            {ok, <<"name_too_long"/utf8>>};

        <<"42939"/utf8>> ->
            {ok, <<"reserved_name"/utf8>>};

        <<"42804"/utf8>> ->
            {ok, <<"datatype_mismatch"/utf8>>};

        <<"42P18"/utf8>> ->
            {ok, <<"indeterminate_datatype"/utf8>>};

        <<"42P21"/utf8>> ->
            {ok, <<"collation_mismatch"/utf8>>};

        <<"42P22"/utf8>> ->
            {ok, <<"indeterminate_collation"/utf8>>};

        <<"42809"/utf8>> ->
            {ok, <<"wrong_object_type"/utf8>>};

        <<"428C9"/utf8>> ->
            {ok, <<"generated_always"/utf8>>};

        <<"42703"/utf8>> ->
            {ok, <<"undefined_column"/utf8>>};

        <<"42883"/utf8>> ->
            {ok, <<"undefined_function"/utf8>>};

        <<"42P01"/utf8>> ->
            {ok, <<"undefined_table"/utf8>>};

        <<"42P02"/utf8>> ->
            {ok, <<"undefined_parameter"/utf8>>};

        <<"42704"/utf8>> ->
            {ok, <<"undefined_object"/utf8>>};

        <<"42701"/utf8>> ->
            {ok, <<"duplicate_column"/utf8>>};

        <<"42P03"/utf8>> ->
            {ok, <<"duplicate_cursor"/utf8>>};

        <<"42P04"/utf8>> ->
            {ok, <<"duplicate_database"/utf8>>};

        <<"42723"/utf8>> ->
            {ok, <<"duplicate_function"/utf8>>};

        <<"42P05"/utf8>> ->
            {ok, <<"duplicate_prepared_statement"/utf8>>};

        <<"42P06"/utf8>> ->
            {ok, <<"duplicate_schema"/utf8>>};

        <<"42P07"/utf8>> ->
            {ok, <<"duplicate_table"/utf8>>};

        <<"42712"/utf8>> ->
            {ok, <<"duplicate_alias"/utf8>>};

        <<"42710"/utf8>> ->
            {ok, <<"duplicate_object"/utf8>>};

        <<"42702"/utf8>> ->
            {ok, <<"ambiguous_column"/utf8>>};

        <<"42725"/utf8>> ->
            {ok, <<"ambiguous_function"/utf8>>};

        <<"42P08"/utf8>> ->
            {ok, <<"ambiguous_parameter"/utf8>>};

        <<"42P09"/utf8>> ->
            {ok, <<"ambiguous_alias"/utf8>>};

        <<"42P10"/utf8>> ->
            {ok, <<"invalid_column_reference"/utf8>>};

        <<"42611"/utf8>> ->
            {ok, <<"invalid_column_definition"/utf8>>};

        <<"42P11"/utf8>> ->
            {ok, <<"invalid_cursor_definition"/utf8>>};

        <<"42P12"/utf8>> ->
            {ok, <<"invalid_database_definition"/utf8>>};

        <<"42P13"/utf8>> ->
            {ok, <<"invalid_function_definition"/utf8>>};

        <<"42P14"/utf8>> ->
            {ok, <<"invalid_prepared_statement_definition"/utf8>>};

        <<"42P15"/utf8>> ->
            {ok, <<"invalid_schema_definition"/utf8>>};

        <<"42P16"/utf8>> ->
            {ok, <<"invalid_table_definition"/utf8>>};

        <<"42P17"/utf8>> ->
            {ok, <<"invalid_object_definition"/utf8>>};

        <<"44000"/utf8>> ->
            {ok, <<"with_check_option_violation"/utf8>>};

        <<"53000"/utf8>> ->
            {ok, <<"insufficient_resources"/utf8>>};

        <<"53100"/utf8>> ->
            {ok, <<"disk_full"/utf8>>};

        <<"53200"/utf8>> ->
            {ok, <<"out_of_memory"/utf8>>};

        <<"53300"/utf8>> ->
            {ok, <<"too_many_connections"/utf8>>};

        <<"53400"/utf8>> ->
            {ok, <<"configuration_limit_exceeded"/utf8>>};

        <<"54000"/utf8>> ->
            {ok, <<"program_limit_exceeded"/utf8>>};

        <<"54001"/utf8>> ->
            {ok, <<"statement_too_complex"/utf8>>};

        <<"54011"/utf8>> ->
            {ok, <<"too_many_columns"/utf8>>};

        <<"54023"/utf8>> ->
            {ok, <<"too_many_arguments"/utf8>>};

        <<"55000"/utf8>> ->
            {ok, <<"object_not_in_prerequisite_state"/utf8>>};

        <<"55006"/utf8>> ->
            {ok, <<"object_in_use"/utf8>>};

        <<"55P02"/utf8>> ->
            {ok, <<"cant_change_runtime_param"/utf8>>};

        <<"55P03"/utf8>> ->
            {ok, <<"lock_not_available"/utf8>>};

        <<"55P04"/utf8>> ->
            {ok, <<"unsafe_new_enum_value_usage"/utf8>>};

        <<"57000"/utf8>> ->
            {ok, <<"operator_intervention"/utf8>>};

        <<"57014"/utf8>> ->
            {ok, <<"query_canceled"/utf8>>};

        <<"57P01"/utf8>> ->
            {ok, <<"admin_shutdown"/utf8>>};

        <<"57P02"/utf8>> ->
            {ok, <<"crash_shutdown"/utf8>>};

        <<"57P03"/utf8>> ->
            {ok, <<"cannot_connect_now"/utf8>>};

        <<"57P04"/utf8>> ->
            {ok, <<"database_dropped"/utf8>>};

        <<"57P05"/utf8>> ->
            {ok, <<"idle_session_timeout"/utf8>>};

        <<"58000"/utf8>> ->
            {ok, <<"system_error"/utf8>>};

        <<"58030"/utf8>> ->
            {ok, <<"io_error"/utf8>>};

        <<"58P01"/utf8>> ->
            {ok, <<"undefined_file"/utf8>>};

        <<"58P02"/utf8>> ->
            {ok, <<"duplicate_file"/utf8>>};

        <<"72000"/utf8>> ->
            {ok, <<"snapshot_too_old"/utf8>>};

        <<"F0000"/utf8>> ->
            {ok, <<"config_file_error"/utf8>>};

        <<"F0001"/utf8>> ->
            {ok, <<"lock_file_exists"/utf8>>};

        <<"HV000"/utf8>> ->
            {ok, <<"fdw_error"/utf8>>};

        <<"HV005"/utf8>> ->
            {ok, <<"fdw_column_name_not_found"/utf8>>};

        <<"HV002"/utf8>> ->
            {ok, <<"fdw_dynamic_parameter_value_needed"/utf8>>};

        <<"HV010"/utf8>> ->
            {ok, <<"fdw_function_sequence_error"/utf8>>};

        <<"HV021"/utf8>> ->
            {ok, <<"fdw_inconsistent_descriptor_information"/utf8>>};

        <<"HV024"/utf8>> ->
            {ok, <<"fdw_invalid_attribute_value"/utf8>>};

        <<"HV007"/utf8>> ->
            {ok, <<"fdw_invalid_column_name"/utf8>>};

        <<"HV008"/utf8>> ->
            {ok, <<"fdw_invalid_column_number"/utf8>>};

        <<"HV004"/utf8>> ->
            {ok, <<"fdw_invalid_data_type"/utf8>>};

        <<"HV006"/utf8>> ->
            {ok, <<"fdw_invalid_data_type_descriptors"/utf8>>};

        <<"HV091"/utf8>> ->
            {ok, <<"fdw_invalid_descriptor_field_identifier"/utf8>>};

        <<"HV00B"/utf8>> ->
            {ok, <<"fdw_invalid_handle"/utf8>>};

        <<"HV00C"/utf8>> ->
            {ok, <<"fdw_invalid_option_index"/utf8>>};

        <<"HV00D"/utf8>> ->
            {ok, <<"fdw_invalid_option_name"/utf8>>};

        <<"HV090"/utf8>> ->
            {ok, <<"fdw_invalid_string_length_or_buffer_length"/utf8>>};

        <<"HV00A"/utf8>> ->
            {ok, <<"fdw_invalid_string_format"/utf8>>};

        <<"HV009"/utf8>> ->
            {ok, <<"fdw_invalid_use_of_null_pointer"/utf8>>};

        <<"HV014"/utf8>> ->
            {ok, <<"fdw_too_many_handles"/utf8>>};

        <<"HV001"/utf8>> ->
            {ok, <<"fdw_out_of_memory"/utf8>>};

        <<"HV00P"/utf8>> ->
            {ok, <<"fdw_no_schemas"/utf8>>};

        <<"HV00J"/utf8>> ->
            {ok, <<"fdw_option_name_not_found"/utf8>>};

        <<"HV00K"/utf8>> ->
            {ok, <<"fdw_reply_handle"/utf8>>};

        <<"HV00Q"/utf8>> ->
            {ok, <<"fdw_schema_not_found"/utf8>>};

        <<"HV00R"/utf8>> ->
            {ok, <<"fdw_table_not_found"/utf8>>};

        <<"HV00L"/utf8>> ->
            {ok, <<"fdw_unable_to_create_execution"/utf8>>};

        <<"HV00M"/utf8>> ->
            {ok, <<"fdw_unable_to_create_reply"/utf8>>};

        <<"HV00N"/utf8>> ->
            {ok, <<"fdw_unable_to_establish_connection"/utf8>>};

        <<"P0000"/utf8>> ->
            {ok, <<"plpgsql_error"/utf8>>};

        <<"P0001"/utf8>> ->
            {ok, <<"raise_exception"/utf8>>};

        <<"P0002"/utf8>> ->
            {ok, <<"no_data_found"/utf8>>};

        <<"P0003"/utf8>> ->
            {ok, <<"too_many_rows"/utf8>>};

        <<"P0004"/utf8>> ->
            {ok, <<"assert_failure"/utf8>>};

        <<"XX000"/utf8>> ->
            {ok, <<"internal_error"/utf8>>};

        <<"XX001"/utf8>> ->
            {ok, <<"data_corrupted"/utf8>>};

        <<"XX002"/utf8>> ->
            {ok, <<"index_corrupted"/utf8>>};

        _ ->
            {error, nil}
    end.

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 531).
-spec decode_timestamp(gleam@dynamic:dynamic_()) -> {ok,
        {{integer(), integer(), integer()}, {integer(), integer(), integer()}}} |
    {error, list(gleam@dynamic:decode_error())}.
decode_timestamp(Value) ->
    (gleam@dynamic:tuple2(
        gleam@dynamic:tuple3(
            fun gleam@dynamic:int/1,
            fun gleam@dynamic:int/1,
            fun gleam@dynamic:int/1
        ),
        gleam@dynamic:tuple3(
            fun gleam@dynamic:int/1,
            fun gleam@dynamic:int/1,
            fun gleam@dynamic:int/1
        )
    ))(Value).

-file("/var/www/build/packages/gleam_pgo/src/gleam/pgo.gleam", 540).
-spec decode_date(gleam@dynamic:dynamic_()) -> {ok,
        {integer(), integer(), integer()}} |
    {error, list(gleam@dynamic:decode_error())}.
decode_date(Value) ->
    (gleam@dynamic:tuple3(
        fun gleam@dynamic:int/1,
        fun gleam@dynamic:int/1,
        fun gleam@dynamic:int/1
    ))(Value).
