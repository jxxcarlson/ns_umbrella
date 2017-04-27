# require IEx

defmodule LookupPhoenix.SearchController do
    use LookupPhoenix.Web, :controller
    alias LookupPhoenix.Note
    alias LookupPhoenix.NoteSearch
    alias LookupPhoenix.Search
    alias LookupPhoenix.User
    alias LookupPhoenix.AppState
    alias LookupPhoenix.Utility

    def cookies(conn, cookie_name) do
       conn.cookies[cookie_name]
    end


    def index(conn, %{"search" => %{"query" => query}}) do

        IO.puts "This is SEARCH CONTROLLER . INDEX, query = #{query}"

        current_user = conn.assigns.current_user

        if current_user == nil do
          query = "/public " <> query
          site = cookies(conn,"site")
          channel_user = User.find_by_username(site)
          channel_tag = "public"
          channel = channel_user.username <> "." <> channel_tag
          # user = channel_user
        else
          user = current_user
          channel = user.channel
          User.increment_number_of_searches(user)
        end

        user_signed_in = current_user != nil
        notes = Search.search(channel, query, %{user_signed_in: user_signed_in})
        if current_user != nil do
          AppState.memorize_notes(notes, current_user.id)
        end

        notes = Utility.add_index_to_maplist(notes)
        id_string = Note.extract_id_list(notes)

        noteCount = length(notes)
        case noteCount do
          1 -> noteCountString = "1 Note found"
          _ -> noteCountString = Integer.to_string(noteCount) <> " Notes found"
        end

        IO.puts "XXX: SearchController, index, notes: #{length(notes)}"

        render(conn, "index.html", site: site, notes: notes, id_string: id_string, noteCountString: noteCountString)

    end

    ################# tag_search ###############


    # Used in tag links in tag index page
    def tag_search(conn, %{"query" => query}) do

          qsMap = Utility.qs2map(conn.query_string)
          # qsKeys = Map.keys(qsMap)
          site = qsMap["site"]
          current_user = conn.assigns.current_user

          # set access
          {access, channel} = cond do
            current_user == nil ->
              { :public,  "#{site}.public" }
            current_user.username == site ->
              { :all, "#{site}.all" }
            true ->
              { :public, "#{site}.public" }
          end

          if current_user != nil do
            User.increment_number_of_searches(current_user)
          end

          # Add /public if access = :public
         #  query_list = tag_search_set_query_list(query, access)
          query = String.trim(query)
          if access == :public do
              query = "/public " <> query
          end
          query_list = String.split(query)


          channel = current_user.channel
          [channel_name, _] = String.split(channel, ".")
          if channel_name = current_user.username do
            access = :all
          else
            access = :public
          end
          notes = Search.tag_search(query_list, channel, access)
          # if current_user == nil || site_user != current_user do
          # notes = Enum.filter(notes, fn(x) -> x.public == true end)
          # end

          noteCount = length(notes)
          if current_user != nil do
            AppState.memorize_notes(notes, current_user.id)
          end

          notes_with_index = Utility.add_index_to_maplist(notes)
          id_string = Note.extract_id_list(notes)

          case noteCount do
            1 -> noteCountString = "1 Note found with tag #{query}"
            _ -> noteCountString = Integer.to_string(noteCount) <> " Notes found with tag #{query}"
          end

          if access == :all do
            render(conn, "index.html", site: site, notes: notes_with_index, id_string: id_string, noteCountString: noteCountString)
          else
            render(conn, "index.html", site: site, notes: notes_with_index, id_string: id_string, noteCountString: noteCountString)
            # redirect(conn, to: "/site/#{site}", notes: notes)
          end
    end




   # Route: /recent?QUERY, where
   # QUERY is hourse_before=N&mode=MODE, where
   # MODE = upated | created | viewed
   def recent(conn, params) do
        parameter = params["username"]

        if parameter =~ ~r/\./ do
          [username, tag] = String.split(parameter, "\.")
        else
          username = parameter
          tag = "all"
        end

        channel = username <> "." <> tag

        user = User.find_by_username(username)
        current_user = conn.assigns.current_user
        public = !(user.id == current_user.id)

        query_string_map = Utility.qs2map(conn.query_string)
        User.increment_number_of_searches(current_user)

        update_message = "Recent"

        cond do
          "hours_before" in Map.keys(query_string_map) ->
             # hours_before = String.to_integer query_string_map["hours_before"]
             notes = Note
               |> NoteSearch.select_by_channel(channel)
               |> NoteSearch.select_by_viewed_at_hours_ago(25)
               |> NoteSearch.select_public(public)
               |> NoteSearch.sort_by_viewed_at
               |> Repo.all
          "max" in Map.keys(query_string_map) ->
             # max_notes = String.to_integer query_string_map["max"]
             notes = Note
              |> NoteSearch.select_by_channel(channel)
              |> NoteSearch.select_public(public)
              |> NoteSearch.sort_by_viewed_at
              |> Repo.all
              |> NoteSearch.most_recent(20)
          true ->
             notes = Note
              |> NoteSearch.select_by_channel("#{current_user.username}.all")
              |> NoteSearch.select_public(true)
              |> NoteSearch.sort_by_viewed_at
              |> Repo.all
              |> NoteSearch.most_recent(5)
        end

        note_count = length(notes)
        AppState.memorize_notes(notes, conn.assigns.current_user.id)

        notes = Utility.add_index_to_maplist(notes)
        # id_string = Note.extract_id_list(notes)
        case note_count do
           1 -> countReportString =   "1 #{update_message} note"
           _ -> countReportString = "#{length(notes)} #{update_message} notes"
        end
        id_string = Note.extract_id_list(notes)
        render(conn, "index.html", notes: notes, id_string: id_string, noteCountString: countReportString)
   end


end



