defmodule XMU do

  alias XMU.Block

#  @type block_headers :: [String.t]
#
#  defmodule BlockInfo do
#    defstruct block_headers: ["foo"], block_separator: "--"
#    @type block_info :: %BlockInfo{ block_headers: [String.t], block_separator: String.t }
#  end
#
#  defmodule ParserStatte do
#    defstruct
#  end



  @docinfo """
  A simple parser for the mu markup language.
  It uses a finite-state machine. The aim is to parse
  the input text into a list of blocks of various types:

    - section headings
    - paragraphs
    - verbatim blocks
    - math blocks
    - generic blocks

  DATA STRUCTURES
  ===============

  initial state for parser = %{blocks: [], blockinfo: %{}, current_block:[], symbol: :start}

  block = %{ content: content, block_info: block_info, type: :atom}

  contents = [lines]

  initial block_info = %{block_headers: [], block_separator: nil}

  The driver for the parser is the parse(text) function defined below.
  The text is split into lines and piped into the function

     Enum.reduce(state, fn(line, state) -> new_state_for(line, state) end)

  The new_state_for(line, state) function returns a new state; when it
  runs to completion, the parsed texts resides in state.blocks.

  The new_state_for(line, state) function implements a finite-state machine
  whose states are the symbols listed below

    SYMBOLS
    ============
    :start
    :blank_line
    :ordinary_line

    :paragraph

    :block_start
    :block_separator
    :block_body
    :block_end

    :verbatim
    :math_block

    BLOCK TYPES
    ============
    :block
    :math_block
    :paragraph
    :section_heading
    :verbatim


"""


  def type_of_line(line, symbol) do
    cond do
      line == "" -> :blank_line
      String.slice(line, 0,1) == "[" -> :block_header
      Enum.member?(["--"], line) -> :block_separator
      Enum.member?([:verbatim, :paragraph, :start], symbol) && line == "----" -> :verbatim_separator
      line == "\\[" -> :math_begin
      line == "\\]" -> :math_end
      line == "$$" -> :dollar_math_2
      Regex.match?(~r/\A=* /, line) -> :section_heading
      true -> :ordinary_line
    end
  end


  @doc """
  iex> header_contents("[abc]")
  abc
"""
  def header_contents(header) do
    String.slice(header, 1, String.length(header) - 2)
  end

  def new_state(state, new_block, next_symbol) do
     blocks = [new_block | state.blocks]
     %{ state | blocks: blocks, current_block: [], block_info: %{}, symbol: next_symbol}
  end

  def create_block(type, content, block_info) do
    %{type: type, content: content, block_info: block_info}
  end

  def create_block(type, state) do
    %{type: type, content: state.current_block, block_info: state.block_info}
  end
  def update_symbol(state, symbol) do
     %{ state | symbol: symbol}
  end


  def next_state(line, state) do
    line_type = type_of_line(line, state.symbol)
    symbol = state.symbol
    IO.inspect {symbol, line_type, line}
    next_state(symbol, line_type, line, state)
  end

  @doc """
  Transitions from vertex :start
  """

  def next_state(:start, :ordinary_line, line, state) do
     %{ state | current_block: [line | state.current_block], symbol: :paragraph}
  end

  def next_state(:start, :math_begin, line, state) do
    %{ state | symbol: :math_block }
  end

  def next_state(:start, :block_header, line, state) do
    block_info = %{block_headers: [header_contents(line)], block_separator: nil}
    %{ state | block_info: block_info, symbol: :block_start}
  end

  def next_state(:start, :verbatim_separator, line, state) do
    %{ state | symbol: :verbatim }
  end

  def next_state(:start, :section_heading, line, state) do
    [target, marker, heading] = Regex.run(~r/(\A=* )(.*)/, line)
    level = String.trim(marker) |> String.length
    block_info = %{level: level}
    content = String.trim(heading)
    new_block = create_block(:section_heading, content, block_info)
    new_state(state, new_block, :start)
  end

  def next_state(:start, :blank_line, line, state) do
    state
  end

  @doc """
  Transitions from vertex :paragraph
  """

  def next_state(:paragraph, :ordinary_line, line, state) do
     %{ state | current_block: [line | state.current_block], symbol: :paragraph}
  end

  def next_state(:paragraph, :verbatim_separator, line, state) do
    new_block = create_block(:paragraph, state)
    new_state(state, new_block, :verbatim)
  end

  def next_state(:paragraph, :math_begin, line, state) do
    new_block = create_block(:paragraph, state)
    new_state(state, new_block, :math_block)
  end

  def next_state(:paragraph, :blank_line, line, state) do
    new_block = create_block(:paragraph, state)
    new_state(state, new_block, :start)
  end

  @doc """
  Transitions from :blank_line
  """

  def next_state(:blank_line, :ordinary_line,line, state) do
    %{ state | current_block: [line | state.current_block], symbol: :paragraph}
  end

  def next_state(:blank_line, :blank_line,line, state) do
    if state.current_block != [] do
       new_block = create_block(:paragraph, state)
       new_state(state, new_block, :start)
    else
       update_symbol(state, :start)
    end
  end

  def next_state(:blank_line, :section_heading,line, state) do
    if state.current_block != [] do
         new_block = create_block(:section_heading, state)
         new_state(state, new_block, :start)
        else
          state
    end
  end

  @doc """
    Transitions from :block_start
 """

  def next_state(:block_start, :block_header, line, state) do
    block_headers = [header_contents(line)|state.block_info[:headers]]
    block_info = %{state.block_info | block_headers: block_headers}
    %{ state | block_info: block_info, symbol: :block_start}
  end

  def next_state(:block_start, :block_separator, line, state) do
    block_info = %{state.block_info | block_separator: line}
    %{ state | block_info: block_info, symbol: :block_body}
  end

  @doc """
    Transitions from vertex :block_bodh
  """


  def next_state(:block_body, :block_separator, line, state) do
    cond do
      line == state.block_info.block_separator ->
         new_block = create_block(:block, state)
         new_state(state, new_block, :block_end)
      true ->
         state
    end
  end

  def next_state(:block_body, line_type, line, state) do
    cond do
      !Enum.member?([:block_header, :block_separator], line_type) ->
        contents = [line | state.current_block]
        %{ state | current_block: contents }
      true ->
        state
    end
  end

  @doc """
  Transitions from vertex :block_end
  """

  def next_state(:block_end, :block_header, line, state) do
     block_headers = [header_contents(line), state.block_info[:headers]]
     block_info = %{state.block_info | block_headers: block_headers}
     %{ state | block_info: block_info, symbol: :block_start}
  end

  def next_state(:block_end, :ordinary_line, line, state) do
     %{ state | current_block: [line | state.current_block], symbol: :paragraph}
  end

  def next_state(:block_end, :blank_line, line, state) do
    %{ state | symbol: :start }
  end

  @doc """
  Transitions from vertex :verbatim
  """


  def next_state(:verbatim, :verbatim_separator, line, state) do
    new_block = create_block(:verbatim, state)
     new_state(state, new_block, :start)
  end

  def next_state(:verbatim, line_type, line, state) do
    cond do
      line_type != :verbatim_separator ->
         current_block = [line|state.current_block]
         %{state | current_block: current_block}
      true ->
        state
    end
  end

  @doc """
  Transitions from vertex :math_block
  """


  def next_state(:math_block, :math_end, line, state) do
    IO.puts "I will now create a math block"
    IO.inspect state
    IO.puts "------------"
    new_block = create_block(:math_block, state)
     new_state(state, new_block, :start)
  end

  def next_state(:math_block, line_type, line, state) do
    cond do
      !Enum.member?([:math_begin, :math_end], line_type) ->
        current_block = [line|state.current_block]
         %{state | current_block: current_block}
      true ->
         state
    end
  end

  @doc """
  Default transition (no_op)
  """


  def next_state(_ , _, line, state) do
    IO.puts "Unrecognized transition"
    state
  end

  ####################

  def parse(text) do
    state = %{blocks: [], current_block: [], block_info: %{}, symbol: :start}
    String.split(text, ["\r", "\n" , "\r\n"]) |> Enum.map(fn(line) -> String.trim_trailing(line) end)
    |> Enum.reduce(state, fn(line, state) -> next_state(line, state) end)
  end

  #####################

    def render(text) do
      parse(text).blocks
      |> render_blocks
    end

    def render_blocks(blocks) do
      Enum.reduce(blocks, "", fn(block, acc) -> Block.render(block.type, block) <> acc end)
    end


end