text = """
foo + bar
"* Google: parsec parser combinator"
blah blah
"""

 Regex.scan(~r/^\* (\S.*)$/m, text) 
