defmodule BlockTest do
  use ExUnit.Case
  # doctest Shared

  alias XMU.Block

  test "decode name"  do
    assert Block.decode_name("foo") == %{name: "foo", subtype: nil, id: nil}
    assert Block.decode_name("foo#yada") == %{name: "foo", subtype: nil, id: "yada"}
    assert Block.decode_name("foo.bar") == %{name: "foo", subtype: "bar", id: nil}
    assert Block.decode_name("foo.bar#yada") == %{name: "foo", subtype: "bar", id: "yada"}
  end

  test "math_block" do
    block = %{type: :math_block, content: ["a^2 + b^2 = c^2"], block_info: %{}}
    output = XMU.Block.render(:math_block, block)
    expected_output = "\n\\[\na^2 + b^2 = c^2\n\\]\n"
    assert output == expected_output
  end

  test "quote" do
    block = %{block_info: %{block_headers: ["quote"], block_separator: "--"},
              content: ["This is a test."], type: :block}
    output = XMU.Block.render(:block, block)
    expected_output = "\n<div class='quote'>\nThis is a test.\n</div>\n"
    assert output == expected_output
  end

  test "display" do
    block = %{block_info: %{block_headers: ["display"], block_separator: "--"},
              content: ["This is a test."], type: :block}
    output = XMU.Block.render(:block, block)
    expected_output = "\n<div class='display'>\nThis is a test.\n</div>\n"
    assert output == expected_output
  end

  test "blurb" do
    block = %{block_info: %{block_headers: ["blurb"], block_separator: "--"},
              content: ["This is a test."], type: :block}
    output = XMU.Block.render(:block, block)
    expected_output = "\n<div class='blurb'>\nThis is a test.\n</div>\n"
    assert output == expected_output
  end

end
