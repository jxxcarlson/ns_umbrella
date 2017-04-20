use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or you later on).
config :lookup_phoenix, LookupPhoenix.Endpoint,
  secret_key_base: "dGUwMGcrZb6/GELJR7vWutLu4UCZBS6a8y5kO8wKA3zJuRO1G86Ne8a+r5ViQ6Z7"

# Configure your database
config :lookup_phoenix, LookupPhoenix.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "lookup_phoenix_prod",
  pool_size: 20
