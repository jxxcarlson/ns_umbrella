defmodule NoteApi.Schema do
  use Absinthe.Schema
  # The import_Types macro brings our types in to use
  import_types NoteApi.Schema.Types

  # We'll define a query to get our users.  It returns a list of users, and this
  # query is resolved by a function in a module we'll make momentarily.
  query do
    field :notes, list_of(:note) do
      resolve &NoteApi.NoteResolver.all/2
    end
  end
end
