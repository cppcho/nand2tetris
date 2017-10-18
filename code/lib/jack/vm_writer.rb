module Jack
  class VmWriter
    def initialize(output)
      @output = output
      @tab_enabled = false
    end

    def write_comment(comment)
      output_line("// #{comment}")
    end

    def write_push(segment, index)
      output_line("push #{VmWriter.segment_str(segment)} #{index}")
    end

    def write_pop(segment, index)
      output_line("pop #{VmWriter.segment_str(segment)} #{index}")
    end

    def write_arithmetic(command)
      output_line(VmWriter.command_str(command))
    end

    def write_label(label)
      output_line("label #{label}")
    end

    def write_goto(label)
      output_line("goto #{label}")
    end

    def write_if(label)
      output_line("if-goto #{label}")
    end

    def write_call(name, n_args)
      output_line("call #{name} #{n_args}")
    end

    def write_function(name, n_locals)
      @tab_enabled = true
      output_line("function #{name} #{n_locals}", true)
    end

    def write_return
      output_line('return')
    end

    private

    def output_line(line, no_tab = false)
      if !@tab_enabled || no_tab
        @output.puts(line)
      else
        @output.puts("  #{line}")
      end
    end

    def self.command_str(command)
      case command
      when :ADD
        'add'
      when :SUB
        'sub'
      when :NEG
        'neg' when :EQ
        'eq'
      when :GT
        'gt'
      when :LT
        'lt'
      when :AND
        'and'
      when :ORG
        'org'
      when :NOT
        'not'
      else
        raise "Invalid command '#{command}'"
      end
    end

    def self.segment_str(segment)
      case segment
      when :CONST
        'constant'
      when :ARG
        'argument'
      when :LOCAL
        'local'
      when :STATIC
        'static'
      when :THIS
        'this'
      when :THAT
        'that'
      when :POINTER
        'pointer'
      when :TEMP
        'temp'
      else
        raise "Invalid segment '#{segment}'"
      end
    end
  end
end
