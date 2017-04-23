defmodule LookupPhoenix.Text do



  def render(text, options) do
    {:ok, rendered_text} = MU.Server.render(%{text: text, options: options})
    rendered_text
  end

end