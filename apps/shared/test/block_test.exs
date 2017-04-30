defmodule BlockTest do
  use ExUnit.Case
  # doctest Shared

  alias XMU.Block

  test "math_block" do
    block = %{type: :math_block, contents: ["a^2 + b^2 = c^2"], block_info: %{}}
    output = XMU.Block.render(:math_block, block)
    expected_output = "\n\\[\na^2 + b^2 = c^2\n\\]\n"
    assert output == expected_output
  end

  test "quote" do
    block = %{block_info: %{block_headers: ["quote"], block_separator: "--"},
              content: ["This is a test."], type: :block}
    output = XMU.Block.render(:block, block)
    expected_output = "<div class='quote'>\nThis is a test.\n</div>"
    assert output == expected_output
  end
end
