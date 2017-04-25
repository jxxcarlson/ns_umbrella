defmodule LookupPhoenix.ImageTest do
  use LookupPhoenix.ModelCase

  alias LookupPhoenix.Image

  @valid_attrs %{owner_id: 42, public: true, source: "some content", title: "some content", url: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Image.changeset(%Image{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Image.changeset(%Image{}, @invalid_attrs)
    refute changeset.valid?
  end
end
