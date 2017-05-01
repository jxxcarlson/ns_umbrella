defmodule MU.Utility do

  def report(message, object) do
    IO.puts "========================"
    IO.puts message
    IO.inspect object
    IO.puts "--"
  end

  def str2identifier(str) do
    Regex.replace(~r/[^A-Za-z0-9_\.]/, str, "_")
    |> String.replace("__", "_")
    |> String.downcase
  end

end