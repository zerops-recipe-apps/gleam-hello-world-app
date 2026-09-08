# Gleam Hello World Recipe App

<!-- #ZEROPS_EXTRACT_START:intro# -->
A minimal [Gleam](https://gleam.run) web application using the Wisp framework and gleam_pgo for PostgreSQL connectivity, demonstrating idempotent database migrations and a health-check endpoint that queries live data.
Used within [Gleam Hello World recipe](https://app.zerops.io/recipes/gleam-hello-world) for [Zerops](https://zerops.io) platform.
<!-- #ZEROPS_EXTRACT_END:intro# -->

⬇️ **Full recipe page and deploy with one-click**

[![Deploy on Zerops](https://github.com/zeropsio/recipe-shared-assets/blob/main/deploy-button/light/deploy-button.svg)](https://app.zerops.io/recipes/gleam-hello-world?environment=small-production)

![gleam cover](https://github.com/zeropsio/recipe-shared-assets/blob/main/covers/svg/cover-gleam.svg)

## Integration Guide

<!-- #ZEROPS_EXTRACT_START:integration-guide# -->

### 1. Adding `zerops.yaml`
The main application configuration file you place at the root of your repository, it tells Zerops how to build, deploy and run your application.

```yaml
zerops:
  # Production setup — compiles an Erlang shipment and deploys the
  # optimized artifact. Gleam compiles to BEAM bytecode; the shipment
  # bundles all compiled modules with a launch script.
  - setup: prod
    build:
      os: ubuntu
      base: gleam@1.5
      buildCommands:
        # Export a self-contained Erlang/OTP shipment — compiled BEAM
        # files for the app and all dependencies, with entrypoint.sh.
        - gleam export erlang-shipment
        # Bundle the migration script with the shipment so initCommands
        # can run it without access to source code.
        - cp migrate.sh build/erlang-shipment/migrate.sh
      deployFiles:
        # ~ strips the path prefix: build/erlang-shipment/* lands at
        # /var/www/* in the runtime container (entrypoint.sh, all
        # package ebin dirs, and migrate.sh at the same level).
        - build/erlang-shipment/~
      cache:
        # Gleam downloads Hex packages to build/packages/ — cache this
        # in-tree folder to skip network fetches on subsequent builds.
        - build/packages

    # Readiness check: verifies containers are healthy before the
    # project balancer routes traffic to them (zero-downtime deploys).
    deploy:
      readinessCheck:
        httpGet:
          port: 3000
          path: /

    run:
      # Gleam's Erlang shipment requires an OTP runtime on the host —
      # the BEAM files are not statically linked. gleam@1.5 includes
      # Erlang/OTP 26, matching the build container exactly.
      os: ubuntu
      base: gleam@1.5

      # Run migration once per deploy using execOnce — prevents race
      # conditions when multiple containers start simultaneously.
      # In initCommands (not buildCommands) so migration and code
      # deploy atomically. retryUntilSuccessful handles transient
      # DB startup delays on fresh deploys.
      initCommands:
        - zsc execOnce ${appVersionId} --retryUntilSuccessful -- sh /var/www/migrate.sh

      ports:
        - port: 3000
          httpSupport: true

      envVariables:
        DB_HOST: ${db_hostname}
        DB_PORT: ${db_port}
        # DB_NAME matches the PostgreSQL service hostname ('db').
        DB_NAME: db
        DB_USER: ${db_user}
        DB_PASS: ${db_password}

      start: ./entrypoint.sh run

  # Development setup — deploys source for live SSH development.
  # Gleam is installed on the runtime; developers run 'gleam run'
  # interactively after SSH.
  - setup: dev
    build:
      os: ubuntu
      base: gleam@1.5
      buildCommands:
        # Source-only deployment. Gleam packages are downloaded in
        # initCommands rather than here, avoiding build-container
        # permission issues when cached build/ directories are restored.
        - 'true'
      deployFiles:
        # Deploy source and config files. zerops.yaml included so
        # 'zcli push' works when SSHed into the dev container.
        - src
        - gleam.toml
        - manifest.toml
        - zerops.yaml
        - migrate.sh

    run:
      os: ubuntu
      base: gleam@1.5

      # Download Hex packages and run migration once per deploy.
      # 'gleam deps download' populates build/packages/ so 'gleam run'
      # works offline in the container. execOnce prevents repeated
      # compilation (30+ packages) on restart or scale events.
      initCommands:
        - zsc execOnce ${appVersionId} --retryUntilSuccessful -- sh -c "gleam deps download && gleam run -m migrate"

      ports:
        - port: 3000
          httpSupport: true

      envVariables:
        # rebar3 (Erlang build tool used by Gleam's package compiler)
        # requires HOME to locate its global config. Without it,
        # rebar_dir:home_dir/0 crashes when 'gleam run' compiles deps.
        HOME: /home/zerops
        DB_HOST: ${db_hostname}
        DB_PORT: ${db_port}
        DB_NAME: db
        DB_USER: ${db_user}
        DB_PASS: ${db_password}

      # Zerops starts the container and leaves it idle. SSH in and
      # run 'gleam run' to start the development server on port 3000.
      # Note: after a container restart, re-run 'gleam deps download'
      # to restore the build/packages/ directory before 'gleam run'.
      start: zsc noop --silent
```
<!-- #ZEROPS_EXTRACT_END:integration-guide# -->
