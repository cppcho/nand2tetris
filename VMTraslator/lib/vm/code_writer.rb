module Vm
  TEMP_BASE = 5
  SP_BASE = 256
  LOCAL_BASE = 300
  ARGUMENT_BASE = 400
  THIS_BASE = 3000
  THAT_BASE = 3010

  class CodeWriter
    def initialize(file_path)
      raise 'empty file_path' if file_path.nil?

      @label_counter = 0
      @current_file_name = nil
      @max_static_index = -1

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
