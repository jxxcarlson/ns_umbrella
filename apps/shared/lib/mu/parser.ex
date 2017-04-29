defmodule MU.Parser do

  # defstruct blocks: [], current_block: [], symbol: :start

  # Parse result is an array of lines, including blank lines
  def ns1(line, state) do
    %{ state | blocks: state.blocks ++ [line]}
  end

  def parse1(text) do
      state = %{blocks: [], current_block: [], symbol: :start}
      String.split(text, ["\r", "\n" , "\r\n"]) |> Enum.map(fn(line) -> String.trim(line) end)
      |> Enum.reduce(state, fn(line, state) -> ns1(line, state) end)
    end



  #####################################

  def parse2(text) do
    state = %{blocks: [], current_block: [], symbol: :start}
    String.split(text, ["\r", "\n" , "\r\n"]) |> Enum.map(fn(line) -> String.trim(line) end)
    |> Enum.reduce(state, fn(line, state) -> ns2(line, state) end)
  end

  def type_of_line2(line) do
    if line == "" do
      :blank_line
    else
      :ordinary_line
    end
  end

  @doc """
  Parse text into parapgrahs

  symbols
    :start
    :blank_line
    :ordinary_line
    :paragraph
"""

  def ns2(line, state) do
    line_type = type_of_line2(line)
    symbol = state.symbol
    IO.inspect {symbol, line_type, state.current_block, state.blocks}

    output = cond do
     {symbol, line_type} == {:start, :ordinary_line} ->
       %{ state | current_block: state.current_block ++ [line], symbol: :paragraph}
     {symbol, line_type} == {:start, :blank_line} ->
       state

     # paragraph
     {:paragraph, :ordinary_line } == {symbol, line_type} ->
       %{ state | current_block: state.current_block ++ [line], symbol: :paragraph}
     {:paragraph, :blank_line } == {symbol, line_type} ->
       %{ state | symbol: :blank_line}

     # blank_line
     {:blank_line, :ordinary_line } == {symbol, line_type} ->
       %{ state | current_block: state.current_block ++ [line], symbol: :paragraph}
     {:blank_line, :blank_line } == {symbol, line_type} ->
       paragraph = state.current_block |> Enum.join("\n")
       blocks = state.blocks ++ [paragraph]
       %{ state | blocks: blocks, current_block: [], symbol: :start}

     true ->
        state
    end

  end



#####################################

  @doc """
  Parse text into paragraphs and blocks

  symbols
    :start
    :blank_line
    :ordinary_line
    :paragraph

    :block_start
    :block_body
    :block_end

    :verbatim
    :math

    :block_separator
"""

  def type_of_line3(line, symbol) do
    cond do
      line == "" -> :blank_line
      String.slice(line, 0,1) == "[" -> :block_header
      !Enum.member?([:verbatim, :start], symbol) && Enum.member?(["--"], line) -> :block_separator
      Enum.member?([:verbatim, :paragraph, :start], symbol) && line == "----" -> :verbatim_separator
      line == "\[" -> :begin_math
      line == "\]" -> :end_math
      line == "$$" -- :dollar_math_2
      Regex.match?(~r/\A=*$/, line) -> :section_heading
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

  def ns3b(line, state) do
    line_type = type_of_line3(line, state.symbol)
    symbol = state.symbol
    IO.inspect {symbol, line_type, state.current_block, state.blocks}

    output = cond do

    # start
     {:start, :ordinary_line} == {symbol, line_type} ->
       %{ state | current_block: state.current_block ++ [line], symbol: :paragraph}
     {:start, :block_header} == {symbol, line_type} ->
       block_info = %{block_headers: [header_contents(line)], block_separator: nil}
       %{ state | block_info: block_info, symbol: :block_start}
     {:start, :verbatim_separator} == {symbol, line_type} ->
       %{ state | symbol: :verbatim }
     {:start, :blank_line} == {symbol, line_type} ->
       state

     # paragraph
     {:paragraph, :ordinary_line } == {symbol, line_type} ->
       %{ state | current_block: state.current_block ++ [line], symbol: :paragraph}
     {:paragraph, :verbatim_separator } == {symbol, line_type} ->
       paragraph = state.current_block
       blocks = state.blocks ++ [%{type: :paragraph, content: paragraph}]
       %{ state | blocks: blocks, current_block: [], symbol: :verbatim}
     {:paragraph, :blank_line } == {symbol, line_type} ->
       %{ state | symbol: :blank_line}

     # blank_line
     {:blank_line, :ordinary_line } == {symbol, line_type} ->
       %{ state | current_block: state.current_block ++ [line], symbol: :paragraph}
     {:blank_line, :blank_line } == {symbol, line_type} ->
       paragraph = state.current_block
       blocks = state.blocks ++ [%{type: :paragraph, content: paragraph}]
       %{ state | blocks: blocks, current_block: [], symbol: :start}

     # block_start
     {:block_start, :block_header } == {symbol, line_type} ->
       block_headers = state.block_info[:headers] ++ [header_contents(line)]
       block_info = %{state.block_info | block_headers: block_headers}
       %{ state | block_info: block_info, symbol: :block_start}

     # block_separator
     {:block_start, :block_separator } == {symbol, line_type} ->
       block_info = %{state.block_info | block_separator: line}
       %{ state | block_info: block_info, symbol: :block_body}

     # block_body
     {:block_body, :block_separator } == {symbol, line_type} && line == state.block_info.block_separator ->
       contents = state.current_block
       block = %{contents: contents, block_info: state.block_info, type: :block}
       blocks = state.blocks ++ [block]
       %{ state | blocks: blocks, current_block: [], block_info: %{}, symbol: :block_end}
     :block_body == symbol && !Enum.member?([:block_header, :block_separator], line_type) ->
       contents = state.current_block ++ [line]
       %{ state | current_block: contents }

    # block_end
     {:block_end, :block_header } == {symbol, line_type} ->
       block_headers = state.block_info[:headers] ++ [header_contents(line)]
       block_info = %{state.block_info | block_headers: block_headers}
       %{ state | block_info: block_info, symbol: :block_start}
     {:block_end, :ordinary_line} == {symbol, line_type} ->
       %{ state | current_block: state.current_block ++ [line], symbol: :paragraph}
     {:block_end, :blank_line} == {symbol, line_type} ->
       %{ state | symbol: :start }

    # verbatim
     :verbatim == symbol && line_type != :verbatim_separator ->
       current_block = state.current_block ++ [line]
       %{state | current_block: current_block}
     {:verbatim, :verbatim_separator} == { symbol, line_type} ->
       new_block = %{contents: state.current_block, type: :verbatim, block_info: %{}}
       blocks = state.blocks ++ [new_block]
       %{state | blocks: blocks, current_block: [ ], block_info: %{}, symbol: :start}

     true ->
        state
    end

  end

  ####################

  def parse3(text) do
    state = %{blocks: [], current_block: [], block_info: %{}, symbol: :start}
    String.split(text, ["\r", "\n" , "\r\n"]) |> Enum.map(fn(line) -> String.trim_trailing(line) end)
    |> Enum.reduce(state, fn(line, state) -> ns3b(line, state) end)
  end


end