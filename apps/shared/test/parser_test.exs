defmodule ParserTest do
  use ExUnit.Case
  # doctest Shared

  alias MU.Parser

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
----

a =
     b = c

----
Line 3
Line 4

"""

  test "parser1" do
    output = Parser.parse1(@text1)
    IO.puts "-------------------------"
    IO.inspect output
  end

  test "parser2" do
    output = Parser.parse2(@text1)
    IO.puts "-------------------------"
    IO.inspect output
  end

  test "parser3" do
    output = Parser.parse3(@text1)
    IO.puts "-------------------------"
    IO.inspect output
  end

  test "parser3 with a block" do
    output = Parser.parse3(@text_with_verbatim).blocks
    IO.puts "\n-------------------------\n"
    output |> Enum.map(fn(block) -> IO.inspect(block) end)
  end

end
