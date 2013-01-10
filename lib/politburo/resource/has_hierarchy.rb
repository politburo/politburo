module Politburo

  module Resource

    module HasHierarchy
      
      def self.included(base)
        base.extend(ClassMethods)
      end

      attr_accessor :parent_resource

      def children()
        @children ||= Set.new
      end

      def add_child(child_resource)
        child_resource.parent_resource = self
        add_dependency_on(child_resource)
        children << child_resource
      end

      module ClassMethods
      end
    end

  end
end