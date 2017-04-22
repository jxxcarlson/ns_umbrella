defmodule LookupPhoenix.NoteController do
  use LookupPhoenix.Web, :controller
  use Timex

  alias LookupPhoenix.Note
  alias LookupPhoenix.User
  alias LookupPhoenix.AppState
  alias LookupPhoenix.Test
  alias LookupPhoenix.Text
  alias LookupPhoenix.Utility
  alias LookupPhoenix.NoteNavigation
  alias MU.TOC


  alias LookupPhoenix.NoteIndexAction
  alias LookupPhoenix.NoteShowAction
  alias LookupPhoenix.NoteShow2Action
  alias LookupPhoenix.NotePrintAction
  alias LookupPhoenix.NoteCreateAction
  alias LookupPhoenix.NoteUpdateAction
  alias LookupPhoenix.NoteMailtoAction

  alias MU.RenderText
  alias MU.LiveNotebook

   def cookies(conn, cookie_name) do
     conn.cookies[cookie_name]
   end

  # Params: random = yes|no
  # /notes?channel=demo.art - perform search and set channel
  # /notes?random=one|many
  # /notes
  # Searches for notes are always conducted in a channel
  # To implement
  #
  # notes?recent=25
  # notes?tag=science
  # notes?search=foo%20bar%20baz
  # notes?search=
  # MORE?
  def index(conn, _params) do

     result = NoteIndexAction.call(conn)

   if result.branch == "site"  do
       conn
       |> put_resp_cookie("site", conn.assigns.current_user.username)
       |> render("index.html", result)
   else
       conn
       |> put_resp_cookie("site", conn.assigns.current_user.username)
       |> redirect(to: "/notes?mode=all")
   end

  end

  defp read_only_message(conn) do
      conn
      |> put_flash(:info, "Sorry, these notes are read-only.")
      |> redirect(to: note_path(conn, :index))
  end


  def new(conn, _params) do
    locked = conn.assigns.current_user.read_only
    if (locked) do
           read_only_message(conn)
    else
        current_notebook_id = AppState.get(:user, conn.assigns.current_user.id, :current_notebook)
        current_notebook = Note.get(current_notebook_id)
        changeset = Note.changeset(%Note{})
        render(conn, "new.html", changeset: changeset, locked: locked,
        word_count: 0, conn: conn, index: 0, id_string: "[0,1]",
        notebook_title:  current_notebook.title)
    end
  end

  def create(conn, %{"note" => note_params}) do
    if (conn.assigns.current_user.read_only == true) do
         read_only_message(conn)
    else
      Utility.report("NEW NOTE, PARAMS",  note_params)
      note_params = Map.merge(note_params, AppState.get(:user, conn.assigns.current_user.id))
      result = NoteCreateAction.call(conn, note_params)
      case result do
        {:ok, conn, note} ->
          AppState.update(:user, conn.assigns.current_user.id, :current_note, note.id)
          conn
          # |> put_flash(:info, "Note created successfully: #{note.id}")
          # |> redirect(to: note_path(conn, :index, active_notes: [note.id], random: "no"))
          |> redirect(to: note_path(conn, :edit, note.id))
        {:error, changeset} ->
          render(conn, "new.html", changeset: changeset)
      end
    end
  end


  def set_channel(conn, params) do
    current_user = conn.assigns.current_user
    channel = params["set"]["channel"]
    if channel == nil or channel == "" do
      channel = "#{conn.assigns.current_user.username}.all"
    end
    if current_user != nil do
      IO.puts "USER . SET CHANNEL TO #{channel} for user #{current_user.username}"
    end
    redirect(conn, to: "/notes?channel=#{channel}")
  end


  defp do_show2(conn, note) do
      text = note.content
      lines =  String.split(String.trim(text), ["\n", "\r", "\r\n"])
      |> Enum.filter(fn(line) -> !Regex.match?(~r/^title/, line) end)
      cond do
        lines != [] ->
           first_line  = hd(lines)
           parts = String.split(first_line, ",")
           if length(parts) == 1 do
             redirect(conn, to: "/show2/#{note.id}/#{note.id}/#{note.id}>#{note.id}")
           else
             [id2, _] = parts
             redirect(conn, to: "/show2/#{note.id}/#{id2}/#{note.id}>#{id2}")
           end
        true ->
           redirect(conn, to: "/show2/#{note.id}/#{note.id}/#{note.id}>#{note.id}")
      end

  end

  def show(conn, %{"id" => id}) do

    IO.puts "THIS IS NOTECONTROLLER . SHOW, ID = #{id}"
    current_user = conn.assigns.current_user
    username = current_user.username

    AppState.update(:user, current_user.id, :current_note, String.to_integer(id))

    query_string = conn.query_string



    if query_string == "" do
       query_string = "index=0&id_string=#{id}"
    end

    note = Note.get(id)

    TOC.update_toc_history2(current_user, note)

    LiveNotebook.auto_update(note)

    cond do
      note.parent_id != nil ->
        conn |> redirect(to: "/show2/#{note.parent_id}/#{note.id}/#{note.parent_id}>#{note.id}")
      Enum.member?(note.tags, ":toc") ->
         do_show2(conn, note)
      true ->
        result = NoteShowAction.call(username, query_string, id)
      render(conn, "show.html", result)
    end
  end




  def show2(conn, %{"id" => id, "id2" => id2, "toc_history" => toc_history}) do

    id = Note.normalize_id(id)
    id2 = Note.normalize_id(id2)
    Utility.report("SHOW2, ID, ID2", [id, id2])
    current_user = conn.assigns.current_user
    IO.puts "current_user: #{current_user.id}"
    AppState.update(:user, current_user.id, :current_notebook, id)
    AppState.update(:user, current_user.id, :current_note, id2)

    params = NoteShow2Action.call(conn, %{"id" => id, "id2" => id2, "toc_history" => toc_history})
    render(conn, "show2.html", params)
  end

  def print(conn, %{"id" => id}) do
    result = NotePrintAction.call(id)
    params = Map.merge(result, %{layout: false})
    render conn, "print.html", params
  end


  def mailto(conn, %{"id" => id}) do
    result = NoteMailtoAction.call(conn, %{"id" => id})
    render(conn, "mailto.html", result.params)
  end


  def edit(conn, %{"id" => id}) do
        current_user = conn.assigns.current_user
        current_user_name = current_user.username

        note = Repo.get!(Note, id)
        changeset = Note.changeset(note)
        locked = conn.assigns.current_user.read_only
        word_count = RenderText.word_count(note.content)
        tags = Note.tags2string(note)

        rendered_text = Text.render(note.content, %{mode: "latex", toc: false, mode: "show", process: "latex"})

        params1 = %{note: note, changeset: changeset,
                    word_count: word_count, locked: locked,
                    conn: conn, tags: tags, note: note,
                    rendered_text: rendered_text, current_user_name: current_user_name}

        # Ensure that id is in id_list
        current_notebook_id = AppState.get(:user, current_user.id, :current_notebook)
        current_notebook = Note.get(current_notebook_id)
        current_note_id = AppState.get(:user, current_user.id, :current_note)

            id_list = AppState.update({:user, current_user.id, :search_history, id})
        if current_notebook != nil do
           id_list = AppState.update({:user, current_user.id, :search_history, current_notebook_id})
        end

        navigation_data = NoteNavigation.get(id_list, id)


        notebook_url  = "/show2/#{current_notebook_id}/#{current_note_id}/#{current_notebook_id}>#{current_note_id}"
        if note.parent_id != nil do
          notebook_link = "<p style=\"float:left\"><a href=\"#{notebook_url}\"> Notebook</a></p>"
        else
          notebook_link = ""
        end

        rendered_text = Text.render(note.content, %{collate: "no", mode: "show", process: "latex"})

        params = Map.merge(params1, %{nav: navigation_data, rendered_text: rendered_text})
        params = Map.merge(params, %{notebook_link: "NL", notebook_title:  current_notebook.title})
        render(conn, "edit.html", params)

  end

  defp do_update(conn, note, note_params, save_option) do

    current_user = conn.assigns.current_user
    id_list = AppState.get(:user, current_user.id, :search_history)
    navigation_data = NoteNavigation.get(id_list, note.id)
    note_params = Map.merge(note_params, %{nav: navigation_data})
    username = current_user.username

    Utility.report("DO UPDATE, NOTE_PARAMS", note_params)

    result = NoteUpdateAction.call(username, note, note_params)

    case result.update_result do
      {:ok, note} ->
        if save_option == "exit" do
          conn
          |> redirect(to: note_path(conn, :show, note))
        else
          params = Map.merge(%{note: note, nav: result.nav}, result.params)
          conn
          |> render "edit.html", params
        end
      {:error, _changeset} ->
          conn
          |> put_flash(:info, "ERROR - is the identifier you proposed unique?")
          |> render "edit.html", result.params
    end
  end

  def update(conn, %{"id" => id, "note" => note_params, "save_option" => save_option}) do

   user = conn.assigns.current_user
   locked = user.read_only
   note = Repo.get!(Note, id)

    cond do
      (note.user_id ==  user.id) && (!locked) ->
        do_update(conn, note, note_params, save_option)
      true -> read_only_message(conn)
    end

  end

  def delete(conn, %{"id" => id}) do

    user = conn.assigns.current_user
    AppState.update(:user, user.id, :current_note, nil)

    note = Repo.get!(Note, id)
    if (user.read_only == true) or (user.id != note.user_id) do
       read_only_message(conn)
    else
       note = Repo.get!(Note, id)

       # Here we use delete! (with a bang) because we expect
       # it to always work (and if it does not, it will raise).
       Repo.delete!(note)

       n = String.to_integer(id)
       AppState.recall_list(conn.assigns.current_user.id)
       |> List.delete(n)
       |> AppState.memorize_list(conn.assigns.current_user.id)

       conn
       |> put_flash(:info, "Note deleted successfully.")
       |> redirect(to: note_path(conn, :index, random: "no"))
    end
  end


end
