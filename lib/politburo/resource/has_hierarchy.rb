module Politburo

  module Resource

    module HasHierarchy
      include Enumerable
      include Politburo::Resource::BelongsToHierarchy
      
      def self.included(base)
        base.extend(ClassMethods)
      end

      def contained_searchables
        children
      end

      def children()
        @children ||= Set.new
      end

      def add_child(child_resource)
        child_resource.parent_resource = self
        children << child_resource
      end

      def each(&block)
        block.call(self)
        children.each { | c | c.each(&block) } 
      end

      module ClassMethods
      end
    end

  end
end