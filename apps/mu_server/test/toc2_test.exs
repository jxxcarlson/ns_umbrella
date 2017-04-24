defmodule NS.Notebook.TOC2.Test do

  alias NS.Notebook.TOC2
  use ExUnit.Case

@text  """
= Introductory Biology, 43    # The title and id of of the book
== Introduction, 61            # First section
== Plants, 7                  # Second section
=== Flowers, 99               # First subsection

foo

=== Trees, 432                # Second subsection
== Animals, 19                # Fourth section
"""

  @doc """
  iex> line = "== Foo, Bar, 29"
  iex> TOC2.parse_line(line)
  [1, "Foo, Bar", "29"]
"""
  test "parse_line" do
    line = "== Foo, Bar, 29"
    assert TOC2.parse_line(line) == %{level: 1, title: "Foo, Bar", id: "29"}
  end

  test "parse_line with comment" do
    line = "== Foo, Bar, 29 # Yada, yada"
    assert TOC2.parse_line(line) == %{level: 1, title: "Foo, Bar", id: "29"}
  end

  test "get_lines" do
    assert TOC2.get_lines(@text) |> Enum.count == 6
  end

  test "parse_lines" do
    triples = TOC2.parse_lines(@text)
    assert Enum.at(triples, 0) == %{level: 0, title:  "Introductory Biology", id: "43"}
    assert Enum.at(triples, 1) == %{level: 1, title:  "Introduction", id: "61"}
    assert Enum.at(triples, 3) == %{level: 2, title:  "Flowers", id: "99"}
    assert Enum.at(triples, 5) == %{level: 1, title:  "Animals", id: "19"}
  end

  test "compile_one" do
    triples = TOC2.parse_lines(@text)

    input = %{triples: triples, stack: [], item: nil}
    output = TOC2.compile_one(input)
    assert output.item == %{level: 0, stack: ["43"], title: "Introductory Biology"}

    output = TOC2.compile_one(output)
    assert output.item == %{level: 1, stack: ["43", "61"], title: "Introduction"}

    output = TOC2.compile_one(output)
    assert output.item == %{level: 1, stack: ["43", "7"], title: "Plants"}

    output = TOC2.compile_one(output)
    assert output.item == %{level: 2, stack: ["43", "7", "99"], title: "Flowers"}

    output = TOC2.compile_one(output)
    assert output.item == %{level: 2, stack: ["43", "7", "432"], title: "Trees"}

    output = TOC2.compile_one(output)
    assert output.item == %{level: 1, stack: ["43", "19"], title: "Animals"}
  end

  test "compile_datum" do

    triples = TOC2.parse_lines(@text)
    input = %{triples: triples, stack: [], item: nil}
    datum = %{input: input, output: []}

    datum = TOC2.compile_datum(datum)
    datum = TOC2.compile_datum(datum)
    datum = TOC2.compile_datum(datum)
    datum = TOC2.compile_datum(datum)
    datum = TOC2.compile_datum(datum)
    datum = TOC2.compile_datum(datum)

    expected_output = %{input: %{item: %{level: 1, stack: ["43", "19"], title: "Animals"},
                           stack: ["43", "19"], triples: []},
                         output: [%{level: 0, stack: ["43"], title: "Introductory Biology"},
                          %{level: 1, stack: ["43", "61"], title: "Introduction"},
                          %{level: 1, stack: ["43", "7"], title: "Plants"},
                          %{level: 2, stack: ["43", "7", "99"], title: "Flowers"},
                          %{level: 2, stack: ["43", "7", "432"], title: "Trees"},
                          %{level: 1, stack: ["43", "19"], title: "Animals"}]}

     assert datum == expected_output
  end

  test "compile" do

    output = TOC2.compile(@text)

    expected_output = [%{level: 0, stack: ["43"], title: "Introductory Biology"},
                           %{level: 1, stack: ["43", "61"], title: "Introduction"},
                           %{level: 1, stack: ["43", "7"], title: "Plants"},
                           %{level: 2, stack: ["43", "7", "99"], title: "Flowers"},
                           %{level: 2, stack: ["43", "7", "432"], title: "Trees"},
                           %{level: 1, stack: ["43", "19"], title: "Animals"}]

   assert output == expected_output

   end

   test "render" do
     html = TOC2.render(@text)
     expected_html = "\n<p id=\"note:43\" class=\"toc toc_level_1\"><a href=\"/show2/43/61\">Introduction</a></p>\n<p id=\"note:43\" class=\"toc toc_level_1\"><a href=\"/show2/43/7\">Plants</a></p>\n<p id=\"note:43\" class=\"toc toc_level_2\"><a href=\"/show2/43/99\">Flowers</a></p>\n<p id=\"note:43\" class=\"toc toc_level_2\"><a href=\"/show2/43/432\">Trees</a></p>\n<p id=\"note:43\" class=\"toc toc_level_1\"><a href=\"/show2/43/19\">Animals</a></p>"
     assert html == expected_html
   end

end