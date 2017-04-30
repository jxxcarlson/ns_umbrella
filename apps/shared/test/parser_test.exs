defmodule ParserTest do
  use ExUnit.Case
  # doctest Shared

  alias XMU

@text1 """
Line 1
Line 2

Line3


Line4
Line5





Line6



"""

@text2 """
Line 1
Line 2

Line3


[quote]
--
Don't cry over spilled milk;
--


Line5
Line6



"""

@text_with_verbatim """

Line 1
Line 2
\\[
a^2 = b^2 + c^2
\\]
Line A
Line B
----

a =
     b = c

----

== Section BBBB

Line 3


Line 4

[quote]
--
This is a test.
--

Hey ho!

"""


  test "parser" do
    output = XMU.parse(@text1)
    IO.puts "-------------------------"
    IO.inspect output
  end



  test "parser 2" do
    output = Enum.reverse XMU.parse(@text_with_verbatim).blocks

    block_0 = Enum.at(output, 0)
    block_1 = Enum.at(output, 1)
    block_2 = Enum.at(output, 2)
    block_3 = Enum.at(output, 3)
    block_4 = Enum.at(output, 4)
    block_5 = Enum.at(output, 7)

    assert block_0 ==  %{content: ["Line 2", "Line 1"], type: :paragraph, block_info: %{}}
    assert block_1 ==  %{block_info: %{}, content: ["a^2 = b^2 + c^2"], type: :math_block}
    assert block_2 ==  %{content: ["Line B", "Line A"], type: :paragraph, block_info: %{}}
    assert block_3 ==  %{block_info: %{}, type: :verbatim, content: ["", "     b = c", "a =", ""]}
    assert block_4 ==  %{type: :section_heading, content: "Section BBBB", block_info: %{level: 2}}
    assert block_5 ==  %{block_info: %{block_headers: ["quote"], block_separator: "--"},
                         content: ["This is a test."], type: :block}
  end




  test "parser with output" do
    output = XMU.parse(@text_with_verbatim).blocks
    IO.puts "\n-------------------------\n"
    IO.puts @text_with_verbatim
    IO.puts "\n-------------------------\n"
    output |> Enum.map(fn(block) -> IO.inspect(block) end)
  end

  test "render with output" do
    IO.puts XMU.render(@text_with_verbatim)
  end

end

