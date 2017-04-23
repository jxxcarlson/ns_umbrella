require 'asciidoctor'

def render(text)
  result = Asciidoctor.convert text, safe: :safe
  Tuple.new(
    [:ok, result]
  )
end