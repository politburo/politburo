module Politburo

  module Resource

    module BelongsToHierarchy
      include Enumerable
      
      def self.included(base)
        base.extend(ClassMethods)
      end

      attr_accessor :parent_resource

      def each(&block)
        block.call(self)
      end

      module ClassMethods
      end
    end

  end
end