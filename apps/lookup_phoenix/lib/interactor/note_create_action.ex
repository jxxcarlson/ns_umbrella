defmodule LookupPhoenix.NoteCreateAction do

  alias LookupPhoenix.Note
  alias LookupPhoenix.Repo
  alias LookupPhoenix.Search
  alias LookupPhoenix.Identifier
  alias LookupPhoenix.User
  alias LookupPhoenix.AppState
  alias LookupPhoenix.Tag

  alias LookupPhoenix.Utility

  def call(conn, note_params) do
     [changeset, notebook] = setup(conn, note_params)
     case Repo.insert(changeset) do
        {:ok, note} ->
          [note.id] ++ AppState.recall_list(conn.assigns.current_user.id)
          |> AppState.memorize_list(conn.assigns.current_user.id)
          if notebook != nil and note_params["attach"] == true do
             # add the note being created to the current notebook:
             content = notebook.content <> "\n" <> "#{note.id}, #{note.title}\n"
             notebook_changeset = Note.changeset(notebook, %{content: content})
             Repo.update(notebook_changeset)
          end
          IO.puts "ABOUT TO EXIT NOTE CREATE ACTION . CALL"
          {:ok, conn, note }
        {:error, changeset} ->
          {:error, changeset: changeset}
      end
  end

  defp get_parent_id(channel, tags) do
    IO.puts "GET PARENT ID"
    Utility.report("[channel, tags]", [channel, tags])
    master_notes = Enum.map(tags, fn(tag) -> "parent:" <> tag end)
    |> Enum.map(fn(tag) -> Search.tag_search([tag], channel, :all) end)
    |> List.flatten
    Utility.report("master_notes", master_notes)
    cond do
      length(master_notes) == 1 && Note.get(hd(master_notes) != nil) ->
        Note.get(hd(master_notes)).id
        true -> nil
    end
  end


  defp setup(conn, note_params) do
      [access, channel_name, user_id] = User.decode_channel(conn.assigns.current_user)
      [tag_string, tags] = get_tags(note_params, channel_name)
      parent_id =  get_parent_id(conn.assigns.current_user.channel, tags)
      if note_params[:current_notebook]  != nil and note_params["attach"] == true   do
        parent_id = note_params[:current_notebook]
        notebook = Note.get(parent_id)
        parent_tag = "parent:#{notebook.identifier}"
        tag_string = "#{tag_string}, #{parent_tag}"
        tags = tags ++ [parent_tag]
        IO.puts "Setting parent ID to that of current_notebook (#{parent_id})"
      else
        notebook = nil
      end

      content = note_params["content"] || " "
      title = note_params["title"] || "Untitled"

      title = cond do
        title == nil -> "Untitled"
        title == "" -> "Untitled"
        true -> title
      end

      content = cond do
        content == nil -> "Write note content here"
        content == "" -> "Write note content here"
        true -> content
      end

      new_content = content
      new_title = title
      identifier = Identifier.make(conn.assigns.current_user.username, new_title)
      new_params = %{"content" => new_content, "title" => new_title,
         "user_id" => conn.assigns.current_user.id, "viewed_at" => Timex.now, "edited_at" => Timex.now,
         "tag_string" => tag_string, "tags" => tags, "public" => false, "identifier" => identifier,
         "parent_id" => parent_id}
      [Note.changeset(%Note{}, new_params), notebook]
  end

  defp get_tags(note_params, channel_name) do

      # Normalize tag_string name and ensure that is non-nil and non-empty
      tag_string = note_params["tag_string"] || ""
      if is_nil(channel_name) do channel_name = "all" end

      cond  do
        !Enum.member?(["all", "public"], channel_name) and tag_string != "" ->
          tag_string = [tag_string, channel_name] |> Enum.join(", ")
        !Enum.member?(["all", "public"], channel_name) and tag_string == ""  ->
          tag_string = channel_name
        tag_string == "" -> tag_string = "-"
        tag_string != "" -> tag_string
      end

      tags = Tag.str2tags(tag_string)

      [tag_string, tags]
  end

end