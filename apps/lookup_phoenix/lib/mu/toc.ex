defmodule Notebook.TOC do

  require IEx

  alias LookupPhoenix.Utility
  alias LookupPhoenix.Note
  alias LookupPhoenix.Constant
  alias LookupPhoenix.AppState

  @module_doc """
  Notebook.TOC Manages "index notes" that represent a table of contents
  for a set of notes, i.e., a notebook.  WE NEED TO GET THIS CIRCLE
  OF IDEAS STRAIGHTENED OUT -- BEFORE I TOTALL FORGET HOW THIS WORKS
  AND WHAT IT IS FOR: NESTED NOTEBOOKS.

  HISTORY RECORDS AND HISTORY STRINGS.

  Example.  A toc_history record looks is a list of 2-lists, e.g.

     [[1010, 993], [1019, 976]]

  The elements of the 2-lists are note IDs. The history string derived from
  the above history record is

      1019/976/1010>993;1019>976

   It has the following meaning:

      1019                is the ID of the current index note (LHS)
      976                 is the ID of the currently displayed note (RHS)
      1010>993;1019>976   is the history.

   A history consists of segments separated by semicolons.  The rightmost
   segment defines the index note and current note.  Segments to the left
   of the rightmost segment define by "browser history" and allow one
   to "go back".  In this model, there is a root notebook, defined by its
   index note.  Its "children" may be regular notes or index notes. And
   so on.
  """


   ########### ########### ########### ########### ########### ########### ###########

   def toc_link(toc_item) do
     parent_id = Integer.to_string(toc_item.parent_id)
     child_id = Integer.to_string(toc_item.child_id)
     "<a href=\"/show2/#{parent_id}/#{child_id}/#{parent_id}>#{child_id}\">#{toc_item.parent_title}</a>"
   end

   def history_links2(user) do
     get_toc_history(user)
     |> Enum.reduce([],fn(link, acc) -> [toc_link(link)] ++ acc end)
     |> Enum.join(" > ")
   end

   def toc_item(note, note2 \\ nil) do
     %{parent_id: note.id, parent_title: note.title, child_id: note2.id,
       child_title: note2.title, child_is_toc: Note.is_toc?(note2)}
   end

   def update_toc_history2(user, note) do

     AppState.update(:user, user.id, :toc_history, [])

   end

   def get_toc_history(user) do
     AppState.get(:user, user.id, :toc_history)
   end

   def put_toc_history(user, toc_history) do
     AppState.update(:user, user.id, :toc_history, toc_history)
   end

   def update_toc_history2(user, note, note2) do

     toc_history = get_toc_history(user)
     Utility.report("IN: AppState toc_history", toc_history)
     IO.puts "Note = #{note.id}, Note2 = #{note2.id}"

     toc_history2 = cond do
        note2 == nil ->
          []
        toc_history == [] ->
          IO.puts "AppState, BRANCH A"
          [toc_item(note, note2)]
        hd(toc_history).parent_id == note.id ->
          IO.puts "AppState, BRANCH B"
          [toc_item(note, note2)| tl(toc_history)]
        hd(toc_history).child_id == note.id ->
          IO.puts "AppState, BRANCH C"
          [toc_item(note, note2)] ++ toc_history
        true ->
          tl(toc_history)
      end

       #

     Utility.report("OUT: AppState toc_history", toc_history2)
     put_toc_history(user, toc_history2)

   end

   ########### ########### ########### ########### ########### ########### ########### ###########

  defp ths1(elem) do
    [id, id2] = elem
     "#{id}>#{id2}"
  end

  #   Notebook.TOC.historify(foo)
  #   => [[1], [1, 2], [1, 2, 3], [1, 2, 3, 4]]
  def historify(list) do
    n = length(list) - 1
    Enum.reduce(0..n, [], fn(k, acc) -> acc ++ [Enum.slice(list, 0..k)] end)
  end

  @doc """
  uuu
"""
  def make_history_string(toc_history) do
     Utility.report("toc_history", toc_history)
     Enum.reduce(toc_history, [], fn(elem, acc) -> acc ++ [ths1(elem)] end)
     |> Enum.join(";")
  end

  def make_history(toc_history) do
    Enum.reduce(toc_history, [], fn(elem, acc) -> acc ++ [elem] end)
  end

  defp make_link(toc_history) do
    n = length(toc_history) - 1
    [id, id2] = Enum.at(toc_history, n)
    title = Note.get(id).title
    history = make_history_string(toc_history)
    "<a href=\"/show2/#{id}/#{id2}/#{history}\">#{title}</a>"
  end

  # Example of toc_history argument:
  # [[904, 443], [903, 757], [905, 447]]
#  def make_history_links(toc_history) do
#    toc_history2 = historify(toc_history)
#    Enum.map(toc_history2, fn(th) -> make_link(th) end)
#    |> Enum.join(" >  ")
#  end

   ################### ################### ################### ################### ###################
#
#  @doc """
#  Remove comments from the text, then split it into lines,
#  filtering out any empty lines.
#  """
#  defp lines_from_note_content(text) do
#    text
#    |> String.trim
#    # split input into lines
#    |> String.split(["\n", "\r", "\r\n"])
#    # remove comments:
#    |> Enum.map(fn(item) -> Regex.replace(~r/(.*)\s*\#.*$/U, item, "\\1") end)
#    # remove empty items
#    |> Enum.filter(fn(item) -> item != "" end)
#  end
#
#
#
#  defp prepare_toc(text, options) do
#    text
#    # split text into lines and normalize them
#    |> lines_from_note_content
#    # Make TOC items
#    |> Enum.map(fn(line) -> make_toc_item(line, options) end)
#  end
#
#  @doc """
#  A standard line looks like this:
#
#  ID, HEADING
#
#  The ID may be either a numerical id or a text identifier.
#  The part after the comma is a HEADING for the table of contents.
#  It is defined by the user, and is typically the title of the
#  note with the given ID, or a shortened version of the title.
#  """
#  defp make_toc_item(line, options) do
#      IO.puts "MTI in APPLICATION PHX APP"
#      IO.puts("LINE (mti): #{line}")
#      # Utility.report("OPTIONS (mti)", options)
#
#      ### THE BELOW IS A TEMPORARY FIX.  WHY IS IT THAT
#      ### options[:path_segment] is sometimes nil?
#      ### This solution will break in the public view.
#      if options[:path_segment] != nil do
#        path_segment = options.path_segment
#      else
#        path_segment = "show2"
#      end
#      toc_history = options[:toc_history] || "" ## id>id2
#      Utility.report("XXX, in make_toc_item,  toc_history", toc_history)
#      line_parts = String.split(line, ",")
#      id = String.trim( hd(line_parts) )
#      note = Note.get(id)
#      heading = tl(line_parts) |> Enum.join(", ")
#      cond do
#        id == "title" ->
#          IO.puts "XXXXXX HEADING: #{heading}"
#          "<p class=\"title\">#{heading}</p>\n"
#        note == nil ->
#            ""
#        true ->
#           "<p id=\"note:#{note.id}\" class=\"toc\"><a href=\"#{Constant.home_site}/#{path_segment}/#{options.note_id}/#{id}/#{toc_history}\">#{heading}</a></p>\n"
#      end
#  end
#
#  def process(text, options) do
#    IO.puts "THIS IS NOTEBOOK . TOC . PROCESS in APP PHX"
#    prepare_toc(text, options)
#    |> Enum.reduce("", fn(item, acc) -> acc <> item end)
#  end


end