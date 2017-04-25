defmodule LookupPhoenix.NoteApiController do

   use LookupPhoenix.Web, :controller
   use Timex

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

   defp authenticated(conn) do
      conn2value(conn, "secret") == "abcdef9h5vkfR1Tj0U_1f!"
   end

    def show(conn, %{"id" => id}) do

      if authenticated(conn) do
         note = Note.get(id)
         query_string = conn.query_string
         username = "jxxcarlson"
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

    def update(conn, %{"id" => id}) do

      if authenticated(conn) or true do
         IO.puts "AUTHORIZED!"
         {:ok, data} = Poison.Parser.parse conn2value(conn, "data")

         username = data["username"]
         user = User.find_by_username(username)
         note = Note.get(id)

         id_list = AppState.update({:user, user.id, :search_history, note.id})
         navigation_data = NoteNavigation.get(id_list, id)
         params = Map.merge(data, %{nav: navigation_data})

         result = NoteUpdateAction.call(username, note, params)
         {status, note} = result.update_result
         params = Map.merge(%{note: note, nav: result.nav}, result.params)
         render conn, "note.json", result: params
       else
        render conn, "error.json", message: "not authorized"
      end
    end

end