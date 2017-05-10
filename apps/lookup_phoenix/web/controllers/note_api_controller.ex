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
   alias LookupPhoenix.Token

   @moduledoc """
   API controller for LookupNote

   JSON: https://github.com/devinus/poison

   For authentication? -- https://github.com/bryanjos/joken
   Hexdocs: https://hexdocs.pm/joken/Joken.html
   Examples: http://blog.simonstrom.xyz/elixir-phoenix-simple-authentication/
             https://medium.com/brightergy-engineering/jwt-authentication-based-api-in-phoenix-6c4b51909b19

   ROUTES
   ======

   0. GET api/stats             -- return servers stats
   1. GET api/note/:id          -- return id, title, content, tag_string
   2. PUT api/note/:id          -- update note

   TEST (POSTMAN)

   0. http://localhost:4001/api/stats

   1. http://localhost:4001/api/notes/998

   2. http://localhost:4001/api/notes/1114

      Send key-value pair in body with key = "data" and value like

      {
        "title":"Magick",
        "username":"jxxcarlson",
        "user_id": "9",
        "content":"This *is* a test",
        "tag_string":"foo,bar",
        "token": "YADA_YADA",
      }
"""

    defp key2value(list, key) do
      pair =  Enum.filter(list, fn(pair) -> {k, v} = pair; k == key end)
      [{_,value}] = pair
      value
    end

    defp conn2value(conn, key) do
      key2value(conn.req_headers, key)
    end


    def show(conn, %{"id" => id}) do

      {:ok, token} = Poison.Parser.parse conn2value(conn, "token")
      {:ok, user_id} = Poison.Parser.parse conn2value(conn, "user_id")
      {:ok, username} = Poison.Parser.parse conn2value(conn, "username")

      if Token.authenticated(token, user_id) do
         query_string = conn.query_string
         result = NoteShowAction.call(username, query_string, id)
         render conn, "note.json", result: result
       else
         render conn, "error.json", message: "not authorized"
      end
    end

    def stats(conn, %{}) do
      result = MU.Server.get_stats
      render conn, result
    end

    def update(conn, params) do

       id = params["id"]

       # Normalize the input: the first branch is for requests from Phoenix,
       # in which case the payload is in `params`.  The second branch is for
       # other requests, when the payload is in the request body.
       if params["token"] != nil do
         data = params
       else
         {:ok, data} = Poison.Parser.parse conn2value(conn, "data")
       end

       token = data["token"]
       user_id = String.to_integer data["user_id"]

      if Token.authenticated(token, user_id) do

         username = data["username"]
         user = User.find_by_username(username)
         note = Note.get(id)

         id_list = AppState.update({:user, user.id, :search_history, note.id})
         navigation_data = NoteNavigation.get(id_list, id)
         new_params = Map.merge(data, %{nav: navigation_data})

         result = NoteUpdateAction.call(username, note, new_params)

         {status, note} = result.update_result
         new_params = Map.merge(%{note: note, nav: result.nav}, result.params)
         render conn, "note.json", result: new_params
       else
        render conn, "error.json", message: "not authorized"
      end
    end

end