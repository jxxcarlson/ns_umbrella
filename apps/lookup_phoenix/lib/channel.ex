defmodule LookupPhoenix.Channel do

  alias LookupPhoenix.User


  @doc """
  Parse channel and reassemble into
  valid form. Valid form is NAME.TAG,
  where NAME is a USERNAME.

  iex> Channel.nomalize("demo.all")
  ["demo", "all"]

  iex> Channel.nomalize("demo.foo.all")
  ["demo", "foo", "all"]

  iex> Channel.nomalize("demo.foo.all")
  "demo", "public"]
"""
  def normalize(channel) do
    parts = String.split(channel, ".")
    name = Enum.at(parts, 0)
    tag = Enum.at(parts, -1)
    if tag == name do
      tag = "public"
    end
    channel = name <> "." <> tag
    [channel, name, tag]
  end

  @doc """
  Given and user and a channel, return
  a valid channel.

  Rules:

  1. Apply Channel.normalize to ensure
     the correct form: NAME.TAG

  2. If NAME is a valid username, pass on
     [channel, name, tag]

  3. If NAME is not valid, return
     the data for channel = NAME.public
"""
  def validated_channel(user, channel) do
    [channel, name, tag] = normalize(channel)
    ch_user = User.find_by_username(name)
    if ch_user == nil do
      name = user.username
      tag = "public"
      channel = name <> "." <> tag
    end
    [channel, name, tag]
  end




end
