defmodule LookupPhoenix do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec
    {:ok, store} = Mnemonix.Store.start_link({Mnemonix.Map.Store, initial: %{active_notes: []}}, name: Cache)

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(LookupPhoenix.Repo, []),
      # Start the endpoint when the application starts
      supervisor(LookupPhoenix.Endpoint, []),
      # Start your own worker by calling: LookupPhoenix.Worker.start_link(arg1, arg2, arg3)
      # worker(LookupPhoenix.Worker, [arg1, arg2, arg3]),
      worker(LookupPhoenix.Periodically, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LookupPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LookupPhoenix.Endpoint.config_change(changed, removed)
    :ok
  end
end
