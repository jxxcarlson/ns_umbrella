defmodule XMU.Block do

  def render(:math_block, block) do
    text = Enum.join(block.contents, "\n")
     "\n\\[\n#{block.contents}\n\\]\n"
  end

  def render(:quote, block) do
#    cond do
#      params.args == [] ->
#        replacement = "<div class='quote'>\n#{params.contents}\n</div>"
#      true ->
#        attribution = hd params.args
#        replacement = "<div class='quote'>\n#{params.contents}\n\n-- #{attribution}</div>"
#    end
#    text = String.replace(data.text, params.target,replacement)
#    %{ data | :text => text }
  end


end