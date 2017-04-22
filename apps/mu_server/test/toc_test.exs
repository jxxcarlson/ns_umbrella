defmodule NS.Notebook.TOC.Test do

  use ExUnit.Case
  import LookupPhoenix.Note

  # use LookupPhoenix.ModelCase
  alias NS.Notebook.TOC
  alias LookupPhoenix.Note
  alias LookupPhoenix.Repo



  test "TOC.process II" do
    IO.puts "Number 1"
    alpha_p = %Note{title: "Alpha", content: "Test, alpha"}
    beta_p = %Note{title: "Beta", content: "Test, beta"}
    gamma_p = %Note{title: "Gammma", content: "Test, gamma"}
    alpha = Repo.insert!(alpha_p)
    beta = Repo.insert!(beta_p)
    gamma = Repo.insert!(gamma_p)

    options = %{mode: "show", note_id: 1045, process: "markup", public: false,
                toc_history: "1044>1045", username: "jxxcarlson"}
    text = """
    #{alpha.id}, Alpha
    title, Foo
    #{beta.id}, Beta
    #{gamma.id}, Gamma
"""
    output = TOC.process(text, options)
    IO.puts ("output = #{IO.inspect(output)}")
  end

%{mode: "show", note_id: 1045, process: "markup", public: false,
  toc_history: "1044>1045", username: "jxxcarlson"}

  test "TOC.process IIAA" do
    IO.puts "Number 2"
    options = %{mode: "show", note_id: 1010, path_segment: "show2",
      process: "toc", public: true, toc_history: "", user_id: 9}
    text = "1045, Alpha title, Foo 1046, Beta 1047, Gamma"
    TOC.process(text, options)
  end


end
