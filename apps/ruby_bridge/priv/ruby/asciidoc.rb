puts "(1) Hello, I am here, in asciidoc.rb, top of file"

# require 'asciidoctor-latex'
require "/app/vendor/bundle/ruby/2.3.0/bundler/gems/asciidoctor-latex-b5c9de1363de/bin/asciidoctor-latex"

# require '/app/vendor/bundle/bin/asciidoctor-latex'
# ?? /app/vendor/bundle/ruby/2.3.0/gems/asciidoctor-1.5.5

def render(text)
  puts "(2) Hello, I am here, in asciidoc.rb -- render(text)"
  result = Asciidoctor.convert text, { 'dialect' => 'latex' }
  # result = "Text length = #{text.length}"
  Tuple.new(
    [:ok, result]
  )
end