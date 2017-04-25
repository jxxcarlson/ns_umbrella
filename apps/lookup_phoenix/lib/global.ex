defmodule LookupPhoenix.Global do

  def app_name do
    "Notefile"
    # Application.get_env(:deploy_vars, :app_name)
  end

  def host do
    Application.get_env(:deploy_vars, :host)
  end

end