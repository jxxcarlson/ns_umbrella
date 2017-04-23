require 'asciidoctor-latex'

def render(text)
  result = Asciidoctor.convert text, { 'dialect' => 'latex' }
  Tuple.new(
    [:ok, result]
  )
end