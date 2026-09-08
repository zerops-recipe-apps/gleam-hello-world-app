#!/bin/sh
# Run the Gleam migration module in the context of the Erlang shipment.
# Loads all compiled BEAM files from the shipment and evaluates the
# migrate module's main function, then stops the Erlang VM.
set -eu

BASE=$(dirname "$0")
MAX_ATTEMPTS=60
DELAY_SECONDS=2
ATTEMPT=1

run_migration() {
  erl \
    -pa "$BASE"/*/ebin \
    -eval 'app@@main:run(migrate)' \
    -noshell \
    -s init stop
}

while [ "$ATTEMPT" -le "$MAX_ATTEMPTS" ]; do
  if run_migration; then
    echo "Migration complete."
    exit 0
  fi

  if [ "$ATTEMPT" -eq "$MAX_ATTEMPTS" ]; then
    echo "Migration failed after ${MAX_ATTEMPTS} attempts."
    exit 1
  fi

  echo "Database not ready (attempt ${ATTEMPT}/${MAX_ATTEMPTS}), retrying in ${DELAY_SECONDS}s..."
  ATTEMPT=$((ATTEMPT + 1))
  sleep "$DELAY_SECONDS"
done
