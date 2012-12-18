module Politburo
  module Support
    module AccessorWithDefault
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def attr_reader_with_default(name_sym_, &block)
          raise "attr_reader_with_default requires a block that initializes the default value." unless block_given?
          name_sym = name_sym_.to_sym

          value_proc = block
          define_method(name_sym) do
            instance_variable_get("@#{name_sym}".to_sym) || instance_eval(&value_proc)
          end
        end

        def attr_accessor_with_default(name_sym, &block)
          attr_reader_with_default(name_sym, &block)
          attr_writer(name_sym)
        end

      end      
    end
  end
end
