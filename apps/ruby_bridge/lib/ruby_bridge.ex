defmodule RubyBridge do
  @moduledoc """
  Documentation for RubyBridge.
  https://blog.fazibear.me/elixir-ruby-dont-fight-talk-d83d5abc8898
  """
    @ruby_dir Application.app_dir(:ruby_bridge, "priv/ruby")

    use Export.Ruby

    @doc """
    iex> RubyBridge.render_asciidoc("This *is* a test.")
    {:ok, "<div class=\"paragraph\">\n<p>This <strong>is</strong> a test.</p>\n</div>"}
"""
    def render_asciidoc(text) do
      {:ok, ruby} = Ruby.start(ruby_lib: @ruby_dir)

      IO.puts "Hello! This is render_asciidoc"

       # asciidoc_path = "/app/apps/ruby_bridge/priv/ruby/asciidoc"
       asciidoc_path = "asciidoc"

       ruby
       |> Ruby.call(render(text), from_file: asciidoc_path)
    end


    @doc """
    iex > RubyBridge.sum_two_integers_in_ruby(14,2)
    {:ok, 16}
"""
    def sum_two_integers_in_ruby(one, another) do
      {:ok, ruby} = Ruby.start(ruby_lib: @ruby_dir)

      ruby
      |> Ruby.call(sum_two_integers(one, another), from_file: "sum")
    end

end

