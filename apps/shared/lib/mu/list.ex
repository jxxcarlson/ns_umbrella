defmodule MU.List do

    import MU.Regex

    def formatItems(text) do
       getItems(text)
       |> Enum.reduce(text, fn(item, text) -> String.replace(text, "- " <> item, formatItem(item)) end)
    end

    defp getItems(text) do
      Regex.scan(unordered_list_item_regex(), text)
      |> Enum.map(fn(x) -> hd(tl(x)) end)
      |> Enum.map(fn(item) -> String.trim(item) end)
    end

    defp formatItem  (item) do
      "<span class='mu_item'>&bullet;  #{item}</span>\n\n"
    end


end