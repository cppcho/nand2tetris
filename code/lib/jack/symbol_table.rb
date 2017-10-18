module Jack
  class SymbolTable
    def initialize
      @class_symbols = {}
      @subroutine_symbols = {}
      @index_counter = {
        STATIC: 0,
        FIELD: 0,
        ARG: 0,
        VAR: 0
      }
    end

    def start_subroutine
      @subroutine_symbols.clear
      @index_counter[:ARG] = 0
      @index_counter[:VAR] = 0
    end

    # kind: :STATIC, :FIELD, :ARG, :VAR
    def define(name: "", type: nil, kind: nil)
      raise 'Invalid name or type' if name.empty? || type.nil?
      res = nil
      case kind
      when :STATIC, :FIELD
        raise "Class symbol '#{name}' has already been defined" if @class_symbols.key?(name)
        res = @class_symbols[name] = {
          type: type,
          kind: kind,
          index: @index_counter[kind]
        }
      when :ARG, :VAR
        raise "Subroutine symbol '#{name}' has already been defined" if @subroutine_symbols.key?(name)
        res = @subroutine_symbols[name] = {
          type: type,
          kind: kind,
          index: @index_counter[kind]
        }
      else
        raise "Invalid kind #{kind}"
      end
      @index_counter[kind] += 1
      res
    end

    # kind: :STATIC, :FIELD, :ARG, :VAR
    def var_count(kind)
      @index_counter[kind]
    end

    def kind_of(name)
      symbol_info(name)[:kind]
    end

    def type_of(name)
      symbol_info(name)[:type]
    end

    def index_of(name)
      symbol_info(name)[:index]
    end

    private

    def symbol_info(name)
      return @subroutine_symbols[name] if @subroutine_symbols.key?(name)
      return @class_symbols[name] if @class_symbols.key?(name)
      {}
    end
  end
end
