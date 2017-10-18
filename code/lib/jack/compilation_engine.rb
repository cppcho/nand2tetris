require_relative 'vm_writer'
require_relative 'symbol_table'
require 'cgi'

module Jack
  class CompilationEngine
    def initialize(tokenizer, output)
      # tokenizer: a fresh new tokenizer created from a file stream
      @tokenizer = tokenizer
      @vm_writer = VmWriter.new(output)
      @symbol_table = SymbolTable.new
      @current_class_name = nil
      @current_subroutine_name = nil
      @current_subroutine_type = nil
      @current_subroutine_return_type = nil

      advance

      # TODO: remove this
      @output = output
    end

    def compile
      compile_class
    end

    private

    def compile_class
      return false unless keyword?('class')
      @vm_writer.write_comment("class")
      check_keyword('class')
      advance
      define_identifier(is_class: true)
      advance
      check_symbol('{')
      advance


      loop { break unless compile_class_var_dec }
      loop { break unless compile_subroutine_dec }

      check_symbol('}')
      advance(true)
      @vm_writer.write_comment("END class")
      true
    end

    def compile_class_var_dec
      return false unless keyword?(%w[static field])
      @vm_writer.write_comment("classVarDec")

      check_keyword(%w[static field])
      first_token = token
      kind = first_token == 'static' ? :STATIC : :FIELD
      advance
      second_token = token
      check_type
      advance
      define_identifier(type: second_token, kind: kind)
      advance

      loop do
        break unless symbol?(',')
        check_symbol(',')
        advance
        define_identifier(type: second_token, kind: kind)
        advance
      end

      check_symbol(';')
      advance
      @vm_writer.write_comment("END classVarDec")
      true
    end

    def compile_subroutine_dec
      return false unless keyword?(%w[constructor function method])
      @vm_writer.write_comment("subroutineDec")
      check_keyword(%w[constructor function method])
      @current_subroutine_type = token
      advance

      if keyword?('void')
        check_keyword('void')
      else
        check_type
      end
      @current_subroutine_return_type = token
      advance

      define_identifier(is_subroutine: true)
      @current_subroutine_name = token
      advance

      check_symbol('(')
      advance
      compile_parameter_list
      check_symbol(')')
      advance

      compile_subroutine_body
      @vm_writer.write_comment("END subroutineDec")
      true
    end

    def compile_parameter_list
      @vm_writer.write_comment("parameterList")
      if type?
        check_type
        type = token
        advance
        define_identifier(kind: :ARG, type: type)
        advance
        loop do
          break unless symbol?(',')
          check_symbol(',')
          advance

          check_type
          type = token
          advance

          define_identifier(kind: :ARG, type: type)
          advance
        end
      end
      @vm_writer.write_comment("END parameterList")
      true
    end

    def compile_subroutine_body
      return false unless symbol?('{')
      @vm_writer.write_comment('subroutineBody')
      check_symbol('{')
      advance

      loop { break unless compile_var_dec }

      function_name = "#{@current_class_name}.#{@current_subroutine_name}"
      n_locals = @symbol_table.var_count(:VAR)
      @vm_writer.write_function(function_name, n_locals)

      compile_statements

      check_symbol('}')
      advance
      @vm_writer.write_comment('END subroutineBody')
      true
    end

    def compile_var_dec
      return false unless keyword?('var')
      @vm_writer.write_comment('varDec')
      check_keyword('var')
      advance

      check_type
      type = token
      advance

      define_identifier(type: type, kind: :VAR)
      advance

      loop do
        break unless symbol?(',')
        check_symbol(',')
        advance
        define_identifier(type: type, kind: :VAR)
        advance
      end

      check_symbol(';')
      advance
      @vm_writer.write_comment('END varDec')
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

      check_keyword('do')
      advance

      compile_subroutine_call

      check_symbol(';')
      advance

      write_file('</doStatement>')
      true
    end

    def compile_let
      return false unless keyword?('let')
      write_file('<letStatement>')

      check_keyword('let')
      advance

      check_identifier
      advance

      if symbol?('[')
        check_symbol('[')
        advance

        compile_expression

        check_symbol(']')
        advance
      end

      check_symbol('=')
      advance

      compile_expression

      check_symbol(';')
      advance

      write_file('</letStatement>')
      true
    end

    def compile_while
      return false unless keyword?('while')
      write_file('<whileStatement>')

      check_keyword('while')
      advance

      check_symbol('(')
      advance

      compile_expression

      check_symbol(')')
      advance

      check_symbol('{')
      advance

      compile_statements

      check_symbol('}')
      advance

      write_file('</whileStatement>')
      true
    end

    def compile_return
      return false unless keyword?('return')

      write_file('<returnStatement>')
      check_keyword('return')
      advance

      compile_expression unless symbol?(';')

      check_symbol(';')
      advance

      write_file('</returnStatement>')
      true
    end

    def compile_if
      return false unless keyword?('if')
      write_file('<ifStatement>')

      check_keyword('if')
      advance

      check_symbol('(')
      advance

      compile_expression

      check_symbol(')')
      advance

      check_symbol('{')
      advance

      compile_statements

      check_symbol('}')
      advance

      if keyword?('else')
        check_keyword('else')
        advance

        check_symbol('{')
        advance

        compile_statements

        check_symbol('}')
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
        check_symbol(%w[+ - * / & | < > =])
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
        check_keyword(%w[true false null this])
        advance
      when :IDENTIFIER
        if %w[( .].include?(@tokenizer.next_token)
          compile_subroutine_call
        else
          check_identifier
          advance
          if symbol?('[')
            check_symbol('[')
            advance
            compile_expression
            check_symbol(']')
            advance
          end
        end
      when :SYMBOL
        if symbol?('(')
          check_symbol('(')
          advance
          compile_expression
          check_symbol(')')
          advance
        else
          check_symbol(%w[- ~])
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
        check_symbol(',')
        advance
        compile_expression
      end
      write_file('</expressionList>')
      true
    end

    def compile_subroutine_call
      return false unless identifier?

      # subroutineName / className / varName
      check_identifier
      advance

      if symbol?('(')
        check_symbol
        advance
        # TODO: Any better method?
        if symbol?(')')
          write_file('<expressionList>')
          write_file('</expressionList>')
        else
          compile_expression_list
        end
        check_symbol(')')
        advance
      elsif symbol?('.')
        check_symbol('.')
        advance

        # subroutineName
        check_identifier
        advance

        check_symbol('(')
        advance

        # TODO: Any better method?
        if symbol?(')')
          write_file('<expressionList>')
          write_file('</expressionList>')
        else
          compile_expression_list
        end

        check_symbol(')')
        advance
      end
    end

    def advance(no_throw = false)
      begin
        @tokenizer.advance
      rescue => exception
        return false if no_throw
        raise exception
      end
      true
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

    def check_type
      if %w[int char boolean].include?(@tokenizer.keyword)
        check_keyword
      elsif @tokenizer.token_type == :IDENTIFIER
        check_identifier
      else
        raise "Invalid type #{token}"
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

    def check_symbol(symbols)
      raise "Invalid symbol #{token} (expected: #{symbols})" unless symbol?(symbols)
    end


    # 2017-10-17
    def check_keyword(keywords)
      raise "Invalid keyword #{token} (expected: #{keywords})" unless keyword?(keywords)
    end

    def define_identifier(is_class: false, is_subroutine: false, kind: nil, type: nil)
      raise "Invalid identifier #{token}" unless identifier?
      identifier = @tokenizer.identifier
      if is_class
        @current_class_name = identifier
      elsif is_subroutine
        @current_subroutine_name = identifier
      else
        @symbol_table.define(name: identifier, type: type, kind: kind)
      end
    end

    def check_identifier
      raise "Invalid identifier #{token}" unless identifier?
      identifier = @tokenizer.identifier
      {
        identifier: identifier,
        kind:@symbol_table.kind_of(identifier),
        type: @symbol_table.type_of(identifier),
        index:  @symbol_table.index_of(identifier)
      }
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
