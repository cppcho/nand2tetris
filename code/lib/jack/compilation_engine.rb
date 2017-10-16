module Jack
  class CompilationEngine
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

      # 'class'
      puts_keyword
      advance

      # className
      puts_identifier
      advance

      # {
      puts_symbol
      advance

      loop do
        break unless compile_class_var_dec
      end

      loop do
        break unless compile_subroutine_dec
      end

      # }
      puts_symbol
      advance

      write_file('</class>')

      p 'success'

      true
    end

    def compile_class_var_dec
      return false unless keyword?(%w[static field])
      write_file('<classVarDec>')
      puts_keyword
      advance

      puts_type
      advance

      puts_identifier
      advance

      loop do
        break unless symbol?(',')
        puts_symbol
        advance

        puts_identifier
        advance
      end

      # ;
      puts_symbol
      advance
      write_file('</classVarDec>')
      true
    end

    def compile_subroutine_dec
      return false unless keyword?(%w[constructor function method])
      write_file('<subroutineDec>')
      puts_keyword
      advance

      if keyword?('void')
        puts_keyword
      else
        puts_type
      end

      # subroutineName
      puts_identifier
      advance

      # (
      puts_symbol
      advance

      compile_parameter_list

      # )
      puts_symbol
      advance

      compile_subroutine_body
      write_file('</subroutineDec>')
      true
    end

    def compile_parameter_list
      return false unless type?
      write_file('<parameterList>')
      puts_type
      advance
      puts_identifier
      advance
      loop do
        break unless symbol?(',')
        advance

        puts_type
        advance

        puts_identifier
        advance
      end
      write_file('</parameterList>')
      true
    end

    def compile_subroutine_body
      return false unless symbol?('{')
      write_file('<subroutineBody>')
      puts_symbol
      advance

      loop do
        break unless compile_var_dec
      end

      compile_statements

      # }
      puts_symbol
      advance
      write_file('</subroutineBody>')
      true
    end

    def compile_var_dec
      return false unless keyword?('var')
      write_file('<varDec>')
      puts_keyword
      advance

      puts_type
      advance

      puts_identifier
      advance

      loop do
        break unless symbol?(',')
        puts_symbol
        advance
        puts_identifier
        advance
      end

      # ;
      puts_symbol
      advance

      true
    end

    def compile_statements
      write_file('<statements>')
      loop do
        case @tokenizer.keyword
        when 'let'
          write_file('<letStatement>')
          puts_keyword
          @tokenizer.advance

          puts_identifier
          @tokenizer.advance

          begin
            raise 'error' unless @tokenizer.symbol == '['
            puts_symbol
            @tokenizer.advance

            compile_expression

            raise 'error' unless @tokenizer.symbol == ']'
            puts_symbol
            @tokenizer.advance
          rescue => exception
            nil
          end

          raise 'error' unless @tokenizer.symbol == '='
          puts_symbol
          @tokenizer.advance

          compile_expression

          raise 'error' unless @tokenizer.symbol == ';'
          puts_symbol
          @tokenizer.advance

          write_file('</letStatement>')
        when 'if'
          write_file('<ifStatement>')

          puts_keyword
          @tokenizer.advance

          raise 'error' unless @tokenizer.symbol == '('
          puts_symbol
          @tokenizer.advance

          compile_expression

          raise 'error' unless @tokenizer.symbol == ')'
          puts_symbol
          @tokenizer.advance

          raise 'error' unless @tokenizer.symbol == '{'
          puts_symbol
          @tokenizer.advance

          compile_statements

          raise 'error' unless @tokenizer.symbol == '}'
          puts_symbol
          @tokenizer.advance

          begin
            raise 'error' unless @tokenizer.keyword == 'else'
            puts_keyword
            @tokenizer.advance

            raise 'error' unless @tokenizer.symbol == '{'
            puts_symbol
            @tokenizer.advance

            compile_statements

            raise 'error' unless @tokenizer.symbol == '}'
            puts_symbol
            @tokenizer.advance
          rescue => exception
            nil
          end

          write_file('</ifStatement>')
        when 'while'
          write_file('<whileStatement>')

          puts_keyword
          @tokenizer.advance

          raise 'error' unless @tokenizer.symbol == '('
          puts_symbol
          @tokenizer.advance

          compile_expression

          raise 'error' unless @tokenizer.symbol == ')'
          puts_symbol
          @tokenizer.advance

          raise 'error' unless @tokenizer.symbol == '{'
          puts_symbol
          @tokenizer.advance

          compile_statements

          raise 'error' unless @tokenizer.symbol == '}'
          puts_symbol
          @tokenizer.advance

          write_file('</whileStatement>')
        when 'do'
          write_file('<doStatement>')

          puts_keyword
          @tokenizer.advance

          compile_subroutine_call

          raise 'error' unless @tokenizer.symbol == ';'
          puts_symbol
          @tokenizer.advance
          write_file('</doStatement>')
        when 'return'
          write_file('<returnStatement>')
          puts_keyword
          @tokenizer.advance

          if @tokenizer.symbol != ';'
            compile_expression
          end

          raise 'error' unless @tokenizer.symbol == ';'
          puts_symbol
          @tokenizer.advance

          write_file('</returnStatement>')
        else
          raise "Invalid keyword #{@tokenizer.token}"
        end
      end
      write_file('</statements>')
    end

    def compile_expression
      write_file('<expression>')
      compile_term
      begin
        raise "Invalid op #{@tokenizer.token}" unless %w[+ - * / & | < > =].include?(@tokenizer.symbol)
        puts_symbol
        @tokenizer.advance

        compile_term
      rescue => exception
        nil
      end
      write_file('</expression>')
    end

    def compile_term
      write_file('<term>')

      case @tokenizer.token_type
      when :INT_CONST
        puts_int_const
      when :STRING_CONST
        puts_string_const
      when :KEYWORD
        raise "Invalid keyword #{@tokenizer.token}" unless %w[true false null this].include?($tokenizer.keyword)
        puts_keyword
      when :IDENTIFIER
        if @tokenizer.next_token == '('
          compile_subroutine_call
        else
          puts_identifier
          if @tokenizer.next_token == '['
            @tokenizer.advance
            puts_symbol
            @tokenizer.advance

            compile_expression

            raise "Invalid symbol #{@tokenizer.token}" unless @tokenizer.symbol == ']'
            puts_symbol
          end
        end
      when :SYMBOL
        if @tokenizer.symbol == '('
          puts_symbol
          @tokenizer.advance

          compile_expression

          raise "Invalid symbol #{@tokenizer.token}" unless @tokenizer.symbol == ')'
          puts_symbol
        elsif %w[- ~].include?(@tokenizer.symbol)
          puts_symbol
          @tokenizer.advance

          compile_term
        else
          raise "error"
        end
      end
      @tokenizer.advance
      write_file('</term>')
    end

    def compile_expression_list

      write_file('<expressionList>')
      begin
        raise "empty" if @tokenizer.token == ')'

        compile_expression

        loop do
          raise "Invalid symbol #{@tokenizer.token}" unless @tokenizer.symbol == ','
          puts_symbol
          @tokenizer.advance
          compile_expression
        end
      rescue => exception
        nil
      end
      write_file('</expressionList>')
    end

    def compile_subroutine_call
      raise "Invalid symbol #{@tokenizer.token}" unless @tokenizer.token_type == :IDENTIFIER

      puts_identifier
      @tokenizer.advance

      if @tokenizer.symbol == '('
        puts_symbol
        @tokenizer.advance

        compile_expression_list

        raise "Invalid symbol #{@tokenizer.token}" unless @tokenizer.symbol == ')'
        puts_symbol
        @tokenizer.advance
      elsif @tokenizer.symbol == '.'
        puts_symbol
        @tokenizer.advance

        puts_identifier
        @tokenizer.advance

        raise "Invalid symbol #{@tokenizer.token}" unless @tokenizer.symbol == '('
        puts_symbol
        @tokenizer.advance

        compile_expression_list

        raise "Invalid symbol #{@tokenizer.token}" unless @tokenizer.symbol == ')'
        puts_symbol
        @tokenizer.advance
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
      @tokenizer.token_type == :SYMBOL && Array(symbols).include?(@tokenizer.symbol)
    end

    def keyword?(symbols)
      @tokenizer.token_type == :KEYWORD && Array(keywords).include?(@tokenizer.keyword)
    end

    def identifier?
      @tokenizer.token_type == :IDENTIFIER
    end

    def int_const?
      @tokenizer.token_type == :INT_CONST
    end

    def string_const?
      @tokenizer.token_type == :STRING_CONST
    end

    def puts_symbol
      puts_tag('symbol', @tokenizer.symbol)
    end

    def puts_keyword
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
