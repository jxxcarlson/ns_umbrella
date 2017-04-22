defmodule LookupPhoenix.NoteTest do
  use LookupPhoenix.ModelCase

  alias LookupPhoenix.Note
  alias LookupPhoenix.Utility

  @valid_attrs %{content: "some content", title: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Note.changeset(%Note{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Note.changeset(%Note{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "get note" do
    note = %Note{title: "Astrology", identifier: "jxxcarlson.bar"}
    {:ok, note} = Repo.insert(note)
    note2 = Note.get(note.id)
    assert note2 != nil
    assert note2.title == "Astrology"
    note2 = Note.get("jxxcarlson.bar")
    assert note2.title == "Astrology"
    note2 = Note.get("jxxcarlson.yada")
    assert note2 == nil
    note2 = Note.get(1)
    assert note2 == nil
  end

  test "get parent, success" do
    parent_note = %Note{title: "Astrology", identifier: "jxxcarlson.bar"}
    {:ok, parent_note} = Repo.insert(parent_note)
    note = %Note{title: "Magick", parent_id: parent_note.id}
    assert note.parent_id == parent_note.id
    assert Note.get_parent(note) != nil
    assert Note.get_parent(note).title == "Astrology"
  end

  test "get parent, parent does not exist" do
    parent_note = %Note{title: "Astrology", identifier: "jxxcarlson.bar"}
    {:ok, parent_note} = Repo.insert(parent_note)
    note = %Note{title: "Magick", parent_id: 1}
    assert Note.get(1) == nil
    # assert Note.get_parent(note) == nil
  end

  test "get parent, failure" do
    note = %Note{title: "Magick"}
    assert Note.get_parent(note) == nil
  end

  test "get parent from tags" do
    parent_note = %Note{title: "Astrology", identifier: "jxxcarlson.bar"}
    {:ok, parent_note} = Repo.insert(parent_note)
    note = %Note{title: "Magick", tags: ["foo", "bar", "parent:jxxcarlson.bar"]}
    parent_note2 = Note.get_parent_from_tags(note)
    assert parent_note2.title == "Astrology"
  end

   test "get parent identifier from tags" do
      note = %Note{title: "Magick", tags: ["foo", "bar", "parent:jxxcarlson.bar"]}
      parent_identifier = Note.parent_identfier_from_tags(note)
      assert parent_identifier == "jxxcarlson.bar"
   end

   test "set_parent" do
     note = %Note{title: "Magick", content: "Test"}
     note = Repo.insert!(note)
     note = Note.set_parent(note, 22)
     assert note.parent_id == 22
     assert note.tag_string == "parent:22"
     assert note.tags == ["parent:22"]

     note = Note.set_parent(note, 777)
     assert note.parent_id == 777
     assert note.tag_string == "parent:777"
     assert note.tags == ["parent:777"]

     note = Note.set_parent(note, nil)
     assert note.parent_id == nil
     assert note.tag_string == "-"
     assert note.tags == []   end

   test "set_tags" do
      note = %Note{title: "Magick", content: "Test"}
      note = Repo.insert!(note)
      note = Note.set_tags(note, ["foo", "bar"])
      assert note.tags == ["foo", "bar"]
   end


  test "set_parent_from_tags -- set parent_id to nil via parent:none tag" do
     parent_note = %Note{title: "Astrology", identifier: "jxxcarlson.astro", content: "test"}
     {:ok, parent_note} = Repo.insert(parent_note)
     note = %Note{title: "Magick", tags: ["foo", "bar", "parent:jxxcarlson.astro"], content: "yada"}
     {:ok, note} = Repo.insert(note)
     note_id = note.id
     note = Note.get(note_id)

     assert Enum.member?(note.tags, "parent:jxxcarlson.astro")
     note = Note.set_tags(note, ["foo", "bar", "parent:none"])
     note = Note.set_parent_from_tags(note)
     assert note.parent_id == nil

  end

 test "set_parent_from_tags -- change parent_id" do
     parent_note = %Note{title: "Astrology", identifier: "jxxcarlson.astro", content: "test"}
     parent_note = Repo.insert!(parent_note)
     note = %Note{title: "Magick",  content: "yada", tags: ["parent:jxxcarlson.astro"]}
     note = Repo.insert!(note)

     note = Note.set_parent_from_tags(note)
     assert note.parent_id == parent_note.id
  end

  test "set_parent_from_tags -- change INTEGER parent_id" do
      parent_note = %Note{title: "Astrology", identifier: "jxxcarlson.astro", content: "test"}
      parent_note = Repo.insert!(parent_note)
      note = %Note{title: "Magick",  content: "yada", tags: ["parent:#{parent_note.id}"]}
      note = Repo.insert!(note)

      note = Note.set_parent_from_tags(note)
      assert note.parent_id == parent_note.id
  end

  test "set_parent_from_tags -- no change if 'parent:IDENTIFIER' not in tags" do
      parent_note = %Note{title: "Astrology", identifier: "jxxcarlson.astro", content: "test"}
      parent_note = Repo.insert!(parent_note)
      note = %Note{title: "Magick", content: "yada", parent_id: parent_note.id,
         tags: ["foo", "bar"]}
      note = Repo.insert!(note)

      note = Note.set_parent_from_tags(note)
      assert note.parent_id == parent_note.id
   end

end
