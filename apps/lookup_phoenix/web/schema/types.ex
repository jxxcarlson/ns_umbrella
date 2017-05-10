defmodule NoteApi.Schema.Types do

   # https://ryanswapp.com/2016/11/29/phoenix-graphql-tutorial-with-absinthe/

  use Absinthe.Schema.Notation


  object :note do
    field :id, :id
    field :title, :string
    field :content, :string
    field :tag_string, :string
    field :idx, :integer
    field :identifier, :string
    field :parent_id, :integer
  end

end
