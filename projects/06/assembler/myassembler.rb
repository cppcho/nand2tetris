#!/usr/bin/env ruby

require 'pathname'
require_relative "parser.rb"
require_relative "code.rb"
require_relative "symbol_table.rb"

file_path = ARGV[0]

parser = Parser.new(file_path)
symbol_table = SymbolTable.new

# 1st parse, handle (XXX) psudo label
pc = 0
while parser.has_more_commands?
  parser.advance
  case parser.command_type
  when :A_COMMAND, :C_COMMAND
      pc += 1
  when :L_COMMAND
    raise "invalid symbol" if parser.symbol.nil?
    symbol_table.add_entry(parser.symbol, pc) unless symbol_table.contains?(parser.symbol)
  end
end

parser.reset
ram_addr_counter = 16

while parser.has_more_commands?
  parser.advance
  value = case parser.command_type
  when :A_COMMAND
    num = Integer(parser.symbol) rescue nil
    if num.nil?
      if symbol_table.contains?(parser.symbol)
        value = symbol_table.get_address(parser.symbol)
      else
        value = ram_addr_counter
        symbol_table.add_entry(parser.symbol, ram_addr_counter)
        ram_addr_counter += 1
      end
    else
      # is a integer
      value = parser.symbol
    end
    "0#{value.to_i.to_s(2).rjust(15, '0')}"
  when :L_COMMAND
    nil
  when :C_COMMAND
    d = Code.dest(parser.dest)
    c = Code.comp(parser.comp)
    j = Code.jump(parser.jump)
    "111#{c}#{d}#{j}"
  end
  puts value if value
end
