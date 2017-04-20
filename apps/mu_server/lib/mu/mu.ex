defmodule MU.RenderText do

  alias MU.Paragraph
  alias MU.Inline
  alias MU.Section
  alias MU.Block
  alias MU.List
  alias MU.Table
  alias MU.Link
  alias LookupPhoenix.Utility

  alias MU.MathSci
  alias MU.Scholar


    # mode = plain | markup | latex | collate | toc

    def transform(text, options \\ %{mode: "show", process: "markup"}) do
      case options.process do
        "plain" -> text
        "markup" -> format_markup(text, options) |> filterComments
        "latex" -> format_latex(text, options)  |> filterComments
        _ -> format_markup(text, options)
      end
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

   def word_count(text) do
      text
      |> String.split(~r/\s/)
      |> length
   end

end