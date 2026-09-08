import gleam/dynamic
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/option.{Some}
import gleam/pgo
import gleam/result
import glenvy/env

const max_attempts = 60

const delay_ms = 2000

const pool_warmup_ms = 500

pub fn main() {
  io.println("Running database migration...")

  case migrate_with_retry() {
    Ok(_) -> io.println("Migration completed successfully.")
    Error(msg) -> {
      io.println_error("Migration failed: " <> msg)
      process.send_abnormal_exit(process.self(), msg)
    }
  }
}

fn migrate_with_retry() -> Result(Nil, String) {
  use config <- result.try(read_db_config())
  attempt_loop(config, 1)
}

fn read_db_config() -> Result(pgo.Config, String) {
  use host <- result.try(get_env("DB_HOST"))
  use port_str <- result.try(get_env("DB_PORT"))
  use port <- result.try(
    int.parse(port_str)
    |> result.map_error(fn(_) { "DB_PORT is not a valid integer" }),
  )
  use user <- result.try(get_env("DB_USER"))
  use password <- result.try(get_env("DB_PASS"))
  use database <- result.try(get_env("DB_NAME"))

  Ok(pgo.Config(
    ..pgo.default_config(),
    host: host,
    port: port,
    user: user,
    password: Some(password),
    database: database,
    pool_size: 1,
  ))
}

fn get_env(name: String) -> Result(String, String) {
  env.get_string(name)
  |> result.map_error(fn(_) { name <> " environment variable not set" })
}

fn attempt_loop(config: pgo.Config, attempt: Int) -> Result(Nil, String) {
  case run_migration(config) {
    Ok(_) -> Ok(Nil)
    Error(err) ->
      case attempt >= max_attempts {
        True ->
          Error(
            "Failed after "
            <> int.to_string(max_attempts)
            <> " attempts: "
            <> err,
          )
        False -> {
          io.println(
            "Database not ready (attempt "
            <> int.to_string(attempt)
            <> "/"
            <> int.to_string(max_attempts)
            <> "): "
            <> err,
          )
          process.sleep(delay_ms)
          attempt_loop(config, attempt + 1)
        }
      }
  }
}

fn run_migration(config: pgo.Config) -> Result(Nil, String) {
  let db = pgo.connect(config)
  process.sleep(pool_warmup_ms)

  use _ <- result.try(execute_sql(
    db,
    "CREATE TABLE IF NOT EXISTS greetings (
       id INTEGER PRIMARY KEY,
       message TEXT NOT NULL
     )",
  ))
  use _ <- result.try(execute_sql(
    db,
    "INSERT INTO greetings (id, message)
     VALUES (1, 'Hello from Zerops!')
     ON CONFLICT (id) DO NOTHING",
  ))

  pgo.disconnect(db)
  Ok(Nil)
}

fn execute_sql(db: pgo.Connection, sql: String) -> Result(Nil, String) {
  pgo.execute(sql, db, [], dynamic.dynamic)
  |> result.map(fn(_) { Nil })
  |> result.map_error(pgo_error_to_string)
}

fn pgo_error_to_string(error: pgo.QueryError) -> String {
  case error {
    pgo.ConnectionUnavailable -> "connection unavailable"
    pgo.ConstraintViolated(message: msg, constraint: c, detail: _) ->
      "constraint violated (" <> c <> "): " <> msg
    pgo.PostgresqlError(code: _, name: _, message: msg) -> msg
    pgo.UnexpectedArgumentCount(expected: e, got: g) ->
      "wrong argument count: expected "
      <> int.to_string(e)
      <> ", got "
      <> int.to_string(g)
    pgo.UnexpectedArgumentType(expected: e, got: g) ->
      "wrong argument type: expected " <> e <> ", got " <> g
    pgo.UnexpectedResultType(_) -> "unexpected result type"
  }
}
