defmodule LookupPhoenix.Repo.Migrations.CreateImage do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :title, :string
      add :url, :string
      add :owner_id, :integer
      add :public, :boolean, default: false, null: false
      add :source, :string

      timestamps()
    end

  end
end
