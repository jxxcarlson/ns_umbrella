defmodule LookupPhoenix.Channel do


  @doc """
  iex> Channel.nomalize("demo.all")
  ["demo", "all"]

  iex> Channel.nomalize("demo.foo.all")
  ["demo", "foo", "all"]

  iex> Channel.nomalize("demo.foo.all")
  "demo", "public"]
"""
  def normalize(channel) do
    parts = String.split(channel, ".")
    site_name = Enum.at(parts, 0)
    tag = Enum.at(parts, -1)
    if tag == site_name do
      tag = "public"
    end
    [site_name <> "." <> tag, site_name, tag]
  end


end
