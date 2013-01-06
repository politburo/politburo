module Politburo
  module Resource
    class Root < Base

      def parent_resource
        nil
      end

      def context_class
        RootContext
      end

      def apply_plugins
        find_all_by_attributes(class: lambda { | obj, attr_name, value | obj.respond_to?(:apply) } ).map(&:apply)
      end

    end

    class RootContext < Politburo::DSL::Context

      def environment(attributes, &block)
        find_or_create_resource(::Politburo::Resource::Environment, attributes, &block)
      end

    end    

  end
end
