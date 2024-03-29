#!/usr/bin/env ruby

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require 'jack/tokenizer'
require 'jack/compilation_engine_xml'

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

@input_file_paths.each do |input_path|
  puts "Analyzing #{input_path}..."
  output_path = File.join(File.dirname(input_path), File.basename(input_path, JACK_EXT) + XML_EXT)

  # Setup Tokenizer
  input_file = File.new(input_path, 'r')
  tokenizer = Jack::Tokenizer.new(input_file)
  input_file.close

  # Setup Compilation Engine
  output_file = File.new(output_path, 'w+')
  compilation_engine = Jack::CompilationEngineXml.new(tokenizer, output_file)
  compilation_engine.compile_class
  output_file.close
end
