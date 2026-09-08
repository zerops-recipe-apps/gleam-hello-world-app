#!/bin/sh
# Run the Gleam migration module in the context of the Erlang shipment.
# Loads all compiled BEAM files from the shipment and evaluates the
# migrate module's main function, then stops the Erlang VM.
#
# Retry logic lives in src/migrate.gleam so connection errors are visible
# in container logs. This wrapper only starts Erlang and surfaces failures.
set -eu

BASE=$(dirname "$0")

echo "Starting Gleam migration via Erlang shipment..."

if ! erl \
  -pa "$BASE"/*/ebin \
  -eval 'app@@main:run(migrate)' \
  -noshell \
  -s init stop
then
  echo "Migration failed — see Erlang output above for details." >&2
  exit 1
fi
