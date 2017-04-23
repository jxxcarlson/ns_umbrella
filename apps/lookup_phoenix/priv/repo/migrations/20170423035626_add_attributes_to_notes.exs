defmodule LookupPhoenix.Repo.Migrations.AddAttributesToNotes do
  use Ecto.Migration

   def change do
     alter table(:notes) do
       add :settings, :map
     end
   end
end
