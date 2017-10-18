#!/usr/bin/env ruby

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require 'jack/tokenizer'
require 'jack/compilation_engine'

JACK_EXT = '.jack'.freeze
VM_EXT = '.vm'.freeze

path = ARGV[0]

raise 'empty path' if path.nil?

@input_file_paths = []

if File.directory?(path)
  @input_file_paths = Dir.entries(path).map do |f|
    fp = File.join(path, f)
    fp if File.file?(fp) && File.extname(fp) == JACK_EXT
  end.reject(&:nil?)
elsif File.file?(path) && File.extname(path) == JACK_EXT
  @input_file_paths.push(path)
else
  raise "invalid path: #{path}"
end

raise 'no input files' if @input_file_paths.empty?

@input_file_paths.each do |input_path|
  puts "Compiling #{input_path}..."
  output_path = File.join(File.dirname(input_path), File.basename(input_path, JACK_EXT) + VM_EXT)

  # Setup Tokenizer
  input_file = File.new(input_path, 'r')
  tokenizer = Jack::Tokenizer.new(input_file)
  input_file.close

  # Create output file
  output_file = File.new(output_path, 'w+')

  # Setup Compilation Engine
  compilation_engine = Jack::CompilationEngine.new(tokenizer, output_file)
  compilation_engine.compile
  output_file.close
end
