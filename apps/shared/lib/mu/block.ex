defmodule MU.Block do

  import MU.Regex
  alias LookupPhoenix.Utility


  def split_at(str, sep_str) do
    if str == nil do
      [nil, nil]
    else
      result = String.split(str, sep_str)
      if length(result) == 1 do
        [hd(result), nil]
      else
        result
      end
    end
  end


  @moduledoc """
  Module MU.Block parses and renders blocks.  There is a
  single public function, MU.block.transform(TEXT) -> TEXT


  Block Example:

  [quote, Oscar Wilde]
  --
  There are only two tragedies in life: one is not getting
  what one wants, and the other is getting it.
  --

  Format:

  [BLOCK_PARAMS]
  --
  BLOCK_BODY
  --

  BLOCK_PARAMS = items separated by commas
  The first item is the block type, e.g., "quote", "click"
  The remaining items (if any) are the block args.  Often the
  second arg is a title.

"""
  def transform(text) do
    # begin_time = Timex.now
    text = String.replace(text, "\r\n", "\n") # normalize
    # eqno_map is a map from labels to equation number, e.g.,
    # %{ "pythag"" => 1, "fourier" => 2 }
    data = %{text: text, equation_counter: 0, eqno_map: %{}}
    data2 = Regex.scan(block_regex, text)
    |> Enum.reduce(data, fn(triple, data) ->
    
       [target, block_meta, block_contents] = triple;
       [type | args]= split_at(block_meta, ",")
       [type, species] = split_at(type, ".")
       [species | label] = split_at(species, "#")

       if label != nil && label != [] do
         label = hd(label)
       else
         label = nil
       end

       params = %{type: type, species: species, label: label, target: target,
         args: args, contents: block_contents
         }

       transform_block(String.to_atom(type), data, params)
     end)
      # Utility.benchmark(begin_time, text, "3. MU.Block")
      resolve_references(data2.text, data2.eqno_map)
  end

  def resolve_reference(ref, text, reference_map) do
    [target, ref_id] = ref
    # :SELF is a route that will be filled in by the controller presenting this text:
    String.replace(text, target, "<span><a href=\"/:SELF\##{ref_id}\">(#{reference_map[ref_id]})</a></span>")
  end

  def resolve_references(text, reference_map) do
    # Produce a list of references, where one reference is
    # of the form [reference_text, label]
    Regex.scan(reference_regex, text)
    |> Enum.reduce(text, fn(ref, text) -> resolve_reference(ref, text, reference_map) end)
  end

  defp transform_block(:quote, data, params) do
    cond do
      params.args == [] ->
        replacement = "<div class='quote'>\n#{params.contents}\n</div>"
      true ->
        attribution = hd params.args
        replacement = "<div class='quote'>\n#{params.contents}\n\n-- #{attribution}</div>"
    end
    text = String.replace(data.text, params.target,replacement)
    %{ data | :text => text }
  end

  defp transform_block(:display, data, params) do
    cond do
      params.args == [] ->
        replacement = "<div class='display'>\n#{params.contents}</div>"
      true ->
        title = hd params.args
        replacement = "<div class='display'><strong>#{title}</strong>\n#{params.contents}</div>"
    end
    text = String.replace(data.text, params.target, replacement)
    %{ data | :text => text }
  end

  defp transform_block(:blurb, data, params) do
    title = String.capitalize(params.type)
    replacement = "<div class='blurb'><span style=\"font-style:italic\">#{params.contents}</span></div>"
    text = String.replace(data.text, params.target,replacement)
    %{ data | :text => text }
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end


  defp transform_block(:click, data, params) do
    identifier = random_string(4)
    cond do
      params.args == [] ->
         replacement = "<span><span id=\"QQ.#{identifier}\" class=\"answer_head\">Answer:</span> <span id=\"QQ.#{identifier}.A\" class=\"hide_answer\">#{params.contents}</span></span>"
      true ->
         title = hd params.args
         replacement = "<span><span id=\"QQ.#{identifier}\" class=\"answer_head\">#{title}</span> <span id=\"QQ.#{identifier}.A\" class=\"hide_answer\">#{params.contents}</span></span>"
    end
    text = String.replace(data.text, params.target,replacement)
    %{ data | :text => text }
  end

  defp make_clickblock(line, counter) do
    [question, answer] = String.split(line, "|") |> Enum.map(fn(item) -> String.trim(item) end)
    identifier = random_string(4)
    "<p><span id=\"QQ.#{identifier}\" class=\"answer_head\">#{counter + 1}. #{question}</span> <span id=\"QQ.#{identifier}.A\" class=\"hide_answer\">#{answer}</span></p>\n"
  end


  defp transform_block(:clicktable, data, params) do
     new_contents = String.split(params.contents, ["\n", "\r", "\r\n"])
     |> Enum.reduce(%{counter: 0, text: ""}, fn(line, acc)
        -> %{counter: acc.counter + 1, text: acc.text <> make_clickblock(line, acc.counter)} end)
     Utility.report("new_contents", new_contents)
     replacement = "<div class='clicktable'>\n#{new_contents.text}</div>"
     text = String.replace(data.text, params.target, replacement)
     %{ data | :text => text }
  end

  defp make_reverse_clickblock(line, counter) do
    [question, answer] = String.split(line, "|") |> Enum.map(fn(item) -> String.trim(item) end)
    identifier = random_string(4)
    "<p><span id=\"QQ.#{identifier}\" class=\"answer_head\">#{counter + 1}. #{answer}</span> <span id=\"QQ.#{identifier}.A\" class=\"hide_answer\">#{question}</span></p>\n"
  end



  defp transform_block(:reverse_clicktable, data, params) do
     new_contents = String.split(params.contents, ["\n", "\r", "\r\n"])
     |> Enum.reduce(%{counter: 0, text: ""}, fn(line, acc)
        -> %{counter: acc.counter + 1, text: acc.text <> make_reverse_clickblock(line, acc.counter)} end)
     Utility.report("new_contents", new_contents)
     replacement = "<div class='clicktable'>\n#{new_contents.text}</div>"
     text = String.replace(data.text, params.target, replacement)
     %{ data | :text => text }
  end

  defp transform_block(:env, data, params) do
    cond do
      params.species != nil ->
        transform_env_block(String.to_atom(params.species), data, params)
      true ->
        transform_open_env_block(data, params)
    end
  end

  defp transform_env_block(:equationalign, data, params) do
    replacement = "<div class='env'>\n\\[\n\\begin\{split\}\n#{params.contents}\n\\end\{split\}\n\\]\n</div>"
    """
     <div class="env">
           <div>
             #{params.contents}
           </div>
     </div>
    """
    text = String.replace(data.text, params.target, replacement)
    %{ data | :text => text }
  end

  @doc """
  A basic env.equation block looks like this

  [env.equation]
  --
  a^2 + b^2 = c^2
  --

  It is rendered as

  \[
  \begin{equation}
  a^2 + b^2 = c^2
  \end{equation}
  \]

  A variant of this block contains a label:
  [env.equation#pythag]
  --
  a^2 + b^2 = c^2
  --

  It is rendered as
  \[
  \begin{equation}
  \label{pythag}
  a^2 + b^2 = c^2
  \end{equation}
  \]

  """
  defp transform_env_block(:equation, data, params) do
    if params.label == nil do
      count = data.equation_counter
      replacement = "<div class='env'>\n\\[\n\\begin\{equation\}\n#{params.contents}\n\\end\{equation\}\n\\]\n</div>"
      text = String.replace(data.text, params.target, replacement)
      %{ data | :text => text }
    else
      count = data.equation_counter + 1
      replacement = "<table  class=\"equation\" ><tr><td class=\"equation\" style=\"width:90%;\">\n\\[#{params.contents}\n\\]\n</td><td class=\"equation\"  style=\"width:10%;\"><a name=\"#{params.label}\">(#{count})</a></td></tr></table>"
      eqno_map = data[:eqno_map]
      eqno_map = Map.merge(eqno_map, %{params.label => count} )
      text = String.replace(data.text, params.target, replacement)
      %{ data | :text => text, :equation_counter => count, :eqno_map => eqno_map }
    end


  end

  @doc """
  A texmacro block looks like this

  [env.texmacro]
  --
  \newcommand{\bor}{\mathbf{r}}
  \newcommand{\bov}{\mathbf{v}}

  \newcommand{\boa}{\mathbf{a}}
  --

  It is rendered as
  \[
   \newcommand{\bor}{\mathbf{r}}
   \newcommand{\bov}{\mathbf{v}}
   \newcommand{\boa}{\mathbf{a}}
  \]

  Notice that blank lines are stripped out
  """
  defp transform_env_block(:texmacro, data, params) do

    contents = String.split(params.contents, ["\n", "\r", "\r\n"])
      |> Enum.filter(fn(line) -> line != "" end)
      |> Enum.map(fn(line) -> "\\[#{line}\\]" end)
      |> Enum.join("\n")

     replacement = "<div style=\"display:none\">\n#{contents}\n</div>"

     text = String.replace(data.text, params.target,replacement)
    %{ data | :text => text }
  end

  defp transform_env_block(_, data, params) do
    replacement = """
    <div class="env"><strong>#{String.capitalize(params.species)}</strong>
      <div class="env_body">
        #{params.contents}
      </div>
    </div>
    """
    text = String.replace(data.text, params.target, replacement)
    out = %{ data | :text => text }
    out
  end

  defp transform_open_env_block(data, params) do
    replacement = "<div class='env'>\n#{params.contents}</div>"
    text = String.replace(data.text, params.target, replacement)
    %{ data | :text => text }
  end


 # Default if the block type is not recognized
  defp transform_block(_, data, params) do
    replacement =  params.contents
    title = String.capitalize(params.type)
    replacement = "<div class='open_block'><strong>#{title}</strong>\n<p>#{params.contents}</p></div>"

    text = String.replace(data.text, params.target,replacement)
    %{ data | :text => text }
  end



  @doc """
  head_excerpt(text, N):
    1. If the text begins with a hyperlink, return it.
    2. Otherwise, return the
  first N words of text.
  """
  def head_excerpt(text, n_words) do
      items = text
      |> String.split([" ", "\r\n", "\r", "\n"])
      |> Enum.map(fn(item) -> String.strip(item) end )
      |> Enum.filter(fn(item) -> item != "" end)
      if Regex.match?(~r/http/, hd(items)) do
        hd(items)
      else
        items
        |> Enum.slice(0..(n_words-1))
        |> Enum.join(" ")
      end
  end

  @doc """
  A blurb looks like this

  [blurb]
  --
  This is an extremely cool article.
  Please read on!
  --

  A blurb is rendered in main text by
  Block.format(:blurb, text).  In the
  index, it is rendered by formatBlurb(text).
  If a blurb is present, it forms the entirety
  of the index entry.  If it is not present,
  the first N words are displayed (this is
  often ugly).
"""
  def formatBlurb(text) do
      triple = Regex.run(blurb_regex, text)
      if triple != nil do
        [_, _, block_contents] = triple;
        block_contents
      else
        head_excerpt(text, 7)
      end
    end

  def formatCode(text) do
    Regex.replace(code_regex(), text, "<pre><code>\n\\1\n</code></pre>")
  end

  def formatVerbatim(text) do
        Regex.replace(~r/----(?:\r\n|[\r\n])(.*)(?:\r\n|[\r\n])----/msr, text, "<pre>\\1</pre>")
  end





end
