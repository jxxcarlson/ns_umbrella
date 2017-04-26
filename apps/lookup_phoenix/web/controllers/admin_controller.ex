defmodule LookupPhoenix.AdminController do


    use LookupPhoenix.Web, :controller
    plug :authenticate

    alias LookupPhoenix.Repo
    alias LookupPhoenix.User
    alias LookupPhoenix.Utility

    def user_index(conn, _) do
      users = Repo.all(User)
      query = Ecto.Query.from user in User,
                    order_by: [asc: user.username]
      users = Repo.all(query)
      render(conn, "user_index.html", users: users)
    end

    def dashboard(conn, _) do
      stats = MU.Server.get_stats
      requests_per_hour = stats.requests/stats.uptime |> Float.round(1)
      render(conn, "dashboard.html", stats: stats, requests_per_hour: requests_per_hour)
    end

    def edit_user(conn, params) do
      id = conn.params["id"]
      user = Repo.get!(User, id)
      changeset = User.changeset(user)
      render(conn, "edit_user.html", user_id: id, changeset: changeset, user: user)
    end

    def update_user(conn, params) do
      user = Repo.get!(User, params["id"])
      password = params["user"]["password"]
      User.change_password(user, password)
      conn
      |> put_flash(:info, "Password changed for #{user.username}")
      |> redirect(to: "/admin/users" )
    end

    defp authenticate(conn, _opts) do

       current_user =conn.assigns.current_user

       bailout = cond do
         current_user == nil -> true
         current_user.admin == nil -> true
         current_user.admin == false -> true
         current_user.admin == true -> false
         true -> true
       end

       if bailout == true do
          conn
          |> put_flash(:error, "Not authorized")
          |> redirect(to: page_path(conn, :index))
          |> halt
       else
          conn
       end
    end


end