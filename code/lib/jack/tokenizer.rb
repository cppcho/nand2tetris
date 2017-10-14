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
      '-',
    ].freeze

    REGEX_COMMENT = %r{(//.*\n|/\*\*?.*\*/)}

    def initialize(input_stream)
      @current_token = nil
      @current_token_type = nil

      @source = input_stream.read

      # remove all comments
      @source.gsub!(REGEX_COMMENT, ' ')

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
    end

    def token_type
      @current_token_type
    end

    def token
      @current_token
    end

    def keyword
      raise "error" unless token_type == :KEYWORD
      @current_token
    end

    def symbol
      raise "error" unless token_type == :SYMBOL
      @current_token
    end

    def identifier
      raise "error" unless token_type == :IDENTIFIER
      @current_token
    end

    def int_val
      raise "error" unless token_type == :INT_CONST
      @current_token
    end

    def string_val
      raise "error" unless token_type == :STRING_CONST
      @current_token
    end
  end
end