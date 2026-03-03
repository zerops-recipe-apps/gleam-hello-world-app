#!/bin/sh
# Run the Gleam migration module in the context of the Erlang shipment.
# Loads all compiled BEAM files from the shipment and evaluates the
# migrate module's main function, then stops the Erlang VM.
set -eu

BASE=$(dirname "$0")

exec erl \
  -pa "$BASE"/*/ebin \
  -eval 'app@@main:run(migrate)' \
  -noshell \
  -s init stop
