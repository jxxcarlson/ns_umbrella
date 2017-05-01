defmodule XMU.Block do

  @moduledoc """
  Block.render(:block_type, block) dispatches the given block
  to a handler, which returns HTML text.

  Type :block means 'named block'.  These are handled by the
  dispatcher Block.render_named(NAME, block)
"""


  def decode_name(str) do
    [name|parts] = String.split(str, [".", "#"])
    n = Enum.count(parts)
    [subtype, id] = cond do
      n == 2 -> parts
      n == 1 and String.contains?(str, ".") -> [hd(parts), nil]
      n == 1 and String.contains?(str, "#") -> [nil, hd(parts)]
      true -> [nil, nil]
    end
    %{name: name, subtype: subtype, id: id}
  end

  def render_content(:simple, content) do
    Enum.reduce(content, "", fn(line, acc) -> line <> "\n" <> acc end)
  end

  def render(:math_block, block) do
    text = Enum.join(block.content, "\n")
     "\n\\[\n#{block.content}\n\\]\n"
  end

  def render(:paragraph, block) do
    text = render_content(:simple, block.content)
     "\n<p>#{text}\n</p>\n"
  end

  def render(:verbatim, block) do
    text = render_content(:simple, block.content)
     "\n<pre>#{text}\n</pre>\n"
  end

  def render(:section_heading, block) do
    n = block.block_info.level
    "\n<h#{n}> #{block.content} </h#{n}>\n"
  end



  def render(:block, block) do
   consolidated_header = block.block_info.block_headers |> Enum.join(",")
   # [main_header|other_headers] = block.block_info.block_headers
   [name| attributes] = String.split(consolidated_header, ",") |> Enum.map(fn(item) -> String.trim(item) end)
   name_packet = decode_name(name)
   render_named(name_packet.name, name_packet, attributes, block)
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

  def render_named("quote", name_packet, args, block) do
    id = name_packet.id
    div_string = "\n<div class='quote'"
    body = render_content(:simple, block.content)
    div_string = cond do
      id != nil -> div_string <> " id=#{id}"
      true -> div_string
    end
    body = cond do
      args == [] ->
        body
      true ->
        attribution = hd(args)
        body <> "\n-- #{attribution}\n"
    end
    div_string <> ">\n" <> body <> "</div>\n"
  end

  def render_named(_, name_packet, args, block) do
    class = name_packet.name
    id = name_packet.id
    div_string = "\n<div class='#{class}'"
    body = render_content(:simple, block.content)
    div_string = cond do
      id != nil -> div_string <> " id=#{id}" <> ">\n"
      true -> div_string <> ">\n"
    end
    title_string = cond do
      args == [] -> ""
      true -> "<div class='title'>#{hd(args)}</div>\n"
    end
    div_string <> title_string <> body <> "</div>\n"
  end

  @doc """
   Default case: no match, either error or renderer for this
   named block type needs to be impldmented
"""
  def render_named(_, _, _, args, block) do
    IO.puts "I can not render the following block"
    IO.inspect block
    "\n<p>Error: block #{block.type} not rendered</p>\n"
  end

end