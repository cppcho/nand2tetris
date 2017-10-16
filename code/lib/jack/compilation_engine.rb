module Jack
  class CompilationEngine

    # non-terminal:


    def initialize(tokenizer, output)
      # tokenizer: a fresh new tokenizer created from a file stream
      @tokenizer = tokenizer
      @output = output

      @write_file_cache = []

      @tokenizer.advance
    end

    def compile_class
      raise "Invalid token #{@tokenizer.token}" unless @tokenizer.keyword == 'class'

      write_file('<class>')

      # 'class'
      puts_keyword
      @tokenizer.advance

      # className
      raise "Invalid className #{@tokenizer.token}" unless @tokenizer.token_type == :IDENTIFIER
      puts_identifier
      @tokenizer.advance

      # '{'
      raise "Invalid symbol #{@tokenizer.token}" unless @tokenizer.symbol == '{'
      puts_symbol
      @tokenizer.advance

      # classVarDec*
      loop do
        begin
          compile_class_var_dec
        rescue => e
          p e
          break
        end
      end

      # classVarDec*
      loop do
        begin
          compile_subroutine_dec
        rescue => e
          p e
          break
        end
      end

      # '}'
      raise "Invalid symbol #{@tokenizer.token}" unless @tokenizer.symbol == '}'
      puts_symbol
      write_file('</class>')

      @tokenizer.advance
    end

    def compile_class_var_dec
      # ('static', 'field') type varName (',' varName)* ';'
      raise "Invalid keyword #{@tokenizer.token}" unless %w[static field].include?(@tokenizer.keyword)

      write_file('<classVarDec>')

      puts_keyword
      @tokenizer.advance

      # type
      puts_type
      @tokenizer.advance

      # varName
      puts_identifier
      @tokenizer.advance

      loop do
        begin
          raise "invalid symbol #{@tokenizer.token}" unless @tokenizer.symbol == ','
          puts_symbol
          @tokenizer.advance

          puts_identifier
          @tokenizer.advance
        rescue => exception
          break
        end
      end

      raise "invalid symbol #{@tokenizer.token}" unless @tokenizer.symbol == ';'
      puts_symbol

      write_file('</classVarDec>')
      @tokenizer.advance
    end

    def compile_subroutine_dec
      raise "Invalid keyword #{@tokenizer.token}" unless %w[constructor function method].include?(@tokenizer.keyword)
      write_file('<subroutineDec>')

      puts_keyword
      @tokenizer.advance

      if @tokenizer.keyword == 'void'
        puts_keyword
      else
        puts_type
      end
      @tokenizer.advance

      # subroutineName
      puts_identifier
      @tokenizer.advance

      raise "Invalid symbol #{@tokenizer.token}" unless @tokenizer.symbol == '('
      puts_symbol
      @tokenizer.advance

      compile_parameter_list

      raise "Invalid symbol #{@tokenizer.token}" unless @tokenizer.symbol == ')'
      puts_symbol
      @tokenizer.advance

      compile_subroutine_body

      write_file('</subroutineDec>')
      @tokenizer.advance
    end

    def compile_parameter_list
      write_file('<parameterList>')
      begin
        raise "empty" if @tokenizer.token == ')'

        puts_type
        @tokenizer.advance
        puts_identifier
        @tokenizer.advance
        loop do
          begin
            raise "Invalid symbol #{@tokenizer.token}" unless @tokenizer.symbol == ','
            puts_symbol
            @tokenizer.advance
            puts_type
            @tokenizer.advance
            puts_identifier
            @tokenizer.advance
          rescue => exception
            break
          end
        end
      rescue => exception
        nil
      end
      write_file('</parameterList>')
    end

    def compile_subroutine_body
      raise "Invalid symbol #{@tokenizer.token}" unless @tokenizer.symbol == '{'

      write_file('<subroutineBody>')

      puts_symbol
      @tokenizer.advance

      begin
        compile_var_dec
      rescue => exception
        nil
      end

      compile_statements

      raise 'error' unless @tokenizer.symbol == '}'
      puts_symbol
      @tokenizer.advance

      write_file('</subroutineBody>')
    end

    def compile_var_dec
      raise 'error' unless @tokenizer.keyword == 'var'
      write_file('<varDec>')
      puts_keyword
      @tokenizer.advance

      puts_type
      @tokenizer.advance

      puts_identifier
      @tokenizer.advance

      begin
        raise 'error' unless @tokenizer.symbol == ','
        puts_symbol
        @tokenizer.advance

        puts_identifier
        @tokenizer.advance
      rescue => exception
        nil
      end

      raise 'error' unless @tokenizer.symbol == ';'
      puts_symbol

      write_file('</varDec>')
      @tokenizer.advance
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

    def write_file(str, pending = false)
      @write_file_cache.push(str)
      commit_write unless pending
    end

    def commit_write
      @write_file_cache.each do |line|
        @output.puts(line)
      end
      @write_file_cache = []
    end

    def puts_type
      if %w[int char boolean].include?(@tokenizer.keyword)
        puts_keyword
      elsif @tokenizer.token_type == :IDENTIFIER
        puts_identifier
      else
        raise "invalid type #{@tokenizer.token}"
      end
    end

    def puts_symbol
      raise "invalid symbol #{@tokenizer.token}" unless @tokenizer.token_type == :SYMBOL
      puts_tag('symbol', @tokenizer.symbol)
    end

    def puts_keyword
      raise "invalid keyword #{@tokenizer.token}" unless @tokenizer.token_type == :KEYWORD
      puts_tag('keyword', @tokenizer.keyword)
    end

    def puts_identifier
      raise "invalid identifier #{@tokenizer.token}" unless @tokenizer.token_type == :IDENTIFIER
      puts_tag('identifier', @tokenizer.identifier)
    end

    def puts_int_const
      raise "invalid int const #{@tokenizer.token}" unless @tokenizer.token_type == :INT_CONST
      puts_tag('integerConstant', @tokenizer.int_val)
    end

    def puts_string_const
      raise "invalid string const #{@tokenizer.token}" unless @tokenizer.token_type == :STRING_CONST
      puts_tag('stringConstant', @tokenizer.string_val)
    end

    def puts_tag(tag_name, value)
      write_file("<#{tag_name}>#{value}</#{tag_name}>")
    end
  end
end
