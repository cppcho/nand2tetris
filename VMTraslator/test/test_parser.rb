require 'vm/parser'

class ParserTest < Test::Unit::TestCase

  def test_one
    parser = Vm::Parser.new('./test/test_parser.vm')
    assert_true parser.has_more_commands?
    parser.advance
    assert_equal parser.command_type, :C_PUSH
    assert_equal parser.arg1, 'constant'
    assert_equal parser.arg2, '7'
    parser.advance
    assert_equal parser.command_type, :C_PUSH
    assert_equal parser.arg1, 'constant'
    assert_equal parser.arg2, '8'

    parser.advance
    assert_equal parser.command_type, :C_ARITHMETIC
    assert_equal parser.arg1, 'add'
  end
end
