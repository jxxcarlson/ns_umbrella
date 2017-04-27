defmodule LookupPhoenix.UserController do

  use LookupPhoenix.Web, :controller
  plug :authenticate when action in [:index, :show, :delete, :get_token]

  alias LookupPhoenix.User
  alias LookupPhoenix.Tag
  alias LookupPhoenix.Repo
  alias LookupPhoenix.Utility
  alias LookupPhoenix.SearchController
  alias LookupPhoenix.Constant

  import Joken

   def get_token(conn, _params) do

      IO.puts "I will make a token for you ..."

      current_user = conn.assigns.current_user
      my_token = %{"user_id" => current_user.id}
#      |> token
#      |> with_signer(hs256("yada82043mU,@izq0#$mcq^&!HFQpnp8i-nc"))
      |> token
      |> with_validation("user_id", &(&1 == 1))
      |> with_signer(hs256("yada82043mU,@izq0#$mcq^&!HFQpnp8i-nc"))
      |> sign
      |> get_compact

      Utility.report("my_token", my_token)

     render conn, "token.json", token: my_token

    end


  def index(conn, _params) do
    if conn.assigns.current_user.admin == true do
        query = Ecto.Query.from user in User,
                  # select: note.id,
                  where: user.public == ^true,
                  order_by: [asc: user.username]
        users = Repo.all(query)
        render conn, "index.html", users: users
      else
        conn
        |> put_flash(:error, "Sorry, you do no have access to that page")
        |> redirect(to: page_path(conn, :index))
        |> halt
    end
  end

  def delete(conn, %{"id" => id}) do
      if conn.assigns.current_user.admin == true do
         user = Repo.get!(User, id)
         User.update_read_only(user, !user.read_only)
         user = Repo.get!(User, id)
         if user.read_only == true do
           message = "locked"
         else
           message = "unlocked"
         end
         conn
         |> put_flash(:info, "#{user.username} is #{message}")
         |> redirect(to: user_path(conn, :index))
      else
          conn
          |> put_flash(:error, "Sorry, you do no have access to that page")
          |> redirect(to: page_path(conn, :index))
          |> halt
      end
    end

    def filter_by_frequency(tag_list, threshold) do
      Enum.filter(tag_list, fn(tag) -> tag["freq"] > Constant.tag_frequency_threshold() end)
    end

    def cookies(conn, cookie_name) do
      conn.cookies[cookie_name]
    end

  def tags(conn, %{"username" => username}) do

      current_user = conn.assigns.current_user

      channel_user_name = cookies(conn, "site")

      user = User.find_by_username(username)
      if user == nil do
        user = User.find_by_username("demo")
      end

      cond do
        current_user == nil ->
            real_access = :public
        current_user.username != channel_user_name ->
            real_access = :public
        true -> real_access = :all
      end

     [access, channel_name, user_id] = User.decode_channel(user)

     access = real_access || access
     if user_id == user.id and real_access != :public do
       channel_user = user
       ctags = user.tags |> Utility.sort_on_key("name", "asc")
       original_tag_count = length(ctags)
       ctags = ctags |> filter_by_frequency(Constant.tag_frequency_threshold())
       ctag_count = length(ctags)
     else
       channel_user = User |> Repo.get!(user_id)
       ctags = channel_user.public_tags |> Utility.sort_on_key("name", "asc")
       original_tag_count = length(ctags)
       ctags = ctags |> filter_by_frequency(Constant.tag_frequency_threshold())
       original_tag_count = length(ctags)
       ctag_count = length(ctags)
     end

     if current_user == channel_user do
       render conn, "tags.html", user: channel_user,
          ctags: ctags, ctag_count: ctag_count, original_tag_count: original_tag_count
     else
       render conn, "tags_public.html", user: channel_user,
          ctags: ctags, ctag_count: ctag_count, original_tag_count: original_tag_count

     end

  end

  def update_tags(conn, _params) do
    current_user = conn.assigns.current_user
    User.update_tags(current_user)
    conn |> redirect(to: "/tags/#{current_user.username}")
    # render conn, "tags.html", user: conn.assigns.current_user
  end

  # Assumption: the current user exists
  def update_channel(conn, params) do
      user = conn.assigns.current_user
      channel = (params["set"])["channel"]
      IO.puts "Calling 'update_channel' for #{user.username} with channel = #{channel}"
      [channel, _name, _tag] = Channel.validated_channel(user, channel)
      IO.puts "Validated channel = #{channel}"
      User.update_channel(user, channel)
      conn |> redirect(to: note_path(conn, :index, mode: "all"))
  end



  def new(conn, _params) do
    changeset = User.changeset(%User{})
    render conn, "new.html", changeset: changeset
  end

  def createUser(changeset, conn) do
    IO.puts "Hello: createUser"
    case Repo.insert(changeset) do
          {:ok, user} ->
            User.initialize_metadata(user)
            User.set_admin(user, false)
            conn
            |> LookupPhoenix.Auth.login(user)
            |> put_flash(:info, "#{Utility.firstWord(user.name)}, you are now a LookupNote user!")
            |> redirect(to: note_path(conn, :index))
          {:error, changeset} ->
            IO.puts "ERROR in createUser"
            render(conn, "new.html", changeset: changeset)
        end
  end

  def create(conn, %{"user" => user_params}) do
    username = user_params["username"]
    channel = "#{username}.all"
    user_params = Map.merge(user_params, %{"channel" => channel})
    changeset = User.registration_changeset(%User{}, user_params)
    Utility.report("create, changeset", changeset)

    preflight_check = cond do
      user_params["registration_code"] == "" ->
           {:error, "Sorry, a registration code is required."}
      Enum.member?(["lattice", "student", "uahs"], user_params["registration_code"]) == false ->
           {:error, "Sorry, that is not a valid registration code."}
      true -> {:ok, :proceed}
    end

    case  preflight_check do
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: user_path(conn, :new))
      _ -> createUser(changeset, conn)
    end


  end

  def show_preferences(conn, params) do
    Utility.report("XXX: show_preferences, params", params)
    changeset = User.running_changeset(%User{}, params)
    preferences_changeset = User.preferences_changeset(%User{}, params)
    render conn, "preferences.html", changeset: changeset, preferences_changeset: preferences_changeset, user: conn.assigns.current_user
  end

  def update_preferences(conn, %{"user" => user_params}) do
    changeset = User.running_changeset(conn.assigns.current_user, user_params)

    case Repo.update(changeset) do
      {:ok, user} ->
        conn
        |> LookupPhoenix.Auth.login(user)
        |> put_flash(:info, "Your preferences have been updated")
        |> redirect(to: "/sites")
      {:error, changeset} ->
        render(conn, "preferences .html", changeset: changeset)
    end
  end


  defp authenticate(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be signed in to access that page")
      |> redirect(to: page_path(conn, :index))
      |> halt
    end
  end


  end
