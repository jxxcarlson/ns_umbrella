defmodule LookupPhoenix.Text do

  alias LookupPhoenix.Utility

  def render(text, options) do
    Utility.report("OPTIONS (In LookupPhoenix.Text)", options)
    {:ok, rendered_text} = MU.Server.render(%{text: text, options: options})
    rendered_text
  end

end