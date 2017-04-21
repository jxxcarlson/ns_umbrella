defmodule MU.Parse do

  alias MU.Parse

  use Combine

  @doc ~S"""
  iex> MU.Parse.block_heading("[env.theorem#pyth]")
  [["[", 'env.theorem#pyth', "]"]]
  """
  def block_heading(input) do
    Combine.parse(input, sequence([char("["), take_while(fn(a) -> !Enum.member?('][-=+*\n\r', a) end), char("]")]))
  end

  @doc ~S"""
  # iex> Combine.parse("[foo]", char("[") |> word() |> char("]"))
  # ["[", "foo", "]"]
"""

  # def parse(text), do: Combine.parse(text, parser)

  def paren_integer(input) do
    Combine.parse(input, between(char("("), integer(), char(")")))
  end

  def block_header(input) do
      # Combine.parse(input, between(char("["), str(), char("]")))
    Combine.parse(input, sequence([char("["), Parse.str(), char("]")]))
  end

  @doc """
  iex> MU.Parse.word_space("foo bar baz")
  ["foo"]
  """
  def word_space(input) do
    Combine.parse(input, pair_left(word(), spaces()))
  end

  @doc """
  > MUP.word_space2("foo bar")
  ["foo", " "]
  """
  def word_space2(input) do
    Combine.parse(input, word()  |> spaces() )
  end

  @doc """
  > MU.Parse.color("red")
  ["red"]
  iex(12)> MU.Parse.color("blue")
  ["blue"]
  iex(13)> MU.Parse.color("green")
  {:error,
   "Expected `red`, but was not found at line 1, column 0., or: Expected `blue`, but was not found at line 1, column 0."}
  """
  def color(input) do
    Combine.parse(input, either(string("red"), string("blue")))
  end

  @doc """
   iex> MU.Parse.sentence1("foo bar baz bim bam bo")
   [["foo", "bar", "baz", "bim", "bam"]]
  """
  def sentence1(input) do
    Combine.parse(input, many(pair_left(word(), space())))
  end

  @doc """
  Not working
  """
  def sentence(input) do
    # Combine.parse(input, pair_left(MU.Parse.sentence1(input), char(".")))
    Combine.parse(input, Parse.sentence1(input) |> char(".") )
  end

  def ordinary_string(input) do
     # valid_characters = ~r/[!:_\-\w]+/
     ordinary_string_regex = ~r/[^]\\"'()[\s]+/
     Combine.parse(input, word_of(ordinary_string_regex) )
     # parser = word_of(fn(a) -> Regex.match?(ordinary_string_regex, a) end)
     # parser = take_while(fn(a) -> ?a >= 48 && ?a <= 126 end)
     # Combine.parse(input, parser)
  end

  @doc ~S"""
  Parse an initial segment up to the first EOL:

  MU.Parse.paragraph("foo, bar\nyada yada\n")
  ['foo, bar']

  """
  def paragraph(input) do
    parser = take_while( fn(a) -> !Enum.member?('\r\n', a) end)
    Combine.parse(input, parser)
  end

  @doc ~S"""
  iex> MU.Parse.blanklines("\n\n")
  [["\n", ["\n"]]]

  iex> MU.Parse.blanklines("\n")
  {:error, "Expected newline, but hit end of input."}
  """
  def blanklines(input) do
    Combine.parse(input, sequence([newline(), many1(newline())]))
  end

  @doc ~S"""
  Accept the largest initial segment of the input that does not
  contain the specified characters.

  iex> MU.Parse.str("foo!-bar !")
  ['foo!']

  """
  def str(input) do
    parser = take_while(fn(a) -> !Enum.member?('-=+*\n\r', a) end)
    Combine.parse(input, parser)
  end

  def str2(input) do
    parser = take_while(fn(a) -> !Enum.member?('-=+*\n\r', a) end)
    #input |> Combine.parse(parser)
  end

  # Combine.parse("[foo bar]", sequence([char("["), MU.Parse.str2(), char("]")]))
  # Combine.parse("[foo bar]", sequence([char("["), take_while(fn(a) -> !Enum.member?('-=+*\n\r', a) end), char("]")]))

#  def section1(input) do
#    Combine.parse(sequence([char("="), spaces(), many(word_space()), word(), newline()]))
#  end


end

