defmodule MU.RenderText do

  alias MU.Paragraph
  alias MU.Inline
  alias MU.Section
  alias MU.Block
  alias MU.List
  alias MU.Table
  alias MU.Link
  alias LookupPhoenix.Utility
  alias LookupPhoenix.Note

  alias MU.MathSci
  alias MU.Scholar

  alias NS.Notebook.TOC
  alias NS.Notebook.TOC2


    # mode = plain | markup | latex | collate | toc

    def transform(text, options \\ %{mode: "show", process: :exmark}) do
      IO.puts "MU.RenderText in APPLICATION MU_SERVER"
      Utility.report "OPTIONS", options
      # begin_time = Timex.now
      result = case options.process do
        :plain -> text
        :exmark -> format_markup(text, options) |> filterComments
        :adoc_latex ->
          {:ok, rendered_text} = RubyBridge.render_asciidoc(text)
          rendered_text = rendered_text <> "\n\n" <> MU.MathSci.inject_mathjax2()
          # rendered_text
        :exmark_latex ->
          texmacros = Note.get("jxxcarlson.texmacros").content
          if texmacros != nil do
            texmacros = texmacros |> String.replace("----", "")
            env_texmacro = "\n[env.texmacro]\n--\n#{texmacros}\n--\n"
            text = env_texmacro <> text
          end
          format_latex(text, options)  |> filterComments
        :collection -> Collate.collate(text, options) |> format_latex(options)  |> filterComments
        :notebook -> TOC.process(text, options)
        :book -> TOC2.render(text)
        _ -> format_markup(text, options)
      end
      # Utility.benchmark(begin_time, text, "0. MU.transform")
      result
    end

    defp format_markup(text, options) do
      text
      |> Section.format
      |> Block.transform
      |> Block.formatCode
      |> linkify(options)
      |> apply_markdown
      |> Paragraph.format
    end

    defp format_latex(text, options) do
      text
      |> format_markup(options)
      |> MathSci.formatChem
      |> MathSci.formatChemBlock
      |> MathSci.insert_mathjax(options)
    end

    def firstParagraph(text) do
      short_text = Regex.run(~r/.*\s\s/, text)
      case short_text do
        nil -> text
        [] -> text
        _ -> (hd short_text) <> " •••"
      end
    end

    def head_excerpt(text, n_words) do
      text
      |> String.split(" ")
      |> Enum.slice(0..(n_words-1))
      |> Enum.join(" ")
    end

    def format_for_index(text) do
      text
      |> Block.formatBlurb
      |> linkify(%{mode: "index", process: "node"})
      |> Inline.formatBold
      |> Inline.formatRed
      |> Inline.formatItalic
      |> Inline.formatInlineCode
      |> Inline.highlight
    end


    defp linkify(text, options) do
      text
      |> Link.makeYouTubePlayer(options)
      |> Link.makeAudioPlayer
      |> Link.makeImageLinks(options)
      |> Link.makeFormattedImageLinks(options)
      |> Link.formatHyperlink2
      |> Link.formatHyperlink
      |> Link.makePDFLinks(options)
      |> Link.siteLink
    end

    defp apply_markdown(text) do
      text
      |> Table.format
      |> Block.formatCode
      |> Block.formatVerbatim
      |> Inline.transform
      |> Scholar.indexWord
      |> List.formatItems
      |> Scholar.formatAnswer
      |> Link.formatXREF
    end

    defp filterComments(text) do
      String.split(text, ["\r", "\n", "\rn"]) |> Enum.filter(fn(line) -> !Regex.match?(~r/^\/\//, line) end) |> Enum.join("\n")
    end



end