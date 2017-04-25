defmodule  NS.Notebook.TOC2 do

  @docmodule """

  Notebook.TOC2 parses a string representing the table
  of contents of a document. Here is a typical input string:

  = Introductory Biology, 43    # The title and id of of the book
  == Introductin, 61            # First section
  == Plants, 7                  # Second section
  === Flowers, 99               # First subsection
  === Trees, 432                # Second subsection
  == Animals, 19                # Fourth section

"""

  def parse_line_regex do
    ~r/^(=+) (.*)/
  end


  @doc """
  parseline yields a triple of the form

    [LEVEL, TITLE, ID]

  when applied to a string like

     == Foo, Bar, 29

  In this case, the output is

     [1, "Foo, Bar", "29"]

  The ID may represent a numerical ID or
  a string identifier.

  iex> line = "== Foo, Bar, 29"
  iex> TOC2.parse_line(line)
  [1, "Foo, Bar", "29"]
"""
  def parse_line(line) do
    if !String.contains?(line, "#") do
      line = line <> " # comment"
    end
    [data | comment] = String.split(line, "#")
    [_, section_mark, tail] = Regex.run(parse_line_regex, data)
    parts = String.split(tail, ",")
    |> Enum.map(fn(item) -> String.trim(item) end)
    id = List.last parts
    level = String.length(section_mark) - 1
    {_, title_parts} = List.pop_at(parts, -1)
    title = Enum.join(title_parts, ", ")
    [level, title, id]
    %{level: level, title: title, id: id}
  end

  @doc """
  get_lines(text) returns a list of strings, ignoring blank lines
  and lines that do not start with "="
"""
  def get_lines(text) do
    lines = String.split(text, ["\r", "\n", "\r\n"])
    |> Enum.filter(fn(line) -> String.length(line) != 0 end)
    |> Enum.filter(fn(line) -> String.slice(line, 0,1) == "=" end)
  end

 @doc """
  parselines(text) returns a list of triples
"""
  def parse_lines(text) do
    text
    |> get_lines
    |> Enum.map(fn(line) -> parse_line(line) end)
  end

  @doc """
  Initial input: :  %{triples: triples, stack: [], item: nil}
  Typical triple: %{level: 1, title:  "Introduction", id: "61"}
"""
  def compile_one(input) do
    {triple, new_triples} = List.pop_at(input.triples, 0)
    cond do
      input.stack == [] ->
        stack = [triple.id]
        item2 = %{level: triple.level, title: triple.title, stack: stack}
        %{triples: new_triples, stack: stack, item: item2}
      triple.level > input.item.level ->
         stack = input.stack ++ [triple.id]
         item2 = %{level: triple.level, title: triple.title, stack: stack}
         %{triples: new_triples, stack: stack, item: item2}
      triple.level == input.item.level ->
         {_, stack} = List.pop_at(input.stack,-1)
         stack = stack ++ [triple.id]
         item2 = %{level: triple.level, title: triple.title, stack: stack}
         %{triples: new_triples, stack: stack, item: item2}
      triple.level < input.item.level ->
         {_, stack} = List.pop_at(input.stack,-1)
         {_, stack} = List.pop_at(stack,-1)
         stack = stack ++ [triple.id]
         item2 = %{level: triple.level, title: triple.title, stack: stack}
         %{triples: new_triples, stack: stack, item: item2}
      true ->
        input
    end
  end

  @doc """
  Initial datum: %{input: %{triples: triples, stack: [], item: nil}, output: []}
"""
  def compile_datum(datum) do
    output = compile_one(datum.input)
    new_output = datum.output ++ [output.item]
    %{input: output, output: new_output}
  end

  @doc """
  compile(text) returns a list of triples ... TBC
"""
  def compile(text) do
    triples = parse_lines(text)
    n = Enum.count(triples)
    input = %{triples: triples, stack: [], item: nil}
    datum = %{input: input, output: []}
    Enum.reduce(1..n, datum, fn(k,datum) -> compile_datum(datum) end).output
  end


  def render_item(item) do
    {id2, stack} = List.pop_at(item.stack, -1)
    {id, _} = List.pop_at(stack, 0)

    "<p id=\"note:#{id2}\" class=\"toc toc_level_#{item.level}\"><a href=\"/show2/#{id}/#{id2}\">#{item.title}</a></p>"
  end

  @doc """

"""
  def render(text) do
    compile(text)
    |> tl
    |> Enum.reduce("", fn(item, acc) -> acc <> "\n" <> render_item(item) end)
  end


end