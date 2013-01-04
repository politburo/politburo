module Politburo
  module Resource
    class Root < Base

      def parent_resource
        nil
      end

      def context_class
        RootContext
      end
    end

    class RootContext < Politburo::DSL::Context

      def environment(attributes, &block)
        find_or_create_resource(::Politburo::Resource::Environment, attributes, &block)
      end

    end    

  end
end
