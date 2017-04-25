defmodule LookupPhoenix.NoteApiController do

   use LookupPhoenix.Web, :controller
   use Timex

   import Joken

   alias LookupPhoenix.Note
   alias LookupPhoenix.NoteNavigation
   alias LookupPhoenix.User
   alias LookupPhoenix.AppState
   alias LookupPhoenix.Utility

   alias LookupPhoenix.NoteShowAction
   alias LookupPhoenix.NoteUpdateAction

   LookupPhoenix.JSONMapBuilder

   @moduledoc """
   API controller for LookupNote

   JSON: https://github.com/devinus/poison

   For authentication? -- https://github.com/bryanjos/joken
   Hexdocs: https://hexdocs.pm/joken/Joken.html
   Examples: http://blog.simonstrom.xyz/elixir-phoenix-simple-authentication/
             https://medium.com/brightergy-engineering/jwt-authentication-based-api-in-phoenix-6c4b51909b19

   ROUTES
   ======

   1. GET api/note/:id          -- return id, title, content, tag_string
   2. PUT api/note/:id          -- update note

   TEST (POSTMAN)
   1. http://localhost:4001/api/notes/998
      -- send secret and username in header
      -- 999 fails
      -- need real authentication
"""

    defp key2value(list, key) do
      pair =  Enum.filter(list, fn(pair) -> {k, v} = pair; k == key end)
      [{_,value}] = pair
      value
    end

    defp conn2value(conn, key) do
      key2value(conn.req_headers, key)
    end

    defp verify_token(token) do
      token
      |> token
      # |> with_validation("user_id", &(&1 == 1))
      |> with_signer(hs256("yada82043mU,@izq0#$mcq^&!HFQpnp8i-nc"))
      |> verify
    end

#    def authenticated(token) do
#      result = verify_token(token)
#      result.error == nil
#    end
#
#    def show(conn, %{"id" => id}) do
#
#      {:ok, token} = Poison.Parser.parse conn2value(conn, "token")
#
#      if authenticated(token) do
#         note = Note.get(id)
#         query_string = conn.query_string
#         username = "jxxcarlson"
#
#         result = NoteShowAction.call(username, query_string, id)
#
#         render conn, "note.json", result: result
#       else
#         render conn, "error.json", message: "not authorized"
#      end
#    end
#
#    def stats(conn, %{}) do
#      result = MU.Server.get_stats
#      render conn, result
#    end
#
#    def update(conn, %{"id" => id}) do
#
#       {:ok, data} = Poison.Parser.parse conn2value(conn, "data")
#       {:ok, token} = Poison.Parser.parse conn2value(conn, "token")
#
#      if authenticated(token) do
#         username = data["username"]
#         user = User.find_by_username(username)
#         note = Note.get(id)
#
#         id_list = AppState.update({:user, user.id, :search_history, note.id})
#         navigation_data = NoteNavigation.get(id_list, id)
#         params = Map.merge(data, %{nav: navigation_data})
#
#         result = NoteUpdateAction.call(username, note, params)
#
#         {status, note} = result.update_result
#         params = Map.merge(%{note: note, nav: result.nav}, result.params)
#         render conn, "note.json", result: params
#       else
#        render conn, "error.json", message: "not authorized"
#      end
#    end

    ################ OLD VERSION ###############

    def show(conn, %{"id" => id}) do
          if authenticated(conn) do
             note = Note.get(id)
             query_string = conn.query_string
             username = "jxxcarlson"
             result = NoteShowAction.call(username, query_string, id)
             render conn, "note.json", result: result
           else
             render conn, "error.json", message: "darn it!"
          end
        end

        def stats(conn, %{}) do
          # {:reply, result, _} = MU.Server.get_stats
          result = MU.Server.get_stats
          render conn, result
        end

        def update(conn, %{"id" => id, "put" => data}) do

    #      Utility.report("conn", conn)
    #      current_user = conn.assigns.current_user
    #      IO.puts("API . UPDATE, CURRENT USER = #{current_user.id}")

          if authenticated(data["secret"]) do
             IO.puts "AUTHORIZED!"
             title = data["title"]
             username = data["username"]
             user = User.find_by_username(username)
             note = Note.get(id)
             Utility.report("user.id", user.id)
             Utility.report("note.id", note.id)

             id_list = AppState.update({:user, user.id, :search_history, note.id})
             navigation_data = NoteNavigation.get(id_list, id)
             params = Map.merge(data, %{nav: navigation_data})

             result = NoteUpdateAction.call(username, note, params)
             {status, note} = result.update_result
             IO.puts "update status = #{status}"
             params = Map.merge(%{note: note, nav: result.nav}, result.params)
             render conn, "note.json", result: params
           else
            render conn, "error.json", message: "darn it!"
          end
        end



end