use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :lookup_phoenix, LookupPhoenix.Endpoint,
  http: [port: 4000],
  secret_key_base: "XWnt9yqvc8ZpWu/WS4epERXm4wRytM+OAkY+mSs3x+wAvudH+PBim8ioF021P5wa",
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    cd: Path.expand("../", __DIR__)]]


# Watch static and templates for browser reloading.
config :lookup_phoenix, LookupPhoenix.Endpoint,
  http: [port: 4001, ip: {0, 0, 0, 0}],
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]


# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :lookup_phoenix, LookupPhoenix.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "carlson",
  database: "lookup_repo",
  hostname: "localhost",
  pool_size: 10

config :lookup_phoenix,
  host_url: "http://localhost:4001"

# Access the above by: Application.get_env(:deploy_vars, :host_url)