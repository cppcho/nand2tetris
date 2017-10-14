#!/usr/bin/env ruby

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require 'jack/tokenizer'
require 'jack/compilation_engine'

JACK_EXT = '.jack'
XML_EXT = 'TT.xml'

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

@input_file_paths.each do |path|
  p path

  output_path = File.join(File.dirname(path), File.basename(path, JACK_EXT) + XML_EXT)

  input_file = File.new(path, 'r')
  tokenizer = Jack::Tokenizer.new(input_file)
  input_file.close

  output_file = File.new(output_path, 'w+')
  compilation_engine = Jack::CompilationEngine.new(tokenizer, output_file)
  compilation_engine.compile_class
  output_file.close
end
