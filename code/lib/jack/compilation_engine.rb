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
      write_comment("class")
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
      write_comment("END class")
      true
    end

    def compile_class_var_dec
      return false unless keyword?(%w[static field])
      write_comment("classVarDec")

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
      write_comment("END classVarDec")
      true
    end

    def compile_subroutine_dec
      return false unless keyword?(%w[constructor function method])
      start_subroutine
      write_comment("subroutineDec")
      check_keyword(%w[constructor function method])
      subroutine_type = token
      advance

      if keyword?('void')
        check_keyword('void')
      else
        check_type
      end
      subroutine_return_type = token
      advance

      define_identifier(
        is_subroutine: true,
        subroutine_type: subroutine_type,
        subroutine_return_type: subroutine_return_type
      )
      advance

      check_symbol('(')
      advance
      compile_parameter_list
      check_symbol(')')
      advance

      compile_subroutine_body
      write_comment("END subroutineDec")
      true
    end

    def compile_parameter_list
      write_comment("parameterList")
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
      write_comment("END parameterList")
      true
    end

    def compile_subroutine_body
      return false unless symbol?('{')
      write_comment('subroutineBody')
      check_symbol('{')
      advance

      loop { break unless compile_var_dec }

      write_subroutine

      compile_statements

      check_symbol('}')
      advance
      write_comment('END subroutineBody')
      true
    end

    def compile_var_dec
      return false unless keyword?('var')
      write_comment('varDec')
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
      write_comment('END varDec')
      true
    end

    def compile_statements
      write_comment('statements')
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
      write_comment('END statements')
    end

    def compile_do
      return false unless keyword?('do')
      write_comment('doStatement')

      check_keyword('do')
      advance

      compile_subroutine_call

      check_symbol(';')
      advance

      # Remove the return result
      @vm_writer.write_pop(:TEMP, 0)

      write_comment('END doStatement')
      true
    end

    def compile_let
      return false unless keyword?('let')
      write_comment('letStatement')

      check_keyword('let')
      advance

      var_info = check_identifier
      raise "Variable #{var_info[:identifier]} not found." unless var_info[:is_var]
      advance

      # TODO
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

      write_var(:POP, var_info)

      write_comment('END letStatement')
      true
    end

    def compile_while
      return false unless keyword?('while')
      write_comment('whileStatement')

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

      write_comment('END whileStatement')
      true
    end

    def compile_return
      return false unless keyword?('return')
      write_comment('returnStatement')
      check_keyword('return')
      advance

      if symbol?(';')
        @vm_writer.write_push(:CONST, 0)
      else
        compile_expression
      end
      @vm_writer.write_return

      check_symbol(';')
      advance

      write_comment('END returnStatement')
      true
    end

    def compile_if
      return false unless keyword?('if')
      write_comment('ifStatement')

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

      write_comment('END ifStatement')
      true
    end

    def compile_expression
      write_comment('expression')
      compile_term
      loop do
        break unless symbol?(%w[+ - * / & | < > =])
        check_symbol(%w[+ - * / & | < > =])
        arithmetic_symbol = token
        advance

        compile_term

        write_op(arithmetic_symbol)
      end
      write_comment('END expression')
      true
    end

    def compile_term
      write_comment('term')

      case token_type
      when :INT_CONST
        write_term_int_const
        advance
      when :STRING_CONST
        write_term_string_const
        advance
      when :KEYWORD
        write_term_keyword
        advance
      when :IDENTIFIER
        # TODO
        if %w[( .].include?(@tokenizer.next_token)
          compile_subroutine_call
        else
          v_info = check_identifier
          advance
          if symbol?('[')
            check_symbol('[')
            advance
            compile_expression
            check_symbol(']')
            advance
          end
          write_var(:PUSH, v_info)
        end
      when :SYMBOL
        if symbol?('(')
          check_symbol('(')
          advance
          compile_expression
          check_symbol(')')
          advance
        else
          # unaryOp term
          check_symbol(%w[- ~])
          op = token
          advance
          compile_term

          write_unary_op(op)
        end
      end
      write_comment('END term')
      true
    end

    def compile_expression_list
      write_comment('expressionList')
      compile_expression
      expression_count = 1
      loop do
        break unless symbol?(',')
        check_symbol(',')
        advance
        compile_expression
        expression_count += 1
      end
      write_comment('END expressionList')
      expression_count
    end

    def compile_subroutine_call
      return false unless identifier?

      identifier_1_info = check_identifier
      advance

      if symbol?('(')
        # Function call
        check_symbol(')')
        advance
        expression_count =
          if symbol?(')')
            0
          else
            compile_expression_list
          end
        check_symbol(')')
        advance
        write_call(identifier_1_info[:identifier], expression_count)
      elsif symbol?('.')
        # Method / static method call
        check_symbol('.')
        advance
        identifier_2_info = check_identifier
        advance
        check_symbol('(')
        advance

        write_var(:PUSH, identifier_1_info) if identifier_1_info[:is_var]

        expression_count =
          if symbol?(')')
            0
          else
            compile_expression_list
          end
        check_symbol(')')
        advance

        if identifier_1_info[:index].nil?
          # identifier 1 is a class
          function_name = "#{identifier_1_info[:identifier]}.#{identifier_2_info[:identifier]}"
          n_args = expression_count
        else
          # identifier 1 is an object
          function_name = "#{identifier_1_info[:type]}.#{identifier_2_info[:identifier]}"
          n_args = expression_count + 1
        end
        write_call(function_name, n_args)
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
        check_keyword(%w[int char boolean])
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

    def define_identifier(
      is_class: false,
      is_subroutine: false,
      kind: nil,
      type: nil,
      subroutine_type: nil,
      subroutine_return_type: nil
    )
      raise "Invalid identifier #{token}" unless identifier?
      identifier = @tokenizer.identifier
      if is_class
        @current_class_name = identifier
      elsif is_subroutine
        @current_subroutine_name = identifier
        @current_subroutine_type = subroutine_type
        @current_subroutine_return_type = subroutine_return_type
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
        index:  @symbol_table.index_of(identifier),
        is_var: !@symbol_table.index_of(identifier).nil?
      }
    end

    def write_term_int_const
      raise "Invalid int const #{token}" unless token_type == :INT_CONST
      @vm_writer.write_push(:CONST, @tokenizer.int_val)
    end

    def write_term_string_const
      raise "Invalid string const #{token}" unless token_type == :STRING_CONST
      string_val = @tokenizer.string_val
      @vm_writer.write_push(:CONST, string_val.length)
      @vm_writer.write_call('String.new', 1)
      # Append each charactor to the string
      string_val.each_char do |char|
        @vm_writer.write_push(:CONST, char.ord)
        @vm_writer.write_call('String.appendChar', 2)
      end
    end

    def write_term_keyword
      check_keyword(%w[true false null this])
      keyword = @tokenizer.keyword
      case keyword
      when 'true'
        @vm_writer.write_push(:CONST, 0)
        @vm_writer.write_arithmetic(:NOT)
      when 'false'
        @vm_writer.write_push(:CONST, 0)
      when 'null'
        @vm_writer.write_push(:CONST, 0)
      when 'this'
        @vm_writer.write_push(:POINTER, 0)
      end
    end

    def write_call(function_name, n_args)
      @vm_writer.write_call(function_name, n_args)
    end

    # mode: :PUSH, :POP
    def write_var(mode, identifier_info)
      raise "Variable #{identifier_info[:identifier]} not found." unless identifier_info[:is_var]
      kind = identifier_info[:kind]
      idx = identifier_info[:index]

      vm_action =
        if mode == :PUSH
          :write_push
        elsif mode == :POP
          :write_pop
        else
          raise "Invalid mode #{mode}"
        end

      case kind
      when :STATIC
        @vm_writer.send vm_action, :STATIC, idx
      when :FIELD
        @vm_writer.send vm_action, :THIS, idx
      when :ARG
        @vm_writer.send vm_action, :ARG, idx
      when :VAR
        @vm_writer.send vm_action, :LOCAL, idx
      else
        raise "Invalid kind #{kind}"
      end
    end

    def start_subroutine
      @symbol_table.start_subroutine
    end

    def write_subroutine
      raise "Invalid subroutine name #{@current_subroutine_name}" unless @current_class_name
      # write function statement
      function_name = "#{@current_class_name}.#{@current_subroutine_name}"
      n_locals = @symbol_table.var_count(:VAR)
      @vm_writer.write_function(function_name, n_locals)

      if @subroutine_return_type == 'constructor'
        # alloc memory for field vars
        n_fields = @symbol_table.var_count(:FIELD)
        @vm_writer.write_push(:CONST, n_fields)
        @vm_writer.write_call('Memory.alloc', 1)

        # set this pointer to the newly allocated memory
        @vm_writer.write_pop('pointer', 0)
      elsif @subroutine_type == 'method'
        @vm_writer.write_push(:ARG, 0)  # argument 0 is the object that call the method
        @vm_writer.write_push(:POINTER, 0)   # set to this
      end
    end

    def write_op(op)
      case op
      when '+'
        @vm_writer.write_arithmetic(:ADD)
      when '-'
        @vm_writer.write_arithmetic(:SUB)
      when '*'
        @vm_writer.write_call('Math.multiply', 2)
      when '/'
        @vm_writer.write_call('Math.divide', 2)
      when '&'
        @vm_writer.write_arithmetic(:AND)
      when '|'
        @vm_writer.write_arithmetic(:OR)
      when '<'
        @vm_writer.write_arithmetic(:LT)
      when '>'
        @vm_writer.write_arithmetic(:GT)
      when '='
        @vm_writer.write_arithmetic(:EQ)
      else
        raise "Invalid binary op #{op}"
      end
    end

    def write_unary_op(op)
      case op
      when '-'
        @vm_writer.write_arithmetic(:NEG)
      when '~'
        @vm_writer.write_arithmetic(:NOT)
      else
        raise "Invalid unary op #{op}"
      end
    end

    def write_comment(comment)
      # @vm_writer.write_comment(comment)
    end
  end
end
