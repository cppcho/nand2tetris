class Parser
  A_COMMAND_REGEX = /^@(.+)$/
  L_COMMAND_REGEX = /^\((.+)\)$/
  C_COMMAND_REGEX = /^(?:([^=;]+)=)?([^=;]+)(?:;([^=;]+))?$/

  def initialize(file_path)
    @commands = []
    @current_command_index = -1

    File.open(file_path, "r") do |file|
      file.each_line do |line|
        line.sub!(/\/\/.*$/, "")  # remove comment
        line.strip!
        @commands.push(line) if !line.empty?
      end
    end
  end

  def has_more_commands?
    !@commands[@current_command_index + 1].nil?
  end

  def advance
    raise "no more command" if !has_more_commands?
    @current_command_index += 1
    nil
  end

  def command_type
    return nil if current_command.nil?
    return :A_COMMAND if current_command.match?(A_COMMAND_REGEX)
    return :L_COMMAND if current_command.match?(L_COMMAND_REGEX)
    return :C_COMMAND if current_command.match?(C_COMMAND_REGEX)
    return nil
  end

  def symbol
    if command_type == :A_COMMAND
      current_command.match(A_COMMAND_REGEX)[1]
    elsif command_type == :L_COMMAND
      current_command.match(L_COMMAND_REGEX)[1]
    else
      nil
    end
  end

  def dest
    if command_type == :C_COMMAND
      current_command.match(C_COMMAND_REGEX)[1]
    else
      nil
    end
  end

  def comp
    if command_type == :C_COMMAND
      current_command.match(C_COMMAND_REGEX)[2]
    else
      nil
    end
  end

  def jump
    if command_type == :C_COMMAND
      current_command.match(C_COMMAND_REGEX)[3]
    else
      nil
    end
  end

  private
  def current_command
    return nil if @current_command_index < 0
    @commands[@current_command_index]
  end
end
