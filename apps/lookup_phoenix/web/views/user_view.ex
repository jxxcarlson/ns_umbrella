defmodule LookupPhoenix.UserView do
  use LookupPhoenix.Web, :view

    def render("token.json", %{token: token}) do
      %{token: token}
    end

end
