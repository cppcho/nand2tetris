require 'cgi'

module Jack
  class CompilationEngineXml
    def initialize(tokenizer, output)
      # tokenizer: a fresh new tokenizer created from a file stream
      @tokenizer = tokenizer
      @output = output

      @tokenizer.advance
    end

    def compile_class
      return false unless keyword?('class')

      ret = true
      write_file('<class>')

      puts_keyword('class')
      advance

      # className
      puts_identifier
      advance

      # {
      puts_symbol('{')
      advance

      loop do
        break unless compile_class_var_dec
      end

      loop do
        break unless compile_subroutine_dec
      end

      # }
      puts_symbol('}')

      advance rescue nil

      write_file('</class>')
      p 'success'
      true
    end

    def compile_class_var_dec
      return false unless keyword?(%w[static field])
      write_file('<classVarDec>')
      puts_keyword(%w[static field])
      advance

      puts_type
      advance

      puts_identifier
      advance

      loop do
        break unless symbol?(',')
        puts_symbol(',')
        advance

        puts_identifier
        advance
      end

      puts_symbol(';')
      advance
      write_file('</classVarDec>')
      true
    end

    def compile_subroutine_dec
      return false unless keyword?(%w[constructor function method])
      write_file('<subroutineDec>')
      puts_keyword(%w[constructor function method])
      advance

      if keyword?('void')
        puts_keyword('void')
      else
        puts_type
      end
      advance

      puts_identifier
      advance

      puts_symbol('(')
      advance

      compile_parameter_list

      puts_symbol(')')
      advance

      compile_subroutine_body
      write_file('</subroutineDec>')
      true
    end

    def compile_parameter_list
      write_file('<parameterList>')
      if type?
        puts_type
        advance
        puts_identifier
        advance
        loop do
          break unless symbol?(',')
          puts_symbol(',')
          advance

          puts_type
          advance

          puts_identifier
          advance
        end
      end
      write_file('</parameterList>')
      true
    end

    def compile_subroutine_body
      return false unless symbol?('{')
      write_file('<subroutineBody>')
      puts_symbol('{')
      advance

      loop do
        break unless compile_var_dec
      end

      compile_statements

      puts_symbol('}')
      advance
      write_file('</subroutineBody>')
      true
    end

    def compile_var_dec
      return false unless keyword?('var')
      write_file('<varDec>')
      puts_keyword('var')
      advance

      puts_type
      advance

      puts_identifier
      advance

      loop do
        break unless symbol?(',')
        puts_symbol(',')
        advance
        puts_identifier
        advance
      end

      puts_symbol(';')
      advance
      write_file('</varDec>')
      true
    end

    def compile_statements
      write_file('<statements>')
      loop do
        case @tokenizer.keyword
        when 'let'
          compile_let
        when 'if'
          compile_if
        when 'while'
          compile_while
        when 'do'
          compile_do
        when 'return'
          compile_return
        else
          break
        end
      end
      write_file('</statements>')
    end

    def compile_do
      return false unless keyword?('do')
      write_file('<doStatement>')

      puts_keyword
      advance

      compile_subroutine_call

      puts_symbol
      advance

      write_file('</doStatement>')
      true
    end

    def compile_let
      return false unless keyword?('let')
      write_file('<letStatement>')

      puts_keyword('let')
      advance

      puts_identifier
      advance

      if symbol?('[')
        puts_symbol('[')
        advance

        compile_expression

        puts_symbol(']')
        advance
      end

      puts_symbol('=')
      advance

      compile_expression

      puts_symbol(';')
      advance

      write_file('</letStatement>')
      true
    end

    def compile_while
      return false unless keyword?('while')
      write_file('<whileStatement>')

      puts_keyword('while')
      advance

      puts_symbol('(')
      advance

      compile_expression

      puts_symbol(')')
      advance

      puts_symbol('{')
      advance

      compile_statements

      puts_symbol('}')
      advance

      write_file('</whileStatement>')
      true
    end

    def compile_return
      return false unless keyword?('return')

      write_file('<returnStatement>')
      puts_keyword('return')
      advance

      compile_expression unless symbol?(';')

      puts_symbol(';')
      advance

      write_file('</returnStatement>')
      true
    end

    def compile_if
      return false unless keyword?('if')
      write_file('<ifStatement>')

      puts_keyword('if')
      advance

      puts_symbol('(')
      advance

      compile_expression

      puts_symbol(')')
      advance

      puts_symbol('{')
      advance

      compile_statements

      puts_symbol('}')
      advance

      if keyword?('else')
        puts_keyword('else')
        advance

        puts_symbol('{')
        advance

        compile_statements

        puts_symbol('}')
        advance
      end

      write_file('</ifStatement>')
      true
    end

    def compile_expression
      write_file('<expression>')
      compile_term
      loop do
        break unless symbol?(%w[+ - * / & | < > =])
        puts_symbol(%w[+ - * / & | < > =])
        advance

        compile_term
      end
      write_file('</expression>')
      true
    end

    def compile_term
      write_file('<term>')

      case token_type
      when :INT_CONST
        puts_int_const
        advance
      when :STRING_CONST
        puts_string_const
        advance
      when :KEYWORD
        puts_keyword(%w[true false null this])
        advance
      when :IDENTIFIER
        if %w[( .].include?(@tokenizer.next_token)
          compile_subroutine_call
        else
          puts_identifier
          advance
          if symbol?('[')
            puts_symbol('[')
            advance
            compile_expression
            puts_symbol(']')
            advance
          end
        end
      when :SYMBOL
        if symbol?('(')
          puts_symbol('(')
          advance
          compile_expression
          puts_symbol(')')
          advance
        else
          puts_symbol(%w[- ~])
          advance
          compile_term
        end
      end
      write_file('</term>')
      true
    end

    def compile_expression_list
      write_file('<expressionList>')
      compile_expression
      loop do
        break unless symbol?(',')
        puts_symbol(',')
        advance
        compile_expression
      end
      write_file('</expressionList>')
      true
    end

    def compile_subroutine_call
      return false unless identifier?

      # subroutineName / className / varName
      puts_identifier
      advance

      if symbol?('(')
        puts_symbol
        advance
        # TODO: Any better method?
        if symbol?(')')
          write_file('<expressionList>')
          write_file('</expressionList>')
        else
          compile_expression_list
        end
        puts_symbol(')')
        advance
      elsif symbol?('.')
        puts_symbol('.')
        advance

        # subroutineName
        puts_identifier
        advance

        puts_symbol('(')
        advance

        # TODO: Any better method?
        if symbol?(')')
          write_file('<expressionList>')
          write_file('</expressionList>')
        else
          compile_expression_list
        end

        puts_symbol(')')
        advance
      end
    end

    private

    def advance
      @tokenizer.advance
    end

    def token
      @tokenizer.token
    end

    def token_type
      @tokenizer.token_type
    end

    def write_file(str)
      # p str
      @output.puts(str)
    end

    def puts_type
      if %w[int char boolean].include?(@tokenizer.keyword)
        puts_keyword
      elsif @tokenizer.token_type == :IDENTIFIER
        puts_identifier
      else
        false
      end
    end

    def type?
      %w[int char boolean].include?(@tokenizer.keyword) || @tokenizer.token_type == :IDENTIFIER
    end

    def symbol?(symbols)
      token_type == :SYMBOL && Array(symbols).include?(@tokenizer.symbol)
    end

    def keyword?(keywords)
      token_type == :KEYWORD && Array(keywords).include?(@tokenizer.keyword)
    end

    def identifier?
      token_type == :IDENTIFIER
    end

    def int_const?
      token_type == :INT_CONST
    end

    def string_const?
      token_type == :STRING_CONST
    end

    def puts_symbol(symbols = nil)
      raise "Invalid symbol #{token} (expected: #{symbols}" unless symbols.nil? || symbol?(symbols)
      puts_tag('symbol', CGI.escapeHTML(@tokenizer.symbol))
    end

    def puts_keyword(keywords = nil)
      raise "Invalid keyword #{token} (expected: #{keywords}" unless keywords.nil? || keyword?(keywords)
      puts_tag('keyword', @tokenizer.keyword)
    end

    def puts_identifier
      puts_tag('identifier', @tokenizer.identifier)
    end

    def puts_int_const
      puts_tag('integerConstant', @tokenizer.int_val)
    end

    def puts_string_const
      puts_tag('stringConstant', @tokenizer.string_val)
    end

    def puts_tag(tag_name, value)
      write_file("<#{tag_name}>#{value}</#{tag_name}>")
      true
    end
  end
end
