defmodule LookupPhoenix.Image do
  use LookupPhoenix.Web, :model
  use Arc.Ecto.Schema

  schema "images" do
    field :image, LookupPhoenix.ImageUploader.Type
    field :title, :string
    field :url, :string
    field :owner_id, :integer
    field :public, :boolean, default: false
    field :source, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:image])
      |> cast_attachments(params, [:image])
    end


end
