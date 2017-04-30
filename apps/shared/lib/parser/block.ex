defmodule XMU.Block do

  @moduledoc """
  Block.render(:block_type, block) dispatches the given block
  to a handler, which returns HTML text.

  Type :block means 'named block'.  These are handled by the
  dispatcher Block.render_named(NAME, block)
"""

  def render(:math_block, block) do
    text = Enum.join(block.content, "\n")
     "\n\\[\n#{block.content}\n\\]\n"
  end

  def render(:paragraph, block) do
    text = Enum.reduce(block.content, "", fn(line, acc) -> line <> "\n" <> acc end)
     "\n<p>#{text}\n</p>\n"
  end

  def render(:verbatim, block) do
    text = Enum.reduce(block.content, "", fn(line, acc) -> line <> "\n" <> acc end)
     "\n<pre>#{text}\n</pre>\n"
  end

  def render(:section_heading, block) do
    n = block.block_info.level
    "\n<h#{n}> #{block.content} </h#{n}>\n"
  end

  def render(:block, block) do
   [main_header|other_headers] = block.block_info.block_headers
   [name| args] = String.split(main_header, ",") |> Enum.map(fn(item) -> String.trim(item) end)
   IO.puts "Block name = #{name}"
   IO.puts "Block args:"
   IO.inspect args
   render_named(name, args, block)
  end

  @doc """
   Default case: no match, either error or renderer for this
   block type needs to be impldmented
"""
  def render(_, block) do
    IO.puts "I can not render the following block"
    IO.inspect block
    "\n<p>Error: block #{block.type} not rendered</p>\n"
  end

  def render_named("quote", args, block) do
    IO.inspect block
    cond do
      args == [] ->
        "<div class='quote'>\n#{block.content}\n</div>"
      true ->
        attribution = hd(args)
        "<div class='quote'>\n#{block.content}\n\n-- #{attribution}</div>"
    end
  end

  @doc """
   Default case: no match, either error or renderer for this
   named block type needs to be impldmented
"""
  def render_named(_, args, block) do
    IO.puts "I can not render the following block"
    IO.inspect block
    "\n<p>Error: block #{block.type} not rendered</p>\n"
  end

end