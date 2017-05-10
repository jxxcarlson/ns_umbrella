defmodule NoteApi.Schema.Types do

  use Absinthe.Schema.Notation

  object :note do
    field :id, :id
    field :title, :string
    field :content, :string
    field :tag_string, :string
    field :public, :boolean
    field :shared, :boolean
    field :idx, :integer
    field :identifier, :string
    field :parent_id, :integer
  end

end
