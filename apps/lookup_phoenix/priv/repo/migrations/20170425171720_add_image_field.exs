defmodule LookupPhoenix.Repo.Migrations.AddImageField do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :image, :string
    end

  end
end
