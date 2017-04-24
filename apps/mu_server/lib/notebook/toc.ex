defmodule NS.Notebook.TOC do

   alias LookupPhoenix.Note

   @doc """
    Remove comments from the text, then split it into lines,
    filtering out any empty lines.
    """
    defp lines_from_note_content(text) do
      text
      |> String.trim
      # split input into lines
      |> String.split(["\n", "\r", "\r\n"])
      # remove comments:
      |> Enum.map(fn(item) -> Regex.replace(~r/(.*)\s*\#.*$/U, item, "\\1") end)
      # remove empty items
      |> Enum.filter(fn(item) -> item != "" end)
    end



    defp prepare_toc(text, options) do
      text
      # split text into lines and normalize them
      |> lines_from_note_content
      # Make TOC items
      |> Enum.map(fn(line) -> make_toc_item(line, options) end)
    end

    @doc """
    A standard line looks like this:

    ID, HEADING

    The ID may be either a numerical id or a text identifier.
    The part after the comma is a HEADING for the table of contents.
    It is defined by the user, and is typically the title of the
    note with the given ID, or a shortened version of the title.
    """
    defp make_toc_item(line, options) do
        IO.puts "MTI in APPLICATION MU SERVER"
        ### THE BELOW IS A TEMPORARY FIX.  WHY IS IT THAT
        ### options[:path_segment] is sometimes nil?
        ### This solution will break in the public view.
        if options[:path_segment] != nil do
          path_segment = options.path_segment
        else
          path_segment = "show2"
        end
        toc_history = options.toc_history ## id>id2
        line_parts = String.split(line, ",")
        id = String.trim( hd(line_parts) )
        note = Note.get(id)
        heading = tl(line_parts) |> Enum.join(", ")
        cond do
          id == "title" ->
            "<p class=\"title\">#{heading}</p>\n"
          note == nil ->
              ""
          true ->
             "<p id=\"note:#{note.id}\" class=\"toc\"><a href=\"#{Application.get_env(:deploy_vars, :host_url)}/#{path_segment}/#{options.note_id}/#{id}\">#{heading}</a></p>\n"
        end
    end

    def process(text, options) do
      IO.puts "THIS IS NOTEBOOK . TOC . PROCESS in app MU SERVER"
      prepare_toc(text, options)
      |> Enum.reduce("", fn(item, acc) -> acc <> item end)
    end


    def prepare_toc2(text) do

    end



end