defmodule LookupPhoenix.Utility do

  def report(message, object) do
    IO.puts "========================"
    IO.puts message
    IO.inspect object
    IO.puts "--"
  end

  def stream_report(object, message) do
    IO.puts "========================"
    IO.puts message
    IO.inspect object
    IO.puts "--"
    object
  end

  def benchmark(begin_time, text, message) do
       end_time = Timex.now
       elapsed_time = Timex.diff(end_time, begin_time, :microseconds)
       text_length = String.length(text)
       microsecond_rate = 1000.0*elapsed_time/text_length
       millisecond_rate = microsecond_rate/1000
       IO.puts "#{message}, elapsed time = #{Float.round(elapsed_time/1000.0, 1)} ms, (#{elapsed_time} µs) for #{String.length(text)} characters"
       IO.puts "#{message}, rate = #{Float.round(millisecond_rate, 3)} ms, (#{Float.round(microsecond_rate, 0)} µs) per 1000 characters"

  end

  def firstWord(str) do
    String.split(str) |> List.first
  end

  def xForTrue(flag) do
    if flag do
      "X"
    else
     ""
    end
  end


  def add_index_to_maplist(maplist) do
     Enum.reduce(maplist, %{list: [], index: 0}, fn(map, acc) -> %{ list: acc.list ++ [%{data: map, index: acc.index}], index: acc.index + 1} end).list
     |> Enum.map(fn(pair) -> Map.merge(pair.data, %{index: pair.index}) end)
  end

  def parse_query_string(str) do
    str
    |> String.split("&")
    |> Enum.map(fn(item) -> String.split(item, "=") end )
    |> Enum.reduce(%{}, fn(item, acc) -> Map.merge(acc, %{List.first(item) => List.last(item)}) end )
  end

  def str2map(str, sep \\ "=") do
    parts = String.split(str,sep)
    if length(parts) == 2 do
      [key, value] = parts
      %{key => String.trim(value)}
    else
      %{"foo" => "bar"}
    end

  end

  # "foo: bar, baz: 1" => %{"foo" => "bar", "baz" => "1"}
  def str22map(str, sep \\ "=") do
    map = %{}
    String.split(str, ",") |> Enum.map(fn(item) -> String.trim(item) end)
    |> Enum.reduce(map, fn(str, acc) -> Map.merge(acc, str2map(str, sep)) end)
  end

  def qs2map(string) do
    string
    |> String.split( ["&", ","])
    |> Enum.reduce(%{}, fn(item, acc) -> Map.merge(acc, str2map(item)) end)
  end

  def map22list(m) do
    Map.keys(m) |> Enum.map( fn(key) -> [key, m[key]] end)
  end

  def sort2list(list, direction) do
    case direction do
      "desc" -> list |> Enum.sort(fn(e1, e2) -> hd(tl(e1)) > hd(tl(e2)) end)
       _ -> list |> Enum.sort(fn(e1, e2) -> hd(tl(e1)) <= hd(tl(e2)) end)
    end
  end

  def sort_on_key(list, key, direction) do
      case direction do
        "desc" -> list |> Enum.sort(fn(e1, e2) -> e1[key] > e2[key] end)
         _ -> list |> Enum.sort(fn(e1, e2) -> e1[key] <= e2[key] end)
      end
    end

  def proj1_2list(list) do
    Enum.map(list, fn(element) -> hd(element) end)
  end

  def proj2_2list(list) do
    Enum.map(list, fn(element) -> hd(tl(element)) end)
  end

  def random_element(list) do
    list |> Enum.shuffle |> hd
  end

  def map2string(map) do
    if is_nil(map) do
      ""
    else
      keys = Map.keys(map)
      Enum.reduce(keys, [], fn(key, acc) -> acc ++ [key <> ": " <> map[key]] end)
      |> Enum.join(", ")
    end
  end


   # return elemnts 0..(n-1) as list
   def list_head(list, n) do
     Enum.reduce(1..n, [], fn(k, acc) -> acc ++ hd(list); list = tl(list) end)
   end

   # last([1,3,5]) = 5
   def last(list) do
     n = length(list) - 1
     Enum.at(list, n)
   end


    @doc """
    Given a string, return that string with 'bad' characters
    replaced by underscores.

    ## Example
      iex > sanitize_string("Abc !# def")
        "Abc____defABCD"

     iex > sanitize_string("Abc !# def")
        "Abc____def"
"""
    def sanitize_string(str) do
      Regex.replace(~r/[^A-Za-z0-9_\._]/, str, "_")
      |> String.replace(" ", "_")
    end

    def str2identifier(str) do
       Regex.replace(~r/[^A-Za-z0-9_\.]/, str, "_")
       |> String.replace("__", "_")
       |> String.downcase
    end


end