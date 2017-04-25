defmodule LookupPhoenix.Index do

  def format(text) do
     String.slice(text, 0, 100)
  end

end