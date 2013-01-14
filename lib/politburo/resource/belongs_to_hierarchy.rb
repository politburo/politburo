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

      def full_name
        parent_resource.nil? ? name : (parent_resource.name.empty? ? name : "#{parent_resource.full_name}:#{name}")
      end

      module ClassMethods
      end
    end

  end
end