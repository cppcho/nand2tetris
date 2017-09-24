require "./parser.rb"
require "./code.rb"

file_path = ARGV[0]

parser = Parser.new(file_path)


while parser.has_more_commands?
  parser.advance
  value = case parser.command_type
  when :A_COMMAND
    "0#{parser.symbol.to_i.to_s(2).rjust(15, '0')}"
  when :L_COMMAND
    "TODO"
  when :C_COMMAND
    d = Code.dest(parser.dest)
    c = Code.comp(parser.comp)
    j = Code.jump(parser.jump)
    "111#{c}#{d}#{j}"
  end
  puts value
end
