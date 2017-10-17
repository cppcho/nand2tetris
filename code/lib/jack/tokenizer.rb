module Jack
  class Tokenizer
    KEYWORDS = [
      'class',
      'constructor',
      'function',
      'method',
      'field',
      'static',
      'var',
      'int',
      'char',
      'boolean',
      'void',
      'true',
      'false',
      'null',
      'this',
      'let',
      'do',
      'if',
      'else',
      'while',
      'return'
    ].freeze

    SYMBOLS = [
      '{',
      '}',
      '(',
      ')',
      '[',
      ']',
      '.',
      ',',
      ';',
      '+',
      '-',
      '*',
      '/',
      '&',
      '|',
      '<',
      '>',
      '=',
      '~',
    ].freeze

    REGEX_COMMENT_1 = %r{//.*\n}
    REGEX_COMMENT_2 = %r{/\*.*?\*/}

    def initialize(input_stream)
      @current_token = nil
      @current_token_type = nil

      @source = input_stream.read

      # remove all comments
      @source.gsub!(REGEX_COMMENT_1, ' ')
      @source.tr!("\n", ' ')
      @source.gsub!(REGEX_COMMENT_2, ' ')

      # change all whitespace / newline to 1 space
      @source.gsub!(/\s+/, ' ')

      @source.strip!
    end

    def more_tokens?
      !@source.empty?
    end

    REGEX_KEYWORDS = /\A(#{KEYWORDS.map { |v| Regexp.escape(v) }.join('|')})/
    REGEX_SYMBOLS = /\A(#{SYMBOLS.map { |v| Regexp.escape(v) }.join('|')})/
    REGEX_INT_CONST = /\A(\d+)/
    REGEX_STRING_CONST = /\A\"([^"^\n]+)\"/
    REGEX_IDENTIFER = /\A([^\d]\w*)/

    def next_token
      case @source
      when REGEX_KEYWORDS
        @source.match(REGEX_KEYWORDS)[1]
      when REGEX_SYMBOLS
        @source.match(REGEX_SYMBOLS)[1]
      when REGEX_INT_CONST
        @source.match(REGEX_INT_CONST)[1]
      when REGEX_STRING_CONST
        @source.match(REGEX_STRING_CONST)[1]
      when REGEX_IDENTIFER
        @source.match(REGEX_IDENTIFER)[1]
      else
        raise "invalid token on #{@source}"
      end
    end

    def advance
      raise "cannot advance, no token left" unless more_tokens?

      @current_token = nil
      @current_token_type = nil

      case @source
      when REGEX_KEYWORDS
        @current_token = @source.match(REGEX_KEYWORDS)[1]
        @current_token_type = :KEYWORD
        @source.sub!(REGEX_KEYWORDS, '')
      when REGEX_SYMBOLS
        @current_token = @source.match(REGEX_SYMBOLS)[1]
        @current_token_type = :SYMBOL
        @source.sub!(REGEX_SYMBOLS, '')
      when REGEX_INT_CONST
        @current_token = @source.match(REGEX_INT_CONST)[1]
        @current_token_type = :INT_CONST
        @source.sub!(REGEX_INT_CONST, '')
      when REGEX_STRING_CONST
        @current_token = @source.match(REGEX_STRING_CONST)[1]
        @current_token_type = :STRING_CONST
        @source.sub!(REGEX_STRING_CONST, '')
      when REGEX_IDENTIFER
        @current_token = @source.match(REGEX_IDENTIFER)[1]
        @current_token_type = :IDENTIFIER
        @source.sub!(REGEX_IDENTIFER, '')
      else
        raise "invalid token on #{@source}"
      end
      @source.strip!

      # p @current_token
    end

    def token_type
      @current_token_type
    end

    def token
      @current_token
    end

    def keyword
      return nil unless token_type == :KEYWORD
      @current_token
    end

    def symbol
      return nil unless token_type == :SYMBOL
      @current_token
    end

    def identifier
      return nil unless token_type == :IDENTIFIER
      @current_token
    end

    def int_val
      return nil unless token_type == :INT_CONST
      @current_token
    end

    def string_val
      return nil unless token_type == :STRING_CONST
      @current_token
    end
  end
end
