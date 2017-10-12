module Vm
  TEMP_BASE = 5
  SP_BASE = 256

  class CodeWriter
    def initialize(file_path)
      raise 'empty file_path' if file_path.nil?

      @label_counter = 0
      @current_file_name = nil
      @max_static_index = -1
      @current_function_name = 'GLOBAL'

      @file = File.new(file_path, 'w+')

      # @file.puts('// Initialize SP (RAM[0]) to 256 (Initial stack pointer)')
      # @file.puts('@256')
      # @file.puts('D=A')
      # @file.puts('@SP')
      # @file.puts('M=D')
    end

    def set_file_name(file_name)
      @file.puts("// File: #{file_name}")
      @current_file_name = file_name
    end

    def write_init
      @file.puts('// Bootstrap')
      @file.puts('// SP=256')
      @file.puts('// call Sys.init')
      # TODO:
      # @file.puts("@#{SP_BASE}")
      # @file.puts('D=A')
      # @file.puts('@SP')
      # @file.puts('M=D')
    end

    def write_label(label)
      @file.puts("// label #{label}")
      @file.puts("(#{@current_function_name}.#{label})")
    end

    def write_goto(label)
      @file.puts("// goto #{label}")
      @file.puts("@#{@current_function_name}.#{label}")
      @file.puts('0;JMP')
    end

    def write_if(label)
      @file.puts("// if-goto #{label}")
      @file.puts('@SP')
      @file.puts('M=M-1')
      @file.puts('A=M')
      @file.puts('D=M')
      @file.puts("@#{@current_function_name}.#{label}")
      @file.puts('D;JGT')
    end

    def write_call(function_name, num_args)

    end

    def write_function(function_name, num_locals)
      @file.puts("// function #{function_name} #{num_locals}")
      (0...num_locals.to_i).each do |i|              # repeat num_locals times:
        write_push_pop(:C_PUSH, 'constant', 0)  # PUSH 0
      end
    end

    def write_return
      @file.puts("// return")
      @file.puts("@LCL")    # FRAME(R13) = LCL
      @file.puts("D=M")
      @file.puts("@R13")
      @file.puts("M=D")
      @file.puts("@5")      # RET(R14) = *(FRAME-5)
      @file.puts("D=D-A")
      @file.puts("A=D")
      @file.puts("D=M")
      @file.puts("@R14")
      @file.puts("M=D")
      @file.puts("@SP")     # *ARG = pop()
      @file.puts("AM=M-1")
      @file.puts("D=M")
      @file.puts("M=0")
      @file.puts("@ARG")
      @file.puts("A=M")
      @file.puts("M=D")
      @file.puts("@ARG")    # SP = ARG + 1
      @file.puts("D=M+1")
      @file.puts("@SP")
      @file.puts("M=D")
      @file.puts("@R13")    # THAT = *(FRAME - 1)
      @file.puts("A=M-1")
      @file.puts("D=M")
      @file.puts("@THAT")
      @file.puts("M=D")
      @file.puts("@R13")    # THIS = *(FRAME - 2)
      @file.puts("D=M")
      @file.puts("@2")
      @file.puts("D=D-A")
      @file.puts("A=D")
      @file.puts("D=M")
      @file.puts("@THIS")
      @file.puts("M=D")
      @file.puts("@R13")    # ARG = *(FRAME - 3)
      @file.puts("D=M")
      @file.puts("@3")
      @file.puts("D=D-A")
      @file.puts("A=D")
      @file.puts("D=M")
      @file.puts("@ARG")
      @file.puts("M=D")
      @file.puts("@R13")    # LCL = *(FRAME - 4)
      @file.puts("D=M")
      @file.puts("@4")
      @file.puts("D=D-A")
      @file.puts("A=D")
      @file.puts("D=M")
      @file.puts("@LCL")
      @file.puts("M=D")
      @file.puts("@R14")    # goto RET
      @file.puts("A=M")
      @file.puts("0;JMP")
    end

    def write_arithmetic(command)
      case command
      when 'add', 'sub', 'and', 'or'
        @file.puts("// #{command}")
        @file.puts('@SP')
        @file.puts('AM=M-1')
        @file.puts('D=M')
        @file.puts('M=0')
        @file.puts('@SP')
        @file.puts('AM=M-1')
        if command == 'add'
          @file.puts('D=D+M')
        elsif command == 'sub'
          @file.puts('D=M-D')
        elsif command == 'and'
          @file.puts('D=D&M')
        elsif command == 'or'
          @file.puts('D=D|M')
        end
        @file.puts('M=0')
      when 'neg', 'not'
        @file.puts("// #{command}")
        @file.puts('@SP')
        @file.puts('AM=M-1')
        @file.puts('D=M')
        @file.puts('M=0')
        if command == 'neg'
          @file.puts('D=-D')
        else
          @file.puts('D=!D')
        end
      when 'eq', 'gt', 'lt'
        @file.puts("// #{command}")
        @file.puts('@SP')
        @file.puts('AM=M-1')
        @file.puts('D=M')
        @file.puts('M=0')
        @file.puts('@SP')
        @file.puts('AM=M-1')
        @file.puts('D=D-M')
        @file.puts('M=0')

        label_cond = new_label
        label_end = new_label

        @file.puts("@#{label_cond}")

        if command == 'eq'
          @file.puts("D;JEQ")
        elsif command == 'gt'
          @file.puts("D;JLT")
        else
          @file.puts("D;JGT")
        end

        @file.puts('D=0')
        @file.puts("@#{label_end}")
        @file.puts('0;JMP')
        @file.puts("(#{label_cond})")
        @file.puts('D=-1')
        @file.puts("(#{label_end})")
      else
        raise "invalid command #{command}"
      end
      # Push result D to the stack
      @file.puts('@SP')
      @file.puts('A=M')
      @file.puts('M=D')
      @file.puts('@SP')
      @file.puts('M=M+1')
    end

    def write_push_pop(command, segment, index)
      case command
      when :C_PUSH
        case segment
        when 'argument', 'local', 'this', 'that', 'temp'
          @file.puts("// push #{segment} #{index}")
          if segment == 'argument'
            @file.puts('@ARG')
          elsif segment == 'local'
            @file.puts('@LCL')
          elsif segment == 'this'
            @file.puts('@THIS')
          elsif segment == 'that'
            @file.puts('@THAT')
          elsif segment == 'temp'
            @file.puts("@#{TEMP_BASE}")
          end
          if segment == 'temp'
            @file.puts('D=A')
          else
            @file.puts('D=M')
          end
          @file.puts("@#{index}")
          @file.puts('D=D+A')
          @file.puts('A=D')
          @file.puts('D=M')
        when 'static'
          write_extra_static_vars(index)
          write_static_var_label(index)
          @file.puts('D=M')
        when 'constant'
          @file.puts("// push constant #{index}")
          @file.puts("@#{index}")
          @file.puts('D=A')
        when 'pointer'
          @file.puts("// push pointer #{index}")
          if index.zero?
            @file.puts('@THIS')
          elsif index == 1
            @file.puts('@THAT')
          else
            raise "invalid pointer index #{index}"
          end
          @file.puts('D=M')
        else
          raise 'invalid command'
        end
        # Push the value in D to stack
        @file.puts('@SP')
        @file.puts('A=M')
        @file.puts('M=D')
        # Increment SP
        @file.puts('@SP')
        @file.puts('M=M+1')
      when :C_POP
        @file.puts("// pop #{segment} #{index}")
        # Decrement SP
        @file.puts('@SP')
        @file.puts('M=M-1')

        case segment
        when 'argument', 'local', 'this', 'that', 'temp'
          # Calculate the save target location and store to R13
          if segment == 'argument'
            @file.puts('@ARG')
          elsif segment == 'local'
            @file.puts('@LCL')
          elsif segment == 'this'
            @file.puts('@THIS')
          elsif segment == 'that'
            @file.puts('@THAT')
          elsif segment == 'temp'
            @file.puts("@#{TEMP_BASE}")
          end
          if segment == 'temp'
            @file.puts('D=A')
          else
            @file.puts('D=M')
          end
          @file.puts("@#{index}")
          @file.puts('D=D+A')
          @file.puts('@R13')
          @file.puts('M=D')
          # Pop the value from stack and store to the target location
          @file.puts('@SP')
          @file.puts('A=M')
          @file.puts('D=M')
          @file.puts('M=0')
          @file.puts('@R13')
          @file.puts('A=M')
          @file.puts('M=D')
        when 'pointer'
          @file.puts('@SP')
          @file.puts('A=M')
          @file.puts('D=M')
          @file.puts('M=0')
          if index.zero?
            @file.puts('@THIS')
          elsif index == 1
            @file.puts('@THAT')
          else
            raise "invalid pointer index #{index}"
          end
          @file.puts('M=D')
        when 'static'
          write_extra_static_vars(index)
          @file.puts('@SP')
          @file.puts('A=M')
          @file.puts('D=M')
          @file.puts('M=0')
          write_static_var_label(index)
          @file.puts('M=D')
        when 'constant'
          raise 'cannot pop to constant segment'
        end
      else
        raise 'invalid command'
      end
    end

    def close
      @file.close
    end

    private

    def new_label
      label = "LBL#{@label_counter}"
      @label_counter += 1
      label
    end

    def write_static_var_label(index)
      @file.puts("@#{@current_file_name}.#{index}")
    end

    def write_extra_static_vars(index)
      return nil if index < @max_static_index
      ((@max_static_index + 1)...index).each do |i|
        write_static_var_label(i)
      end
      @max_static_index = index
      nil
    end
  end
end
