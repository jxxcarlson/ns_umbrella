defmodule MU.LineProcessor do

  def process_line(line) do
    
  end

  def work(text) do

    String.split(text, ["\n", "\r", "\r\n"])
    |> Enum.reduce("", fn(line, acc) -> line end)

  end

end