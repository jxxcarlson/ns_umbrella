defmodule LookupPhoenix.NoteSettingsTest do
  use LookupPhoenix.ModelCase

  alias LookupPhoenix.Note
  alias LookupPhoenix.NoteSettings
  alias LookupPhoenix.Repo

  test "bare-metal update render_as" do
    note = %Note{title: "Yada", content: "Bada"}
    note = Repo.insert!(note)
    assert note.title == "Yada"

    changeset = Ecto.Changeset.change(note)

    changeset = Ecto.Changeset.put_embed(changeset, :settings,
      %NoteSettings{
        render_as: "plain",
      }
    )
    note = Repo.update!(changeset)

    assert note.settings.render_as ==  "plain"

  end

  test "set defaults" do
    note = %Note{title: "Yada", content: "Bada"}
    note = Repo.insert!(note)
    assert note.title == "Yada"

    note = NoteSettings.set_defaults(note)

    assert note.settings.render_as ==  "mm"
    assert note.settings.doc_type ==  "note"

  end

  test "use NoteSettings.update_render_as to update render_as" do
    note = %Note{title: "Yada", content: "Bada"}
    note = Repo.insert!(note)
    note = NoteSettings.set_defaults(note)

    # note = NoteSettings.update_render_as(note, "plain")
    note = NoteSettings.update_doc_type(note, "index")

    # assert note.settings.render_as ==  "plain"
    assert note.settings.doc_type ==  "index"
  end

  test "use Note.render_as to determine render type" do
    note = %Note{title: "Yada", content: "Bada", tags: [":latex"]}
    note = Repo.insert!(note)
    assert Note.rendering_process(note) == :exmark_latex
  end

  test "use Note.render_as to determine render type - default case" do
    note = %Note{title: "Yada", content: "Bada", tags: []}
    note = Repo.insert!(note)
    assert Note.rendering_process(note) == :exmark
  end

#  test "use NoteSettings.update to update render_as" do
#    note = %Note{title: "Yada", content: "Bada"}
#    note = Repo.insert!(note)
#    assert note.title == "Yada"
#
#    note = NoteSettings.update(note, :render_as, "plain")
#
#    assert note.settings.render_as ==  "plain"
#
#  end
end