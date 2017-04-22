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
     current_user = conn.assigns.current_user
     [changeset, current_notebook, attach] = setup(conn, note_params)
     case Repo.insert(changeset) do
        {:ok, note} ->
          [note.id] ++ AppState.recall_list(current_user.id)
          |> AppState.memorize_list(current_user.id)
          if current_notebook != nil and attach == "true" do
             # add the note being created to the current notebook:
             content = current_notebook.content <> "\n" <> "#{note.id}, #{note.title}\n"
             notebook_changeset = Note.changeset(current_notebook, %{content: content})
             Repo.update(notebook_changeset)
          end
          {:ok, conn, note }
        {:error, changeset} ->
          {:error, changeset: changeset}
      end
  end

  defp get_current_notebook(current_user_id) do
    AppState.get(:user, current_user_id, :current_notebook)
    |> Note.get()
  end


  defp setup(conn, note_params) do
      current_user = conn.assigns.current_user
      [access, channel_name, user_id] = User.decode_channel(conn.assigns.current_user)
      [tag_string, tags] = get_tags(note_params, channel_name)
      current_notebook = get_current_notebook(current_user.id)
      attach = note_params["attach"]
      if current_notebook != nil and attach == "true"   do
        parent_tag = "parent:#{current_notebook.identifier}"
        tag_string = "#{tag_string}, #{parent_tag}"
        tags = tags ++ [parent_tag]
        IO.puts "Setting parent ID to that of current_notebook (#{current_notebook.id})"
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
      identifier = Identifier.make(current_user.username, new_title)
      new_params = %{"content" => new_content, "title" => new_title,
         "user_id" => conn.assigns.current_user.id, "viewed_at" => Timex.now, "edited_at" => Timex.now,
         "tag_string" => tag_string, "tags" => tags, "public" => false, "identifier" => identifier,
         "parent_id" => current_notebook.id}
      [Note.changeset(%Note{}, new_params), current_notebook, attach]
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