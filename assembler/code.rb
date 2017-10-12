class Code
  def self.dest(mnemonic)
    case mnemonic
    when "M"
      "001"
    when "D"
      "010"
    when "MD"
      "011"
    when "A"
      "100"
    when "AM"
      "101"
    when "AD"
      "110"
    when "AMD"
      "111"
    else
      "000"
    end
  end

  def self.comp(mnemonic)
    c = case mnemonic.gsub("M", "A")
    when "0"
      "101010"
    when "1"
      "111111"
    when "-1"
      "111010"
    when "D"
      "001100"
    when "A"
      "110000"
    when "!D"
      "001101"
    when "!A"
      "110001"
    when "-D"
      "001111"
    when "-A"
      "110011"
    when "D+1"
      "011111"
    when "A+1"
      "110111"
    when "D-1"
      "001110"
    when "A-1"
      "110010"
    when "D+A"
      "000010"
    when "D-A"
      "010011"
    when "A-D"
      "000111"
    when "D&A"
      "000000"
    when "D|A"
      "010101"
    else
      raise "unrecognized mnemonic #{mnemonic}"
    end
    a = (mnemonic.include? "M") ? "1" : "0"
    "#{a}#{c}"
  end

  def self.jump(mnemonic)
    case mnemonic
    when "JGT"
      "001"
    when "JEQ"
      "010"
    when "JGE"
      "011"
    when "JLT"
      "100"
    when "JNE"
      "101"
    when "JLE"
      "110"
    when "JMP"
      "111"
    else
      "000"
    end
  end
end
