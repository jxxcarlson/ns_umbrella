def sum_two_integers(one, another)
  result = one + another
  Tuple.new(
    [:ok, result]
  )
end
