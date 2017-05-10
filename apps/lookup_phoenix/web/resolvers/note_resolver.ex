defmodule NoteApi.NoteResolver do
  alias LookupPhoenix.{Repo, Note}
  # We won't do anything with any arguments that are passed into this query for
  # now.
  def all(_args, _info) do
    {:ok, Repo.all(Note)}
  end
end