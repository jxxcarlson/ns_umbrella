defmodule NoteSettings do
  # use Ecto.Model
  use LookupPhoenix.Web, :model

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
end