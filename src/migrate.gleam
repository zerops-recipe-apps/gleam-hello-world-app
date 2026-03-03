import gleam/dynamic
import gleam/int
import gleam/io
import gleam/option.{Some}
import gleam/pgo
import glenvy/env

pub fn main() {
  io.println("Running database migration...")

  let assert Ok(host) = env.get_string("DB_HOST")
  let assert Ok(port_str) = env.get_string("DB_PORT")
  let assert Ok(port) = int.parse(port_str)
  let assert Ok(user) = env.get_string("DB_USER")
  let assert Ok(password) = env.get_string("DB_PASS")
  let assert Ok(database) = env.get_string("DB_NAME")

  let db =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        host: host,
        port: port,
        user: user,
        password: Some(password),
        database: database,
        pool_size: 1,
      ),
    )

  let assert Ok(_) =
    pgo.execute(
      "CREATE TABLE IF NOT EXISTS greetings (
         id INTEGER PRIMARY KEY,
         message TEXT NOT NULL
       )",
      db,
      [],
      dynamic.dynamic,
    )

  let assert Ok(_) =
    pgo.execute(
      "INSERT INTO greetings (id, message)
       VALUES (1, 'Hello from Zerops!')
       ON CONFLICT (id) DO NOTHING",
      db,
      [],
      dynamic.dynamic,
    )

  pgo.disconnect(db)
  io.println("Migration complete.")
}
