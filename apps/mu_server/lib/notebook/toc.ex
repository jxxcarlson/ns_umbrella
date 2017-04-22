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
        IO.puts("LINE PARTS = #{IO.inspect line_parts}")
        [part_a, part_b] = line_parts
        IO.puts("A = #{part_a}, B = #{part_b}")
        id = String.trim( hd(line_parts) )
        # id = String.trim( part_a )
        note = Note.get(id)
        heading = tl(line_parts) |> Enum.join(", ")
        cond do
          id == "title" ->
            IO.puts "XXXXXX HEADING: #{heading}"
            "<p class=\"title\">#{heading}</p>\n"
          id == "subsections" ->
            id2 = String.trim(part_b) |> String.to_integer
            IO.puts "ID2 = #{id2}"
            IO.puts "-------"
            index_note = Note.get(id2)
            IO.puts "title of index note = #{index_note.title}"
            IO.puts "content of index note = #{index_note.content}"
            # IO.puts "content of index note = #{process(index_note.content, %{})}"
            IO.puts "-------"
            # IO.puts "PART B NOTE (#{part_b}) CONTENTS: #{index_note.contents}"
            # IO.puts "PART B NOTE (#{part_b}) CONTENTS: #{Note.get(part_b).contents}"
            "<div>\n#{index_note.content}\n</div>"
          note == nil ->
              ""
          true ->
             "<p id=\"note:#{note.id}\" class=\"toc\"><a href=\"#{Application.get_env(:deploy_vars, :host_url)}/#{path_segment}/#{options.note_id}/#{id}/#{toc_history}\">#{heading}</a></p>\n"
        end
    end

    def process(text, options) do
      # Utility.report("process, options", options)
      # IO.puts "PROCESS OPTIONS: #{IO.inspect(options)}"
      prepare_toc(text, options)
      |> Enum.reduce("", fn(item, acc) -> acc <> item end)
    end



end