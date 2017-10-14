module Jack
  class CompilationEngine
    def initialize(tokenizer, output)
      @tokenizer = tokenizer
      @output = output
    end

    def compile_class
      @output.puts('<class>')

      # 'class'
      compile_keyword('class')
      compile_identifier
      compile_symbol('{')



      compile_symbol('}')

      @output.puts('</class>')
    end

    def compile_class_var_dec
      @output.puts('<classVarDec>')
      @output.puts('</classVarDec>')
    end

    def compile_subroutine
      @output.puts('<subroutineDec>')

      @output.puts('</subroutineDec>')
    end

    def compile_parameter_list

    end

    def compile_var_dec

    end

    def compile_statements

    end

    def compile_do

    end

    def compile_liet

    end

    def compile_while

    end

    def compile_return

    end

    def compile_if

    end

    def compile_expression

    end

    def compile_term

    end

    def compile_expression_list

    end

    private

    def compile_keyword(keyword)
      return false if @tokenizer.more_tokens?
      @tokenizer.advance
      return false unless @tokenizer.token_type == :KEYWORD && @tokenizer.keyword == keyword
      @output.puts("<keyword>#{@tokenizer.keyword}</keyword>")
    end

    def compile_identifier
      @tokenizer.advance
      raise "error" unless @tokenizer.token_type == :IDENTIFIER
      @output.puts("<identifier>#{@tokenizer.identifier}</identifier>")
    end

    def compile_symbol(symbol)
      @tokenizer.advance
      raise "error" unless @tokenizer.token_type == :SYMBOL && @tokenizer.symbol == symbol
      @output.puts("<symbol>#{@tokenizer.symbol}</symbol>")
    end
  end
end
