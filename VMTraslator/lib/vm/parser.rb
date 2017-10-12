module Vm
  class Parser

    C_ARITHMETIC_REGEX = /^(add|sub|neg|eq|gt|lt|and|or|not)$/
    C_PUSH_REGEX = /^push\s+(argument|local|static|constant|this|that|pointer|temp)\s+([0-9]+)$/
    C_POP_REGEX = /^pop\s+(argument|local|static|constant|this|that|pointer|temp)\s+([0-9]+)$/
    C_LABEL_REGEX = /^label\s+([^\s]+)$/
    C_GOTO_REGEX = /^goto\s+([^\s]+)$/
    C_IF_REGEX = /^if\-goto\s+([^\s]+)$/
    C_FUNCTION_REGEX = /^function\s+([^\s]+)\s+([0-9]+)$/
    C_RETURN_REGEX = /^call\s+([^\s]+)\s+([0-9]+)$/
    C_CALL_REGEX = /^return$/

    def initialize(file_path)
      @commands = []

      File.open(file_path, "r") do |file|
        file.each_line do |line|
          line.sub!(/\/\/.*$/, "")  # remove comment
          line.strip!
          @commands.push(line) if !line.empty?
        end
      end

      reset
    end

    def reset
      @current_command_index = -1
      @current_command = nil
    end

    def has_more_commands?
      !@commands[@current_command_index + 1].nil?
    end

    def advance
      raise "no more command" unless has_more_commands?
      @current_command_index += 1
      @current_command = nil
      nil
    end

    def command_type
      raise "empty command" if current_command.nil?
      return :C_ARITHMETIC if current_command.match?(C_ARITHMETIC_REGEX)
      return :C_PUSH if current_command.match?(C_PUSH_REGEX)
      return :C_POP if current_command.match?(C_POP_REGEX)
      return :C_LABEL if current_command.match?(C_LABEL_REGEX)
      return :C_GOTO if current_command.match?(C_GOTO_REGEX)
      return :C_IF if current_command.match?(C_IF_REGEX)
      return :C_FUNCTION if current_command.match?(C_FUNCTION_REGEX)
      return :C_RETURN if current_command.match?(C_RETURN_REGEX)
      return :C_CALL if current_command.match?(C_CALL_REGEX)
      raise "invalid command: #{current_command}"
    end

    def arg1
      case command_type
      when :C_ARITHMETIC
        current_command.match(C_ARITHMETIC_REGEX)[1]
      when :C_PUSH
        current_command.match(C_PUSH_REGEX)[1]
      when :C_POP
        current_command.match(C_POP_REGEX)[1]
      when :C_LABEL
        current_command.match(C_LABEL_REGEX)[1]
      when :C_GOTO
        current_command.match(C_GOTO_REGEX)[1]
      when :C_IF
        current_command.match(C_IF_REGEX)[1]
      when :C_FUNCTION
        current_command.match(C_FUNCTION_REGEX)[1]
      when :C_CALL
        current_command.match(C_CALL_REGEX)[1]
      else
        raise "cannot call arg1 on command: #{current_command}"
      end
    end

    def arg2
      case command_type
      when :C_PUSH
        current_command.match(C_PUSH_REGEX)[2]
      when :C_POP
        current_command.match(C_POP_REGEX)[2]
      when :C_FUNCTION
        current_command.match(C_FUNCTION_REGEX)[2]
      when :C_CALL
        current_command.match(C_CALL_REGEX)[2]
      else
        raise "cannot call arg2 on command: #{current_command}"
      end
    end

    private
    def current_command
      @current_command ||=
        if @current_command_index >= 0
          @commands[@current_command_index]
        else
          nil
        end
    end
  end
end
