import gleam/dynamic
import gleam/erlang/process
import gleam/http
import gleam/int
import gleam/io
import gleam/json
import gleam/option.{Some}
import gleam/pgo
import gleam/result
import glenvy/env
import mist
import wisp.{type Request, type Response}
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()

  let assert Ok(db) = connect_db()
  io.println("Database connected — starting server on :3000")

  let secret_key_base = wisp.random_string(64)

  let assert Ok(_) =
    fn(req: Request) -> Response { handle_request(req, db) }
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(3000)
    |> mist.start_http

  process.sleep_forever()
}

fn connect_db() -> Result(pgo.Connection, String) {
  use host <- result.try(get_env("DB_HOST"))
  use port_str <- result.try(get_env("DB_PORT"))
  use port <- result.try(
    int.parse(port_str)
    |> result.map_error(fn(_) { "DB_PORT is not a valid integer" }),
  )
  use user <- result.try(get_env("DB_USER"))
  use password <- result.try(get_env("DB_PASS"))
  use database <- result.try(get_env("DB_NAME"))

  Ok(
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        host: host,
        port: port,
        user: user,
        password: Some(password),
        database: database,
        pool_size: 2,
      ),
    ),
  )
}

fn get_env(name: String) -> Result(String, String) {
  env.get_string(name)
  |> result.map_error(fn(_) { name <> " environment variable not set" })
}

fn handle_request(req: Request, db: pgo.Connection) -> Response {
  case req.method, wisp.path_segments(req) {
    http.Get, [] -> health_check(db)
    _, _ -> wisp.not_found()
  }
}

fn health_check(db: pgo.Connection) -> Response {
  case query_greeting(db) {
    Ok(greeting) ->
      wisp.json_response(
        json.to_string_builder(
          json.object([
            #("type", json.string("gleam")),
            #("greeting", json.string(greeting)),
            #("status", json.object([#("database", json.string("OK"))])),
          ]),
        ),
        200,
      )
    Error(err) ->
      wisp.json_response(
        json.to_string_builder(
          json.object([
            #("type", json.string("gleam")),
            #("greeting", json.null()),
            #(
              "status",
              json.object([#("database", json.string("ERROR: " <> err))]),
            ),
          ]),
        ),
        503,
      )
  }
}

fn query_greeting(db: pgo.Connection) -> Result(String, String) {
  pgo.execute(
    "SELECT message FROM greetings LIMIT 1",
    db,
    [],
    fn(row) { dynamic.element(0, dynamic.string)(row) },
  )
  |> result.map_error(pgo_error_to_string)
  |> result.then(fn(returned) {
    case returned.rows {
      [message, ..] -> Ok(message)
      [] -> Error("greetings table is empty — migration may not have run")
    }
  })
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
