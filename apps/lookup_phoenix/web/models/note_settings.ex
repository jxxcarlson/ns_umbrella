defmodule LookupPhoenix.NoteSettings do
  # use Ecto.Model
  use LookupPhoenix.Web, :model
  alias LookupPhoenix.Repo
  alias LookupPhoenix.Note

  @moduledoc """
  render_as = :plain | :mu | :mu_lates | :adoc | adoc_latex
  doc_type = :note | :notebook
"""

  # embedded_schema is short for:
  #
  #   @primary_key {:id, :binary_id, autogenerate: true}
  #   schema "embedded Item" do
  #
  #


  embedded_schema do
    field :render_as, :string
    field :doc_type, :string
  end


  def set_defaults(note) do
     new_settings = %LookupPhoenix.NoteSettings{render_as: "mm", doc_type: "note"}
     changeset = Ecto.Changeset.change(note)
     changeset = Ecto.Changeset.put_embed(changeset, :settings, new_settings)
     Repo.update!(changeset)
  end


  def update_render_as(note, value) do
    old_settings = note.settings || %LookupPhoenix.NoteSettings{}
    new_settings = Ecto.Changeset.change(old_settings, %{render_as: value})
    changeset = Ecto.Changeset.change(note)
    changeset = Ecto.Changeset.put_embed(changeset, :settings, new_settings)
    Repo.update!(changeset)
  end

  def update_doc_type(note, value) do
    old_settings = note.settings
    new_settings = Ecto.Changeset.change(old_settings, %{doc_type: value})

    changeset =
    note
    |> Ecto.Changeset.change
    |> Ecto.Changeset.put_embed(:settings, new_settings)

    Repo.update!(changeset)
  end


#
#  def update(note, key, value) do
#   changeset = Ecto.Changeset.change(note)
#
#   changeset = Ecto.Changeset.put_embed(changeset, :settings,
#         %LookupPhoenix.NoteSettings{ key: value }
#       )
#    note = Repo.update!(changeset)
#  end

end