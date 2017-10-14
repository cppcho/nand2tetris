require 'vm/code_writer'
require 'vm/parser'

module Vm
  VM_EXT = '.vm'.freeze
  ASM_EXT = '.asm'.freeze

  class VMTranslator
    def initialize(path)
      raise 'empty path' if path.nil?

      @vm_files = []
      @output_file = nil

      if File.directory?(path)
        @vm_files = Dir.entries(path).map do |f|
          fp = File.join(path, f)
          fp if File.file?(fp) && File.extname(fp) == VM_EXT
        end.reject(&:nil?)
        @output_file = File.join(path, File.basename(path, VM_EXT) + ASM_EXT)
      elsif File.file?(path) && File.extname(path) == VM_EXT
        @vm_files.push(path)
        @output_file = File.join(File.dirname(path), File.basename(path, VM_EXT) + ASM_EXT)
      else
        raise "invalid path: #{path}"
      end

      raise 'no vm files' if @vm_files.empty?
    end

    def run
      code_writer = Vm::CodeWriter.new(@output_file)
      code_writer.write_init
      @vm_files.each do |f|
        parser = Vm::Parser.new(f)
        code_writer.set_file_name(File.basename(f, VM_EXT))

        while parser.has_more_commands?
          parser.advance

          case parser.command_type
          when :C_ARITHMETIC
            code_writer.write_arithmetic(parser.arg1)
          when :C_PUSH, :C_POP
            code_writer.write_push_pop(parser.command_type, parser.arg1, parser.arg2.to_i)
          when :C_LABEL
            code_writer.write_label(parser.arg1)
          when :C_GOTO
            code_writer.write_goto(parser.arg1)
          when :C_IF
            code_writer.write_if(parser.arg1)
          when :C_FUNCTION
            code_writer.write_function(parser.arg1, parser.arg2)
          when :C_CALL
            code_writer.write_call(parser.arg1, parser.arg2)
          when :C_RETURN
            code_writer.write_return
          end
        end
      end
      code_writer.close
    end
  end
end
